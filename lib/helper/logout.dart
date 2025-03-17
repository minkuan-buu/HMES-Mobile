import 'package:flutter/material.dart';
import 'package:hmes/helper/tokenHelper.dart';
import 'package:hmes/pages/home.dart';

class Logout extends StatefulWidget {
  const Logout({super.key, required this.controller});

  final PageController controller;
  @override
  State<Logout> createState() => _LogoutState();
}

class _LogoutState extends State<Logout> {
  @override
  void initState() {
    super.initState();
    _logout();
  }

  Future<void> _logout() async {
    await removeToken();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InkWell(
        onTap: () {
          widget.controller.animateToPage(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          );
        },
      );
    });
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
