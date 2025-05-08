import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/helper/logout.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/models/device.dart';
import 'package:hmes/pages/connect-device.dart';
import 'package:hmes/services/mqtt-service.dart';
import 'package:intl/intl.dart';
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
                              _goToDeviceDetail(
                                device.getId(),
                                device.getName(),
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

  void _goToDeviceDetail(String deviceId, String deviceName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DeviceDetailScreen(
              deviceId: deviceId,
              deviceName: deviceName,
              controller: widget.controller,
            ),
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true; // Đặt trạng thái tải lại
      });
      // Reload lại dữ liệu khi quay về
      _getDevices();
    }
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
        setState(() {
          _isLoading = false;
        });

        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (mounted) {
        //     Navigator.pop(context);
        //   }
        // });
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
  bool _isButtonRefreshing = false;
  bool _isLoading = true;
  String _getDeviceStatus = '';
  bool hasNewData = false;
  DeviceItemModel? _deviceItem;
  int selectedOption = 5; // Default value for the dropdown

  @override
  void initState() {
    super.initState();
    _getDeviceDetails();
  }

  String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm, dd/MM/yyyy').format(dateTime);
  }

  void onNewData() {
    setState(() {
      hasNewData = true;
    });
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
            Navigator.pop(context, true);
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
                      ? Column(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04, // Thay vì 15
                              vertical: screenHeight * 0.03, // Thay vì 40
                            ),
                            height:
                                screenHeight *
                                0.25, // Tự động thay đổi theo màn hình
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                        _deviceItem
                                                ?.ioTData
                                                ?.soluteConcentration
                                                .toStringAsFixed(1) ??
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
                                //SizedBox(height: screenHeight * 0.1), // Thay vì 50
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.06, // Thay vì 110
                                    right: screenWidth * 0.06, // Thay vì 110
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.thermostat,
                                            color: Colors.white,
                                            size: screenWidth * 0.06,
                                          ),
                                          SizedBox(width: screenWidth * 0.02),
                                          Text(
                                            _deviceItem?.ioTData?.temperature
                                                    .toStringAsFixed(1) ??
                                                '',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: screenWidth * 0.055,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Image(
                                            image: const AssetImage(
                                              'assets/images/icons/ph.png',
                                            ),
                                            width: screenWidth * 0.055,
                                            height: screenWidth * 0.055,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: screenWidth * 0.02),
                                          Text(
                                            _deviceItem?.ioTData?.ph
                                                    .toStringAsFixed(2) ??
                                                '',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: screenWidth * 0.055,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.water_drop,
                                            color: Colors.white,
                                            size: screenWidth * 0.06,
                                          ),
                                          SizedBox(width: screenWidth * 0.02),
                                          Text(
                                            _deviceItem?.ioTData?.waterLevel
                                                    .toString() ??
                                                '',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: screenWidth * 0.055,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: screenHeight * 0.03,
                                ), // Thay vì 10
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.06, // Thay vì 110
                                    right: screenWidth * 0.06, // Thay vì 110
                                  ),
                                  child: Text(
                                    'Cập nhật lần cuối: ${_deviceItem?.lastUpdatedDate != null ? formatDateTime(_deviceItem!.lastUpdatedDate!) : 'N/A'}',
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04, // Thay vì 15
                              vertical: screenHeight * 0.001, // Thay vì 40
                            ),
                            height:
                                screenHeight *
                                0.29, // Tự động thay đổi theo màn hình
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.green, Colors.greenAccent],
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenHeight * 0.02, // Thay vì 10
                                vertical: screenWidth * 0.06, // Thay vì 110
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info,
                                        color: Colors.white,
                                        size: screenWidth * 0.04,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Expanded(
                                        // Giúp Row con chiếm hết không gian có sẵn
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Serial',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              _deviceItem?.serial ?? '',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                    color: Color.fromARGB(255, 197, 197, 197),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info,
                                        color: Colors.white,
                                        size: screenWidth * 0.04,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Expanded(
                                        // Giúp Row con chiếm hết không gian có sẵn
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Loại thiết bị',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              _deviceItem?.type ?? '',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                    color: Color.fromARGB(255, 197, 197, 197),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info,
                                        color: Colors.white,
                                        size: screenWidth * 0.04,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Expanded(
                                        // Giúp Row con chiếm hết không gian có sẵn
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Trực tuyến',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              (_deviceItem?.isOnline ?? false)
                                                  ? 'Có'
                                                  : 'Không',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                    color: Color.fromARGB(255, 197, 197, 197),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.eco,
                                        color: Colors.white,
                                        size: screenWidth * 0.04,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Expanded(
                                        // Giúp Row con chiếm hết không gian có sẵn
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Cây đang trồng',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              (_deviceItem
                                                          ?.plantName
                                                          ?.isEmpty ??
                                                      true)
                                                  ? 'Không có'
                                                  : _deviceItem!.plantName,
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                    color: Color.fromARGB(255, 197, 197, 197),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: Colors.white,
                                        size: screenWidth * 0.04,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Expanded(
                                        // Giúp Row con chiếm hết không gian có sẵn
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Bảo hành đến',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              _deviceItem?.warrantyExpiryDate !=
                                                      null
                                                  ? formatDate(
                                                    _deviceItem!
                                                        .warrantyExpiryDate!,
                                                  )
                                                  : 'N/A',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // const Divider(
                                  //   color: Color.fromARGB(255, 197, 197, 197),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04, // Thay vì 15
                              vertical: screenHeight * 0.025,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.45,
                                  height: screenHeight * 0.055,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      _goToChoosePlant();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9F7BFF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Chọn cây trồng',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: screenWidth * 0.45,
                                  height: screenHeight * 0.055,
                                  child: ElevatedButton(
                                    onPressed:
                                        (_deviceItem?.isOnline == true &&
                                                !_isButtonRefreshing)
                                            ? () async {
                                              setState(() {
                                                _isButtonRefreshing = true;
                                              });

                                              final mqttService = MqttService();
                                              mqttService.onRefreshData = (
                                                message,
                                              ) {
                                                refreshData(message);
                                                setState(() {
                                                  _isButtonRefreshing =
                                                      false; // Kết thúc refresh
                                                });
                                              };

                                              mqttService.sendRefreshSignal(
                                                _deviceItem?.deviceItemId
                                                        .toUpperCase() ??
                                                    '',
                                              );
                                            }
                                            : null, // disable nếu offline hoặc đang refresh
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9F7BFF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child:
                                        _isButtonRefreshing
                                            ? SizedBox(
                                              width: screenWidth * 0.05,
                                              height: screenWidth * 0.05,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : Text(
                                              'Cập nhật dữ liệu',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04, // Thay vì 15
                              vertical: screenHeight * 0.001,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Thời gian cập nhật dữ liệu',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                DropdownButton<int>(
                                  value: _deviceItem?.refreshCycleHours ?? 5,
                                  items:
                                      [5, 7, 10].map((int value) {
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text('$value tiếng'),
                                        );
                                      }).toList(),
                                  onChanged: (int? newValue) {
                                    if (newValue != null &&
                                        _deviceItem != null) {
                                      setState(() {
                                        _deviceItem!.setRefreshCycleHours(
                                          newValue,
                                        );
                                      });
                                      selectedOption = newValue;
                                      _updateRefreshCycle();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04, // Thay vì 15
                              vertical: screenHeight * 0.001,
                            ),
                            child: Text(
                              '*Việc chọn cây trồng sẽ giúp chúng tôi đưa ra những cảnh báo chính xác hơn cho từng loại cây bạn trồng.',
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
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

  Future<void> refreshData(String message) async {
    // Sau khi hoàn thành việc xử lý dữ liệu, bật lại nút
    setState(() {
      _isButtonRefreshing = true;
    });
    if (message == '') {
      Fluttertoast.showToast(
        msg: 'Không có dữ liệu mới',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    }
    // parse dữ liệu sang json
    Map<String, dynamic> jsonData = jsonDecode(message);
    // Kiểm tra xem dữ liệu có hợp lệ không
    if (jsonData.isNotEmpty) {
      // Cập nhật dữ liệu vào model
      // _deviceItem?.setIoTData(IoTResModel.fromJson(jsonData));
      // Cập nhật lại giao diện
      setState(() {
        _deviceItem?.ioTData?.ph = (jsonData['ph'] ?? 0).toDouble();
        _deviceItem?.ioTData?.soluteConcentration =
            (jsonData['soluteConcentration'] ?? 0).toDouble();
        _deviceItem?.ioTData?.temperature =
            (jsonData['temperature'] ?? 0).toDouble();
        _deviceItem?.ioTData?.waterLevel = jsonData['waterLevel'] ?? 0;
        _deviceItem?.lastUpdatedDate = DateTime.now(); // Cập nhật thời gian
      });

      // String token = (await getToken()).toString();
      // String refreshToken = (await getRefreshToken()).toString();
      // String deviceId = (await getDeviceId()).toString();

      // if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

      // final response = await http.post(
      //   Uri.parse('${apiUrl}user/me/mobile/devices/${widget.deviceId}'),
      //   headers: <String, String>{
      //     'Content-Type': 'application/json; charset=UTF-8',
      //     'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
      //     'Authorization': 'Bearer $token',
      //   },
      //   body: jsonEncode(jsonData),
      // );

      // String? newAccessToken = response.headers['new-access-token'];
      // if (newAccessToken != null) {
      //   await updateToken(newAccessToken);
      // }

      if (!mounted) return; // Kiểm tra lại widget trước khi setState

      // if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: 'Đã cập nhật dữ liệu',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
      // } else if (response.statusCode == 401) {
      //   if (mounted) {
      //     WidgetsBinding.instance.addPostFrameCallback((_) {
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(
      //           builder: (context) => Logout(controller: widget.controller),
      //         ),
      //       );
      //     });
      //   }
      // } else {
      //   Map<String, dynamic> responseJson = jsonDecode(response.body);
      //   _getDeviceStatus = responseJson['message'];

      //   if (mounted) {
      //     Fluttertoast.showToast(
      //       msg: _getDeviceStatus,
      //       toastLength: Toast.LENGTH_SHORT,
      //       gravity: ToastGravity.BOTTOM,
      //       timeInSecForIosWeb: 1,
      //       textColor: Colors.black,
      //       fontSize: 16.0,
      //     );

      //     WidgetsBinding.instance.addPostFrameCallback((_) {
      //       if (mounted) {
      //         Navigator.pop(context);
      //       }
      //     });
      //   }
      // }
    } else {
      Fluttertoast.showToast(
        msg: 'Không thể cập nhật dữ liệu lên máy chủ',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    }
    // Thực hiện các thao tác khác với message nếu cần.
    debugPrint("Dữ liệu đã được cập nhật: $message");
  }

  void _goToChoosePlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChoosePlant(
              controller: widget.controller,
              deviceId: widget.deviceId,
            ),
      ),
    );

    if (result == true) {
      // Reload lại dữ liệu khi quay về
      _getDeviceDetails();
    }
  }

  Future<void> _getDeviceDetails() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.get(
      Uri.parse('${apiUrl}user/me/mobile/devices/${widget.deviceId}'),
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
      setState(() {
        _isLoading = false;
        _deviceItem?.setIoTData(ioTData); // Cập nhật dữ liệu IoT vào thiết bị
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

  Future<void> _updateRefreshCycle() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.patch(
      Uri.parse('${apiUrl}user/me/devices/${widget.deviceId}/refresh-cycle'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{'refreshCycleHours': selectedOption}),
    );

    String? newAccessToken = response.headers['new-access-token'];
    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }

    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: 'Cập nhật chu kỳ làm mới thành công',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
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

class ChoosePlant extends StatefulWidget {
  const ChoosePlant({
    super.key,
    required this.controller,
    required this.deviceId,
  });
  final PageController controller;
  final String deviceId; // Thay thế bằng ID thiết bị thực tế

  @override
  State<ChoosePlant> createState() => _ChoosePlantState();
}

class _ChoosePlantState extends State<ChoosePlant> {
  List<PlantModel>? _listPlant = [];
  bool _isLoading = true;
  String _getListPlantStatus = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getListPlant();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text("Chọn cây trồng"),
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
                await _getListPlant();
                setState(() {
                  _isLoading = false;
                });
              },
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _listPlant != null
                      ? Column(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04, // Thay vì 15
                              vertical: screenHeight * 0.025,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Danh sách cây trồng',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    _getListPlant();
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _listPlant?.length ?? 0,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_listPlant![index].name),
                                  onTap: () {
                                    // Xử lý khi người dùng chọn cây trồng
                                    _handleChoosePlant(_listPlant![index].id);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      )
                      : const Center(
                        child: Text(
                          'Không có cây trồng nào',
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

  Future<void> _handleChoosePlant(String plantId) async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.put(
      Uri.parse('${apiUrl}device/set-plant'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'plantId': plantId,
        'deviceItemId': widget.deviceId,
      }),
    );

    String? newAccessToken = response.headers['new-access-token'];
    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }

    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: 'Cập nhật cây trồng thành công',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
      Navigator.pop(context, true);
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
      _getListPlantStatus = responseJson['message'];

      if (mounted) {
        Fluttertoast.showToast(
          msg: _getListPlantStatus,
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

  Future<void> _getListPlant() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.get(
      Uri.parse('${apiUrl}plant?pageSize=1000'),
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
      // Fluttertoast.showToast(
      //   msg: 'Cập nhật chu kỳ làm mới thành công',
      //   toastLength: Toast.LENGTH_SHORT,
      //   gravity: ToastGravity.BOTTOM,
      //   timeInSecForIosWeb: 1,
      //   textColor: Colors.black,
      //   fontSize: 16.0,
      // );
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      List<dynamic> dataList = responseJson['response']?['data'] ?? [];
      _listPlant = dataList.map((item) => PlantModel.fromJson(item)).toList();
      setState(() {
        _isLoading = false;
      });
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
      _getListPlantStatus = responseJson['message'];

      if (mounted) {
        Fluttertoast.showToast(
          msg: _getListPlantStatus,
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
