import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hmes/services/mqtt-service.dart';
import 'package:permission_handler/permission_handler.dart';

// The callback function should always be a top-level function
@pragma('vm:entry-point')
void startCallback() {
  // The port to communicate with the isolate
  FlutterForegroundTask.setTaskHandler(MqttTaskHandler());

  // Log that callback was triggered
  debugPrint('Foreground service callback triggered');
}

class MqttTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  MqttService? _mqttService;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  int _connectionAttempts = 0;
  static const int _maxConnectionAttempts = 5;
  DateTime? _lastConnectionAttempt;
  bool _isInitialized = false;

  // This static flag helps track if there's an active handler
  static bool _isHandlerActive = false;

  // Track processed notification IDs
  final Set<String> _processedNotifications = {};

  // Track if we're in a restart situation
  static bool _wasRestartedAfterDestroy = false;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    if (_isInitialized) {
      debugPrint(
        'MqttTaskHandler: Already initialized, skipping initialization',
      );
      return;
    }

    // First set the static flag to indicate we're running
    if (MqttTaskHandler._isHandlerActive) {
      debugPrint(
        'WARNING: Another MqttTaskHandler is already active. This may cause duplicate connections.',
      );
    }
    MqttTaskHandler._isHandlerActive = true;

    _isInitialized = true;
    _sendPort = sendPort;
    _connectionAttempts = 0;
    _lastConnectionAttempt = null;

    // Log start of handler
    debugPrint(
      'MqttTaskHandler: Starting in foreground task - this is the primary MQTT connection',
    );

    // Initialize the MQTT service - use the singleton to prevent duplicates
    _mqttService = MqttService();

    // Check if we're restarting after being destroyed
    final wasDestroyed =
        await FlutterForegroundTask.getData(key: 'serviceWasDestroyed') == true;

    // Connect with a slight delay to avoid blocking the isolate startup
    // But use a shorter delay if we're restarting after being destroyed
    final connectDelay = wasDestroyed ? 500 : 3000;
    debugPrint(
      'MqttTaskHandler: Connecting after ${connectDelay}ms delay (wasDestroyed: $wasDestroyed)',
    );

    _reconnectTimer = Timer(Duration(milliseconds: connectDelay), () {
      debugPrint('MqttTaskHandler: Delayed connect triggered');
      _connectToMqtt();
    });

    // Start a heartbeat timer with less frequent checks to avoid overloading
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      debugPrint('MqttTaskHandler: Heartbeat timer triggered');
      _sendHeartbeat();
    });

    // Send event to main isolate
    _sendPort?.send('mqtt_task_started');

    // Save flag in case we need to auto-restart later
    await FlutterForegroundTask.saveData(key: 'serviceActive', value: true);

    // Reset the destroyed flag since we're now started
    if (wasDestroyed) {
      await FlutterForegroundTask.saveData(
        key: 'serviceWasDestroyed',
        value: false,
      );
    }
  }

  // Safely connect to MQTT with retry logic
  Future<void> _connectToMqtt() async {
    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();

    // Don't attempt to connect if we're already trying
    if (_isConnecting) {
      debugPrint('MqttTaskHandler: Already trying to connect, skipping');
      return;
    }

    // Implement rate limiting for connection attempts
    final now = DateTime.now();
    if (_lastConnectionAttempt != null) {
      final timeSinceLastAttempt = now.difference(_lastConnectionAttempt!);
      if (timeSinceLastAttempt.inSeconds < 5) {
        debugPrint('MqttTaskHandler: Connection attempt too soon, delaying...');
        _reconnectTimer = Timer(Duration(seconds: 5), () {
          _connectToMqtt();
        });
        return;
      }
    }
    _lastConnectionAttempt = now;

    // Implement exponential backoff for repeated failed attempts
    if (_connectionAttempts >= _maxConnectionAttempts) {
      debugPrint(
        'MqttTaskHandler: Max connection attempts reached, waiting longer before retry',
      );
      // Reset after a longer delay
      _connectionAttempts = 0;
      _reconnectTimer = Timer(Duration(minutes: 5), () {
        _connectToMqtt();
      });
      return;
    }

    _isConnecting = true;
    _connectionAttempts++;

    try {
      debugPrint(
        'MqttTaskHandler: Attempting to connect to MQTT (attempt $_connectionAttempts)',
      );
      // Identify ourselves as the foreground service when connecting
      final connected = await _mqttService!.connect(
        source: 'foreground_service',
      );
      if (connected) {
        debugPrint('MqttTaskHandler: Successfully connected to MQTT');
        _sendPort?.send('mqtt_connected');
        _connectionAttempts = 0; // Reset on success

        // Update notification to show connected status
        await FlutterForegroundTask.updateService(
          notificationTitle: 'HMES dịch vụ thông báo - Đã kết nối',
          notificationText: 'Nhận thông báo trong nền',
        );
      } else {
        debugPrint('MqttTaskHandler: Failed to connect to MQTT');

        // Update notification to show connection error
        await FlutterForegroundTask.updateService(
          notificationTitle: 'HMES dịch vụ thông báo - Đang kết nối',
          notificationText: 'Đang thử kết nối lại...',
        );

        _scheduleReconnect();
      }
    } catch (e) {
      debugPrint('MqttTaskHandler: Error connecting to MQTT: $e');
      _sendPort?.send('mqtt_connection_error: $e');

      // Update notification to show connection error
      await FlutterForegroundTask.updateService(
        notificationTitle: 'HMES dịch vụ thông báo - Lỗi kết nối',
        notificationText: 'Lỗi kết nối, thử lại...',
      );

      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _scheduleReconnect() {
    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();

    // Exponential backoff: 5s, 10s, 20s, 40s, 80s (capped at 2 minutes)
    int delaySeconds = 5 * (1 << (_connectionAttempts - 1));
    delaySeconds = delaySeconds > 120 ? 120 : delaySeconds;
    debugPrint(
      'MqttTaskHandler: Scheduling reconnect in $delaySeconds seconds',
    );

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isConnecting) {
        _connectToMqtt();
      }
    });
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Handle any events received from the main isolate
    debugPrint('MqttTaskHandler: Received event from main isolate');
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // This method is called periodically based on the interval set in ForegroundTaskOptions
    // Check connection status only, don't do heavy work here
    try {
      if (_mqttService != null && !_isConnecting) {
        if (!_mqttService!.isConnected) {
          debugPrint(
            'MqttTaskHandler: MQTT not connected in onRepeatEvent, triggering reconnect',
          );
          _connectToMqtt();
        } else {
          debugPrint('MqttTaskHandler: MQTT connected in onRepeatEvent');

          // Check if we need to refresh the connection
          final now = DateTime.now();
          if (_lastConnectionAttempt != null) {
            final timeSinceLastAttempt = now.difference(
              _lastConnectionAttempt!,
            );
            if (timeSinceLastAttempt.inMinutes > 30) {
              // Refresh connection every 30 minutes for long-term reliability
              debugPrint(
                'MqttTaskHandler: Refreshing MQTT connection after 30 minutes',
              );
              _connectToMqtt();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('MqttTaskHandler: Error in onRepeatEvent: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    debugPrint('MqttTaskHandler: Service being destroyed, cleaning up');

    // Save flag that we're being destroyed but should restart
    await FlutterForegroundTask.saveData(
      key: 'serviceWasDestroyed',
      value: true,
    );
    MqttTaskHandler._wasRestartedAfterDestroy = true;

    // Reset the static flag when this handler is destroyed
    MqttTaskHandler._isHandlerActive = false;

    // Cancel timers
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    // Cleanly disconnect MQTT
    try {
      if (_mqttService != null && _mqttService!.isConnected) {
        debugPrint('MqttTaskHandler: Disconnecting MQTT on destroy');
        _mqttService!.disconnect();
      }
    } catch (e) {
      debugPrint('MqttTaskHandler: Error during cleanup: $e');
    }

    // Send a final message to the main isolate
    sendPort?.send('mqtt_service_destroyed');

    // Schedule service to restart immediately
    _scheduleServiceRestart();

    // Set a failsafe timer to restart the service after a short delay
    // This acts as a backup in case the immediate restart fails
    Timer(const Duration(seconds: 3), () async {
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (!isRunning) {
        debugPrint(
          'MqttTaskHandler: Failsafe timer triggered, restarting service',
        );
        await FlutterForegroundTask.startService(
          notificationTitle: 'HMES dịch vụ thông báo - Tiếp tục',
          notificationText: 'Tiếp tục nhận thông báo',
          callback: startCallback,
        );
      }
    });
  }

  @override
  void onButtonPressed(String id) {
    debugPrint('MqttTaskHandler: Button pressed: $id');

    if (id == 'refreshButton') {
      if (!_isConnecting) {
        debugPrint(
          'MqttTaskHandler: Refresh button pressed, reconnecting MQTT',
        );
        _connectToMqtt();
      } else {
        debugPrint(
          'MqttTaskHandler: Already connecting, ignoring refresh button',
        );
      }
    }
  }

  void _sendHeartbeat() {
    debugPrint('MqttTaskHandler: Sending heartbeat');

    // Check if MQTT is still connected, reconnect if necessary
    if (_mqttService != null && !_isConnecting) {
      if (!_mqttService!.isConnected) {
        debugPrint(
          'MqttTaskHandler: MQTT not connected during heartbeat, reconnecting',
        );
        _connectToMqtt();
      } else {
        debugPrint('MqttTaskHandler: MQTT is connected during heartbeat');

        // Update notification to show active status
        try {
          FlutterForegroundTask.updateService(
            notificationTitle: 'HMES dịch vụ thông báo - Đang hoạt động',
            notificationText: 'Đã kết nối và nhận thông báo',
          );
        } catch (e) {
          debugPrint('MqttTaskHandler: Error updating notification: $e');
        }
      }
      _sendPort?.send('mqtt_heartbeat');
    }
  }

  // Helper to restart the service after destruction
  Future<void> _scheduleServiceRestart() async {
    try {
      // Check if we should restart (based on saved data)
      final shouldRestart =
          await FlutterForegroundTask.getData(key: 'serviceActive') == true;

      if (shouldRestart) {
        debugPrint(
          'MqttTaskHandler: Service was active before destroy, scheduling restart',
        );

        // Wait a short time before restarting to avoid rapid restart cycles
        Timer(const Duration(milliseconds: 500), () async {
          debugPrint(
            'MqttTaskHandler: Attempting to restart service after destruction',
          );
          final isRunning = await FlutterForegroundTask.isRunningService;

          if (!isRunning) {
            debugPrint(
              'MqttTaskHandler: Service not running, restarting foreground service',
            );
            // Restart the foreground service
            final result = await FlutterForegroundTask.startService(
              notificationTitle: 'HMES dịch vụ thông báo - Tiếp tục',
              notificationText: 'Tiếp tục nhận thông báo',
              callback: startCallback,
            );
            debugPrint('MqttTaskHandler: Service restart result: $result');

            // Verify the restart and try again if needed
            Timer(const Duration(milliseconds: 1000), () async {
              final isRunningAfterRestart =
                  await FlutterForegroundTask.isRunningService;
              if (!isRunningAfterRestart) {
                debugPrint(
                  'MqttTaskHandler: Service failed to restart, trying again',
                );
                await FlutterForegroundTask.startService(
                  notificationTitle: 'HMES dịch vụ thông báo - Tiếp tục',
                  notificationText: 'Tiếp tục nhận thông báo',
                  callback: startCallback,
                );
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('MqttTaskHandler: Error scheduling service restart: $e');
    }
  }
}

class ForegroundServiceHelper {
  // Initialize the foreground task
  static Future<void> initForegroundTask() async {
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'hmes_notification_channel',
          channelName: 'HMES Foreground Service',
          channelDescription:
              'Keeps the MQTT service running in the background',
          channelImportance: NotificationChannelImportance.HIGH,
          priority: NotificationPriority.HIGH,
          iconData: const NotificationIconData(
            resType: ResourceType.mipmap,
            resPrefix: ResourcePrefix.ic,
            name: 'launcher',
          ),
          buttons: [
            const NotificationButton(id: 'refreshButton', text: 'Làm mới'),
          ],
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: const ForegroundTaskOptions(
          interval: 15000, // Increased to 15 seconds to reduce CPU load
          isOnceEvent: false,
          autoRunOnBoot: true,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
      print('Foreground task initialized successfully');

      // Set autostart data
      await FlutterForegroundTask.saveData(key: 'shouldAutoStart', value: true);

      // Check if the service was previously destroyed and should be restored
      checkAndRestoreService();

      // If we're initializing after app restart, ensure service is running
      Future.delayed(Duration(seconds: 1), () async {
        final isRunning = await isServiceRunning();
        if (!isRunning && await hasNotificationPermission()) {
          debugPrint('Starting service during initialization');
          await startForegroundService();
        }
      });
    } catch (e) {
      print('Error initializing foreground task: $e');
    }
  }

  // Check if service was previously running and should be restored
  static Future<void> checkAndRestoreService() async {
    try {
      // Check stored flags to see if service was previously active
      final wasActive =
          await FlutterForegroundTask.getData(key: 'serviceActive') == true;
      final wasDestroyed =
          await FlutterForegroundTask.getData(key: 'serviceWasDestroyed') ==
          true;
      final shouldAutoStart =
          await FlutterForegroundTask.getData(key: 'shouldAutoStart') == true;

      // Check current running state
      final isCurrentlyRunning = await isServiceRunning();

      debugPrint(
        'Service status - Active: $wasActive, Destroyed: $wasDestroyed, AutoStart: $shouldAutoStart, Running: $isCurrentlyRunning',
      );

      if (!isCurrentlyRunning && (wasActive || shouldAutoStart)) {
        debugPrint('Service should be running but isn\'t, restoring...');

        // Clear the destroyed flag
        await FlutterForegroundTask.saveData(
          key: 'serviceWasDestroyed',
          value: false,
        );

        // Check if we have the required permissions
        if (await hasNotificationPermission()) {
          debugPrint('Have notification permission, restarting service');
          await startForegroundService();

          // Verify restart
          Future.delayed(Duration(milliseconds: 1000), () async {
            if (!await isServiceRunning()) {
              debugPrint('Service restart verification failed, trying again');
              await startForegroundService();
            }
          });
        } else {
          debugPrint('Missing notification permission, cannot restart service');
        }
      } else if (isCurrentlyRunning) {
        debugPrint('Service is already running, no need to restore');
      }
    } catch (e) {
      debugPrint('ForegroundServiceHelper: Error checking service state: $e');
    }
  }

  // Check if we have notification permission
  static Future<bool> hasNotificationPermission() async {
    try {
      // First check with permission_handler for better compatibility
      if (await Permission.notification.isGranted) {
        debugPrint('Notification permission is granted (permission_handler)');
        return true;
      }

      // Then check with flutter_foreground_task as fallback
      final permissionStatus =
          await FlutterForegroundTask.checkNotificationPermission();
      debugPrint(
        'Notification permission status (foreground_task): $permissionStatus',
      );
      return permissionStatus == 2; // 2 is the value for granted
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      debugPrint('Requesting notification permission...');

      // First try to request with permission_handler for better UI
      final status = await Permission.notification.request();
      if (status.isGranted) {
        debugPrint('Notification permission granted via permission_handler');
        return true;
      }

      // If that didn't work, try with flutter_foreground_task
      debugPrint('Requesting notification permission via foreground_task...');
      await FlutterForegroundTask.requestNotificationPermission();

      // Wait a moment before checking if permission was granted
      await Future.delayed(Duration(milliseconds: 500));

      // Check if permission was granted
      return await hasNotificationPermission();
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  // Start the foreground service
  static Future<bool> startForegroundService() async {
    try {
      debugPrint('Starting foreground service...');

      // Check if the service is already running
      if (await isServiceRunning()) {
        debugPrint('Foreground service is already running');
        return true;
      }

      // Ensure we have notification permission before even trying to start
      debugPrint('Checking notification permission...');
      if (!await hasNotificationPermission()) {
        debugPrint('Notification permission not granted, requesting...');
        bool permissionGranted = await requestNotificationPermission();

        if (!permissionGranted) {
          debugPrint(
            'Failed to get notification permission, cannot start service',
          );
          return false;
        }

        // Wait a moment after permission is granted before starting the service
        await Future.delayed(Duration(milliseconds: 500));
      }

      debugPrint('Permission granted, starting foreground service...');

      // Set up Android power management for longer background running
      await FlutterForegroundTask.saveData(key: 'keepRunning', value: true);
      await FlutterForegroundTask.saveData(key: 'serviceActive', value: true);
      await FlutterForegroundTask.saveData(
        key: 'serviceWasDestroyed',
        value: false,
      );
      await FlutterForegroundTask.saveData(key: 'shouldAutoStart', value: true);

      // Start the foreground service
      final result = await FlutterForegroundTask.startService(
        notificationTitle: 'HMES dịch vụ thông báo',
        notificationText: 'Chạy trong nền để nhận thông báo',
        callback: startCallback,
      );

      debugPrint('Foreground service start result: $result');

      // Wait a moment and check if the service is actually running
      await Future.delayed(Duration(seconds: 1));
      final isRunning = await isServiceRunning();
      debugPrint('After starting, service running: $isRunning');

      // If service failed to start, try one more time
      if (!isRunning && result) {
        debugPrint('Service reported success but not running, retrying...');
        final retryResult = await FlutterForegroundTask.startService(
          notificationTitle: 'HMES dịch vụ thông báo',
          notificationText: 'Chạy trong nền để nhận thông báo',
          callback: startCallback,
        );
        debugPrint('Service retry result: $retryResult');
      }

      return result;
    } catch (e) {
      debugPrint('Error starting foreground service: $e');
      return false;
    }
  }

  // Stop the foreground service
  static Future<bool> stopForegroundService() async {
    try {
      if (!await isServiceRunning()) {
        print('Foreground service is not running');
        return true;
      }

      final result = await FlutterForegroundTask.stopService();
      print('Foreground service stop result: $result');
      return result;
    } catch (e) {
      print('Error stopping foreground service: $e');
      return false;
    }
  }

  // Check if service is running
  static Future<bool> isServiceRunning() async {
    try {
      final running = await FlutterForegroundTask.isRunningService;
      print('Is foreground service running: $running');
      return running;
    } catch (e) {
      print('Error checking if service is running: $e');
      return false;
    }
  }
}
