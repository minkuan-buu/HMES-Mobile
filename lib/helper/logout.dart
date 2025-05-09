import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/pages/home.dart';
import 'package:hmes/services/foreground_service.dart';
import 'package:hmes/services/mqtt-service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

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
    // First disconnect MQTT service
    MqttService().disconnect();

    // Also stop the foreground service to prevent reconnection attempts
    await ForegroundServiceHelper.stopForegroundService();

    // Set auto-start flag to false to prevent service from restarting automatically
    await FlutterForegroundTask.saveData(key: 'shouldAutoStart', value: false);
    await FlutterForegroundTask.saveData(key: 'serviceActive', value: false);

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

    await removeToken(); // Clear tokens regardless of success or failure

    if (response.statusCode == 200) {
      _logoutStatus = 'Đã đăng xuất khỏi thiết bị!';
    } else {
      _logoutStatus = 'Phiên đăng nhập đã hết hạn!';
    }

    Fluttertoast.showToast(
      msg: _logoutStatus,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      textColor: Colors.black,
      fontSize: 16.0,
    );

    if (mounted) {
      setState(() {}); // Update UI if widget not disposed

      // Navigate after UI update
      Future.microtask(() {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder:
                  (context) => HomePage(
                    isLoggedIn: false,
                    controller: widget.controller,
                  ),
            ),
            (Route<dynamic> route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
