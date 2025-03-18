import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/pages/home.dart';
import 'package:http/http.dart' as http;

class Logout extends StatefulWidget {
  const Logout({super.key, required this.controller});
  final PageController controller;

  @override
  State<Logout> createState() => _LogoutState();
}

class _LogoutState extends State<Logout> {
  String _logoutStatus = '';

  @override
  void initState() {
    super.initState();
    _logout();
  }

  Future<void> _logout() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();
    final response = await http.post(
      Uri.parse('${apiUrl}auth/logout'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
    );

    String? newAccessToken = response.headers['New-Access-Token'];

    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }

    if (response.statusCode == 200) {
      _logoutStatus = 'Đã đăng xuất khỏi thiết bị!';
      await removeToken();
      Fluttertoast.showToast(
        msg: _logoutStatus,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _logoutStatus = responseJson['message'];
      switch (_logoutStatus) {
        case "DeviceId cookie is missing.":
          _logoutStatus = "Đã đăng xuất khỏi thiết bị!";
          break;
        default:
      }

      Fluttertoast.showToast(
        msg: _logoutStatus,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );

      throw _logoutStatus;
    }
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
