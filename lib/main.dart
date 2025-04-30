import 'package:flutter/material.dart';
import 'package:hmes/pages/home.dart';
import 'package:hmes/pages/login.dart';
import 'package:hmes/pages/register.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hmes/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // Request notification permission for Android 13+
  await _requestNotificationPermissions();
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

Future<void> _requestNotificationPermissions() async {
  try {
    // Request notification permission
    PermissionStatus status = await Permission.notification.request();
    print('Notification permission status: $status');

    if (status.isDenied || status.isPermanentlyDenied) {
      print('Notification permission denied by user');
    }
  } catch (e) {
    print('Error requesting notification permission: $e');
  }
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
      home: HomePage(
        isLoggedIn: isLoggedIn,
        controller: controller,
      ), // ✅ Truyền trực tiếp vào HomePage
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
