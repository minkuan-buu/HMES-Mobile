import 'package:flutter/material.dart';
import 'package:hmes/helper/logout.dart';
import 'package:hmes/pages/change-password.dart';
import 'package:hmes/pages/information.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.controller});
  static String id = 'profile_screen';
  final PageController controller;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<String> menuItems = [
    'Thông tin cá nhân',
    'Thay đổi mật khẩu',
    'Đăng xuất',
  ];
  int? selectedIndex;

  late List<InkWell> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      InkWell(
        onTap: () {
          widget.controller.animateToPage(
            6,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          );
        },
      ),
      InkWell(
        onTap: () {
          widget.controller.animateToPage(
            7,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          );
        },
      ),
      InkWell(
        onTap: () {
          widget.controller.animateToPage(
            4,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          );
        },
      ),
    ];
  }

  final List<IconData> menuIcons = [Icons.person, Icons.lock, Icons.logout];

  void _navigateToPage(int index, BuildContext context) {
    setState(() {
      selectedIndex = index; // Cập nhật mục được chọn
    });

    // Hiển thị hiệu ứng trước khi chuyển trang
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => pages[index]),
        ).then((_) {
          setState(() {
            selectedIndex = null; // Reset khi quay lại trang trước
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(top: 35, left: 20, right: 20, bottom: 20),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Tài khoản',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // CircleAvatar(
                //   backgroundColor: Colors.white,
                //   child: Icon(Icons.person, color: Colors.blue),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 5,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(menuItems.length, (index) {
                  bool isSelected =
                      selectedIndex == index; // Kiểm tra mục nào đang chọn

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index; // Cập nhật mục được chọn
                          });

                          // Tự động xóa hiệu ứng sau 500ms để trở lại trạng thái ban đầu
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              setState(() {
                                selectedIndex = null;
                              });
                            }
                          });
                          _navigateToPage(index, context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 300,
                          ), // Hiệu ứng mượt hơn
                          curve: Curves.easeInOut, // Bo góc hiệu ứng mượt hơn
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                menuIcons[index],
                                color:
                                    isSelected ? Colors.blue : Colors.black54,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                menuItems[index],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isSelected ? Colors.blue : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (index < menuItems.length - 1)
                        const Divider(
                          color: Color.fromARGB(255, 197, 197, 197),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
