import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hmes/pages/home.dart';
import 'package:hmes/pages/login.dart';
import 'package:hmes/pages/register.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hmes/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hmes/services/foreground_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hmes/services/mqtt-service.dart';

// import 'package:hmes/pages/welcome.dart';
// import 'package:firebase_core/firebase_core.dart';
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Xử lý khi notification đến lúc app đang background hoặc bị kill
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().initNotification();

  // Initialize foreground task first without starting
  await ForegroundServiceHelper.initForegroundTask();

  //await removeToken();
  String token = (await getToken()).toString();
  String refreshToken = (await getRefreshToken()).toString();
  String deviceId = (await getDeviceId()).toString();
  print('Token: $token');
  print('Refresh Token: $refreshToken');
  print('Device ID: $deviceId');
  final bool isLoggedIn =
      token.isNotEmpty && refreshToken.isNotEmpty && deviceId.isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});
  static PageController controller = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: const TextTheme(bodyMedium: TextStyle(fontFamily: 'Ubuntu')),
      ),
      home:
          isLoggedIn
              ? PermissionHandlerWidget(
                child: HomePage(isLoggedIn: isLoggedIn, controller: controller),
              )
              : HomePage(isLoggedIn: isLoggedIn, controller: controller),
      routes: {
        HomePage.id:
            (context) =>
                HomePage(isLoggedIn: isLoggedIn, controller: controller),
        LoginPage.id: (context) => LoginPage(controller: controller),
        SignUpPage.id: (context) => SignUpPage(),
      },
    );
  }
}

// Widget to request notification permissions and start the foreground service
class PermissionHandlerWidget extends StatefulWidget {
  final Widget child;

  const PermissionHandlerWidget({Key? key, required this.child})
    : super(key: key);

  @override
  State<PermissionHandlerWidget> createState() =>
      _PermissionHandlerWidgetState();
}

class _PermissionHandlerWidgetState extends State<PermissionHandlerWidget>
    with WidgetsBindingObserver {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Register for lifecycle events
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsAndStartService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('App resumed, checking foreground service status');
      // Check if service is running when app comes back to foreground
      _checkServiceOnResume();
    }
  }

  Future<void> _checkServiceOnResume() async {
    try {
      final isRunning = await ForegroundServiceHelper.isServiceRunning();

      if (!isRunning) {
        print('Service not running after resume, attempting to restart');
        // Check if we should restore the service
        await ForegroundServiceHelper.checkAndRestoreService();

        // If still not running and we have permission, start it
        if (!await ForegroundServiceHelper.isServiceRunning() &&
            await ForegroundServiceHelper.hasNotificationPermission()) {
          print('Restarting foreground service after resume');
          await ForegroundServiceHelper.startForegroundService();

          // Double-check and retry if needed
          Future.delayed(Duration(milliseconds: 1000), () async {
            if (!await ForegroundServiceHelper.isServiceRunning()) {
              print('Service restart failed, trying again');
              await ForegroundServiceHelper.startForegroundService();
            } else {
              print('Service successfully restarted after resume');
            }
          });
        }
      } else {
        print('Service is already running after resume');

        // Ensure the MQTT connection is active
        final mqttService = MqttService();
        if (!mqttService.isConnected) {
          print('MQTT not connected after resume, reconnecting');
          await mqttService.connect(source: 'app_resumed');
        }
      }
    } catch (e) {
      print('Error checking service on resume: $e');
    }
  }

  Future<void> _requestPermissionsAndStartService() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Request notification permission explicitly
    bool hasPermission = await _requestNotificationPermissions();

    if (hasPermission) {
      print('Notification permission granted, starting service...');
      // Start the foreground service
      await ForegroundServiceHelper.startForegroundService();
    } else {
      print('Notification permission denied, cannot start foreground service');

      // Show dialog to explain why we need permission (after a short delay to let UI build)
      Future.delayed(Duration(seconds: 1), () {
        _showPermissionDialog();
      });
    }
  }

  Future<bool> _requestNotificationPermissions() async {
    print('Requesting notification permission...');

    // First check current permission status
    PermissionStatus status = await Permission.notification.status;
    print('Current notification permission status: $status');

    // If permission is not granted yet, request it
    if (!status.isGranted) {
      status = await Permission.notification.request();
      print('After request, notification permission status: $status');
    }

    return status.isGranted;
  }

  void _showPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification Permission Required'),
          content: Text(
            'HMES needs notification permission to keep the MQTT service running in the background. '
            'Without this permission, you may not receive notifications when the app is in the background.',
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ForegroundTaskHandler(child: widget.child);
  }
}

// Widget to handle the foreground service
class ForegroundTaskHandler extends StatelessWidget {
  final Widget child;

  const ForegroundTaskHandler({Key? key, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillStartForegroundTask(
      onWillStart: () async {
        // Check if the service is already running
        final isRunning = await ForegroundServiceHelper.isServiceRunning();
        if (isRunning) {
          return true;
        }

        // Check if we have notification permission
        final hasPermission =
            await ForegroundServiceHelper.hasNotificationPermission();
        if (!hasPermission) {
          print(
            'Notification permission not granted, cannot start foreground service',
          );
          return false;
        }

        // Start the service
        return await ForegroundServiceHelper.startForegroundService();
      },
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'hmes_notification_channel',
        channelName: 'HMES Foreground Service',
        channelDescription: 'Keeps the MQTT service running in the background',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 15000,
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
      notificationTitle: 'HMES MQTT Service',
      notificationText: 'Running in background to receive notifications',
      child: child,
    );
  }
}
