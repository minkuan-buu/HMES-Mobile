import 'package:flutter/material.dart';
import 'package:hmes/pages/device.dart';
import 'package:hmes/pages/login.dart';
import 'package:hmes/components/components.dart';
import 'package:hmes/pages/profile.dart';
import 'package:hmes/pages/register.dart';

class HomePage extends StatefulWidget {
  static String id = 'home_screen';
  final bool isLoggedIn;

  const HomePage({super.key, required this.isLoggedIn});

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
                          const ScreenTitle(title: 'Chào mừng đến với HMES'),
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(),
                                  ),
                                );
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
      return const BottomNavigationBarExample();
    }
  }
}

class BottomNavigationBarExample extends StatefulWidget {
  const BottomNavigationBarExample({super.key});

  @override
  State<BottomNavigationBarExample> createState() =>
      _BottomNavigationBarExampleState();
}

class _BottomNavigationBarExampleState
    extends State<BottomNavigationBarExample> {
  int _selectedIndex = 0;
  static const TextStyle style = TextStyle(color: Colors.black, fontSize: 20);

  static final List<Widget> _bodyContent = [
    Text("Thiết bị", style: style),
    Text("Thông báo", style: style),
    Text("Tài khoản", style: style),
  ];

  // Danh sách tiêu đề theo từng trang
  static final List<String> _titles = ["Thiết bị", "Thông báo", "Tài khoản"];

  void _changeIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            _selectedIndex == 0
                ? const DevicePage()
                : _selectedIndex == 2
                ? const ProfilePage()
                : _bodyContent.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _changeIndex,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: "Thiết bị"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: "Thông báo",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
        ],
      ),
    );
  }
}
