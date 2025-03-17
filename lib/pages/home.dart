import 'package:flutter/material.dart';
import 'package:hmes/pages/device.dart';
import 'package:hmes/pages/login.dart';
import 'package:hmes/components/components.dart';
import 'package:hmes/pages/profile.dart';
import 'package:hmes/pages/register.dart';

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
  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      // Sử dụng widget.isLoggedIn thay vì HomePage.isLoggedIn
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
                              onPressed: () {
                                Navigator.pushNamed(context, LoginPage.id);
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Hero(
                            tag: 'signup_btn',
                            child: CustomButton(
                              buttonText: 'Đăng ký',
                              isOutlined: true,
                              onPressed: () {
                                Navigator.pushNamed(context, SignUpPage.id);
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
      return BottomNavigationBarExample(controller: widget.controller);
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
