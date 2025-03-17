import 'package:flutter/material.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Chuyển đến trang đăng nhập
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  HomePage(isLoggedIn: false, controller: widget.controller),
        ),
      );
    });
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
