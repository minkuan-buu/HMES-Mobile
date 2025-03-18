import 'package:flutter/material.dart';
import 'package:hmes/helper/logout.dart';
import 'package:hmes/pages/change-password.dart';
import 'package:hmes/pages/device.dart';
import 'package:hmes/pages/home.dart';
import 'package:hmes/pages/information.dart';
import 'package:hmes/pages/login.dart';
import 'package:hmes/pages/profile.dart';
import 'package:hmes/pages/reset-password.dart';

class MainView extends StatefulWidget {
  const MainView({super.key, required this.isLoggedIn});
  final bool isLoggedIn;

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  PageController controller = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        controller: controller,
        itemBuilder: (context, index) {
          if (index == 0) {
            return HomePage(
              controller: controller,
              isLoggedIn: widget.isLoggedIn,
            );
          } else if (index == 1) {
            return LoginPage(controller: controller);
          } else if (index == 2) {
            return ResetPasswordPage(controller: controller);
          } else if (index == 3) {
            return VerifyScreen(controller: controller);
          }
          return null;
        },
      ),
    );
  }
}
