import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hmes/pages/device.dart';
import 'package:hmes/pages/login.dart';
import 'package:hmes/components/components.dart';
import 'package:hmes/pages/profile.dart';
import 'package:hmes/pages/register.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/pages/ticket.dart';
import 'package:hmes/services/mqtt-service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hmes/helper/sharedPreferencesHelper.dart';
import 'package:hmes/services/foreground_service.dart';
import 'notification.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  static String id = 'home_screen';
  final bool isLoggedIn;
  final PageController controller;

  const HomePage({
    super.key,
    required this.isLoggedIn,
    required this.controller,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoggedIn = false;
  DateTime? _lastPressed; // Biến lưu thời điểm bấm nút Back lần trước

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.isLoggedIn;
    _lastPressed = null; // Reset khi thoát ứng dụng
    _checkLoginStatus();
    FirebaseMessaging.instance.getToken().then((token) {
      print(
        'FCM Token: $token',
      ); // Token này gửi cho server để push notification
    });

    // No need to start the foreground service here since we're using WillStartForegroundTask
    // which handles it automatically
  }

  // Start the MQTT foreground service only when needed (e.g., after login)
  Future<void> _startMqttForegroundService() async {
    try {
      // Check if already running to avoid duplicate services
      bool isRunning = await ForegroundServiceHelper.isServiceRunning();
      if (!isRunning) {
        print('Starting MQTT foreground service from HomePage...');
        await ForegroundServiceHelper.startForegroundService();
      } else {
        print('MQTT foreground service already running');
      }
    } catch (e) {
      print('Error starting MQTT foreground service: $e');
    }
  }

  // Stop the MQTT foreground service
  Future<void> _stopMqttForegroundService() async {
    try {
      print('Stopping MQTT foreground service...');
      await ForegroundServiceHelper.stopForegroundService();
    } catch (e) {
      print('Error stopping MQTT foreground service: $e');
    }
  }

  void _checkLoginStatus() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();
    bool isLoggedIn =
        token.isNotEmpty && refreshToken.isNotEmpty && deviceId.isNotEmpty;

    bool previousLoginState = _isLoggedIn;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });

    // Only handle service state changes when login status changes
    if (isLoggedIn != previousLoginState) {
      // Give UI time to update before handling service
      Future.delayed(Duration(milliseconds: 500), () {
        if (isLoggedIn && !previousLoginState) {
          // User just logged in, service should be started by WillStartForegroundTask
          print(
            'Login detected, service should be handled by WillStartForegroundTask',
          );
        } else if (!isLoggedIn && previousLoginState) {
          // User just logged out, stop the service
          _stopMqttForegroundService();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TopScreenImage(screenImageName: 'home.jpg'),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 15.0,
                        left: 15,
                        bottom: 15,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const ScreenTitle(title: 'HMES'),
                          const Text(
                            'Quản lý thiết bị thủy canh của bạn một cách dễ dàng.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                          const SizedBox(height: 25),
                          Hero(
                            tag: 'login_btn',
                            child: CustomButton(
                              buttonText: 'Đăng nhập',
                              onPressed: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  LoginPage.id,
                                );
                                if (result == true) {
                                  _checkLoginStatus();
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Hero(
                            tag: 'signup_btn',
                            child: CustomButton(
                              buttonText: 'Đăng ký',
                              isOutlined: true,
                              onPressed: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  SignUpPage.id,
                                );
                                if (result == true) {
                                  _checkLoginStatus();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return WillPopScope(
        onWillPop: () async {
          DateTime now = DateTime.now();
          if (_lastPressed == null ||
              now.difference(_lastPressed!) > Duration(seconds: 2)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Nhấn lần nữa để thoát ứng dụng")),
            );
            setState(() {
              _lastPressed = now;
            });
            return false;
          }

          SystemNavigator.pop();
          return true;
        },
        child: BottomNavigationBarExample(controller: widget.controller),
      );
    }
  }
}

class BottomNavigationBarExample extends StatefulWidget {
  final PageController controller;

  const BottomNavigationBarExample({super.key, required this.controller});

  @override
  State<BottomNavigationBarExample> createState() =>
      _BottomNavigationBarExampleState();
}

class _BottomNavigationBarExampleState
    extends State<BottomNavigationBarExample> {
  int _selectedIndex = 0;
  bool hasNewNotification = false; // Trạng thái thông báo mới
  final PageController _pageController = PageController();
  late MqttService mqttService; // Khai báo mqttService theo kiểu instance
  String message = 'Chưa nhận thông báo';

  // Set to track already processed notification IDs
  final Set<String> _processedNotificationIds = {};

  @override
  void initState() {
    super.initState();
    // Get the singleton instance but DON'T connect - foreground service will handle this
    mqttService = MqttService();

    // Only set up the callback to update the UI when notifications arrive
    mqttService.onNewNotification = (message) => onNewNotification(message);

    // We no longer call mqttService.connect() here as the foreground service handles this
    debugPrint(
      'Home UI initialized, using MQTT connection from foreground service',
    );
  }

  void _changeIndex(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        hasNewNotification = false; // Xóa chấm khi mở trang thông báo
      }
      _pageController.jumpToPage(index);
    });
  }

  // Hàm cập nhật khi có thông báo mới
  void onNewNotification(String message) {
    try {
      // Parse the message to get notification details
      final Map<String, dynamic> notificationData = jsonDecode(message);

      // Generate a unique ID for this notification to avoid duplicates
      final String title = notificationData['title'] ?? '';
      final String body = notificationData['message'] ?? '';
      final String notificationId =
          '$title-$body-${DateTime.now().millisecondsSinceEpoch}';

      // Only update UI, don't show another notification since MqttService already shows one
      setState(() {
        this.message = message; // Cập nhật thông báo mới
        hasNewNotification = true; // Đánh dấu có thông báo mới
      });

      debugPrint('UI updated for notification: $title');
    } catch (e) {
      debugPrint('Error processing notification for UI update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          DevicePage(controller: widget.controller),
          // Text("Thông báo", style: TextStyle(fontSize: 20)),
          NotificationPage(controller: widget.controller),
          Ticket(controller: widget.controller),
          ProfilePage(controller: widget.controller),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _changeIndex,
        unselectedItemColor: Colors.grey,
        selectedItemColor: const Color(0xFF3F51B5),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: "Thiết bị",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (hasNewNotification) // Hiển thị chấm đỏ nếu có thông báo
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: "Thông báo",
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: "Hỗ trợ",
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Tài khoản",
          ),
        ],
      ),
    );
  }
}
