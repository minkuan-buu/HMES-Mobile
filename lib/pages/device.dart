import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/helper/logout.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/models/device.dart';
import 'package:hmes/pages/connect-device.dart';
import 'package:http/http.dart' as http;

class DevicePage extends StatefulWidget {
  const DevicePage({super.key, required this.controller});
  static String id = 'device_screen';
  final PageController controller;

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  List<DeviceModel> _device = [];
  bool _isLoading = true;
  String _getDeviceStatus = '';

  @override
  void initState() {
    super.initState();
    _getDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 20),
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
                  'Thiết bị',
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  _device.isNotEmpty
                      ? _device.map((device) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                device.getIsOnline()
                                    ? const Icon(
                                      Icons.circle,
                                      color: Colors.green,
                                    )
                                    : const Icon(
                                      Icons.circle,
                                      color: Colors.red,
                                    ),
                                const SizedBox(width: 10),
                                Text(
                                  device.getName(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Device ID: ${device.getId().split('-')[0]}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Description: ${device.getDescription()}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }).toList()
                      : [
                        const Center(
                          child: Text(
                            'Không có thiết bị nào',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TutorialConnectScreen()),
          );
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future _getDevices() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();
    final response = await http.get(
      Uri.parse('${apiUrl}user/me/devices'),
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
      List<dynamic> dataList = responseJson['response']?['data'] ?? [];
      _device = dataList.map((item) => DeviceModel.fromJson(item)).toList();
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
    } else if (response.statusCode == 404) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _getDeviceStatus = responseJson['message'];
      Fluttertoast.showToast(
        msg: _getDeviceStatus,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _getDeviceStatus = responseJson['message'];
      Fluttertoast.showToast(
        msg: _getDeviceStatus,
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
