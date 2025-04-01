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
          // Header
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Danh sách thiết bị với Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _isLoading = true; // Đặt trạng thái tải lại
                });
                await _getDevices(); // Gọi hàm tải lại thiết bị
                setState(() {
                  _isLoading = false; // Đặt trạng thái không tải lại
                });
              }, // Hàm tải lại thiết bị
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _device.isNotEmpty
                      ? ListView.builder(
                        padding: EdgeInsets.all(20),
                        itemCount: _device.length,
                        itemBuilder: (context, index) {
                          final device = _device[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => DeviceDetailScreen(
                                        deviceId: device.getId(),
                                        deviceName: device.getName(),
                                        controller: widget.controller,
                                      ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color:
                                          device.getIsOnline()
                                              ? Colors.green
                                              : Colors.red,
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
                            ),
                          );
                        },
                      )
                      : const Center(
                        child: Text(
                          'Không có thiết bị nào',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),

      // Nút thêm thiết bị
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TutorialConnectScreen()),
          );
        },
        tooltip: 'Thêm thiết bị',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _getDevices() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

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

    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      List<dynamic> dataList = responseJson['response']?['data'] ?? [];
      _device = dataList.map((item) => DeviceModel.fromJson(item)).toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (response.statusCode == 401) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Logout(controller: widget.controller),
            ),
          );
        });
      }
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _getDeviceStatus = responseJson['message'];

      if (mounted) {
        Fluttertoast.showToast(
          msg: _getDeviceStatus,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: Colors.black,
          fontSize: 16.0,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }
}

class DeviceDetailScreen extends StatefulWidget {
  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.controller,
  });
  final String deviceId;
  final String deviceName;
  final PageController controller;

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  bool _isLoading = true;
  String _getDeviceStatus = '';
  DeviceItemModel? _deviceItem;

  @override
  void initState() {
    super.initState();
    _getDeviceDetails();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _isLoading = true;
                });
                await _getDeviceDetails();
                setState(() {
                  _isLoading = false;
                });
              },
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _deviceItem != null
                      ? Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04, // Thay vì 15
                          vertical: screenHeight * 0.03, // Thay vì 40
                        ),
                        height:
                            screenHeight *
                            0.20, // Tự động thay đổi theo màn hình
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.green, Colors.greenAccent],
                          ),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: screenHeight * 0.001, // Thay vì 10
                                left: screenWidth * 0.06, // Thay vì 110
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .baseline, // Căn theo đường baseline
                                textBaseline:
                                    TextBaseline
                                        .alphabetic, // Đảm bảo căn chuẩn cho chữ
                                children: [
                                  Text(
                                    _deviceItem?.ioTData?.soluteConcentration
                                            .toString() ??
                                        '',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.2,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 5), // Tạo khoảng cách
                                  Text(
                                    'ppm',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.07,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01), // Thay vì 50
                            Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.05,
                                  ), // Thay vì 20
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.thermostat,
                                        color: Colors.white,
                                        size: screenWidth * 0.075,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        _deviceItem?.ioTData?.temperature
                                                .toString() ??
                                            '',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.07,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.05,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Image(
                                        image: const AssetImage(
                                          'assets/images/icons/ph.png',
                                        ),
                                        width: screenWidth * 0.06,
                                        height: screenWidth * 0.06,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        _deviceItem?.ioTData?.ph.toString() ??
                                            '',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.07,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.05,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.water_drop,
                                        color: Colors.white,
                                        size: screenWidth * 0.075,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        _deviceItem?.ioTData?.waterLevel
                                                .toString() ??
                                            '',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.07,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      : const Center(
                        child: Text(
                          'Không có thiết bị nào',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getDeviceDetails() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.get(
      Uri.parse('${apiUrl}user/me/devices/${widget.deviceId}'),
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

    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      Map<String, dynamic> data = responseJson['response']?['data'] ?? {};
      _deviceItem = DeviceItemModel.fromJson(data);
      IoTResModel ioTData = IoTResModel.fromJson(data['ioTData'] ?? {});
      _deviceItem?.setIoTData(ioTData); // Cập nhật dữ liệu IoT vào thiết bị
      setState(() {
        _isLoading = false;
      });
      // Xử lý dữ liệu thiết bị ở đây
      _isLoading = false;
    } else if (response.statusCode == 401) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Logout(controller: widget.controller),
            ),
          );
        });
      }
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _getDeviceStatus = responseJson['message'];

      if (mounted) {
        Fluttertoast.showToast(
          msg: _getDeviceStatus,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: Colors.black,
          fontSize: 16.0,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }
}
