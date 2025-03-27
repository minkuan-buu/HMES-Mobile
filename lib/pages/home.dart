import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hmes/pages/device.dart';
import 'package:hmes/pages/login.dart';
import 'package:hmes/components/components.dart';
import 'package:hmes/pages/profile.dart';
import 'package:hmes/pages/register.dart';
import 'package:hmes/helper/secureStorageHelper.dart';

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
  }

  void _checkLoginStatus() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();
    bool isLoggedIn =
        token.isNotEmpty && refreshToken.isNotEmpty && deviceId.isNotEmpty;

    setState(() {
      _isLoggedIn = isLoggedIn;
    });
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
  final PageController _pageController = PageController();

  void _changeIndex(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index); // Chuyển trang ngay lập tức
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // Ngăn vuốt ngang
        children: [
          DevicePage(controller: widget.controller), // Trang Thiết bị
          Text("Thông báo", style: TextStyle(fontSize: 20)),
          ProfilePage(controller: widget.controller), // Trang Tài khoản
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _changeIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: "Thiết bị"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Thông báo",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
        ],
      ),
    );
  }
}
