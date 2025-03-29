import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/helper/logout.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/models/profile.dart';
import 'package:http/http.dart' as http;
import 'package:loading_overlay/loading_overlay.dart';

class InfomationPage extends StatefulWidget {
  const InfomationPage({super.key, required this.controller});
  final PageController controller;

  @override
  State<InfomationPage> createState() => _InfomationPageState();
}

class _InfomationPageState extends State<InfomationPage> {
  ProfileModel? _profile;
  bool _isLoading = true;
  String _getInformationStatus = '';

  @override
  void initState() {
    super.initState();
    _getProfileInformation();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Thông tin cá nhân')),
        body: Stack(
          clipBehavior: Clip.none, // Cho phép avatar lấn ra ngoài Stack
          children: [
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, // Thay vì 15
                vertical: screenHeight * 0.05, // Thay vì 40
              ),
              height: screenHeight * 0.20, // Tự động thay đổi theo màn hình
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue, Colors.purple],
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: screenHeight * 0.015, // Thay vì 10
                      left: screenWidth * 0.3, // Thay vì 110
                    ),
                    child: Text(
                      _profile?.name ?? '',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05, // Responsive font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05), // Thay vì 50
                  Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.05,
                    ), // Thay vì 20
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.email,
                          color: Colors.white,
                          size: screenWidth * 0.06,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          _profile?.email ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02), // Thay vì 15
                  Padding(
                    padding: EdgeInsets.only(left: screenWidth * 0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: screenWidth * 0.06,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          _profile?.phone ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: screenHeight * 0.005, // Scale theo chiều cao màn hình
              left: screenWidth * 0.1,
              child: CircleAvatar(
                radius: screenWidth * 0.13, // Tỷ lệ avatar theo màn hình
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: screenWidth * 0.12, // Tỷ lệ ảnh avatar bên trong
                  backgroundImage:
                      (_profile?.attachment != null &&
                              _profile!.attachment.isNotEmpty)
                          ? NetworkImage(_profile!.attachment) // Ảnh từ mạng
                          : const AssetImage('assets/images/avatar.png')
                              as ImageProvider, // Ảnh mặc định
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future _getProfileInformation() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();
    final response = await http.get(
      Uri.parse('${apiUrl}user/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
    );

    String? newAccessToken = response.headers['new-access-token'];

    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      Map<String, dynamic> data = responseJson['response']?['data'];
      _profile = ProfileModel.fromJson(data);
      setState(() {
        _isLoading = false;
      });
    } else if (response.statusCode == 401) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Logout(controller: widget.controller),
        ),
      );
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _getInformationStatus = responseJson['message'];
      Fluttertoast.showToast(
        msg: _getInformationStatus,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
      Navigator.pop(context);
    }
  }
}
