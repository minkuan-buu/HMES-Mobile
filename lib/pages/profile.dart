import 'dart:ui';

import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  static String id = 'profile_screen';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<String> menuItems = [
    'Thông tin cá nhân',
    'Thay đổi mật khẩu',
    'Đăng xuất',
  ];

  final List<IconData> menuIcons = [Icons.person, Icons.lock, Icons.logout];

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
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Căn lề trái tất cả nội dung
                mainAxisSize: MainAxisSize.min,
                children: List.generate(menuItems.length, (index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            Icon(menuIcons[index], color: Colors.blue),
                            const SizedBox(width: 10),
                            Text(
                              menuItems[index],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < menuItems.length - 1)
                        Divider(color: Colors.grey),
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
