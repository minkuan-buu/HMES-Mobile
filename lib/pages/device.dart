import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/helper/logout.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/models/device.dart';
import 'package:hmes/models/phase.dart';
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
                                    Expanded(
                                      child: Text(
                                        device.getName(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
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
                                  'Serial: ${device.getSerial()}',
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
  PhaseGetModel? currentPhase;
  int selectedOption = 5; // Default value for the dropdown
  List<phaseResModel>? phaseRes;
  var dropdownItems = [];
  var customOptionValue = '__custom__';
  List<double> soluteConcentration = [0, 0];
  List<double> temperature = [0, 0];
  List<double> ph = [0, 0];
  List<int> waterLevel = [0, 1300];

  phaseResModel? selectedPhase;

  String selectedPhaseId = '';
  bool isSelectedEmpty = false;

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
        title: Text(
          _deviceItem?.deviceItemName == widget.deviceName
              ? widget.deviceName
              : _deviceItem?.deviceItemName ?? 'Thiết bị',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _goToHistory();
            },
          ),
        ],
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
                      ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04, // Thay vì 15
                                vertical: screenHeight * 0.02, // Thay vì 40
                              ),
                              height:
                                  screenHeight *
                                  0.33, // Tự động thay đổi theo màn hình
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              _deviceItem
                                                      ?.ioTData
                                                      ?.soluteConcentration
                                                      ?.toStringAsFixed(1) ??
                                                  '',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.2,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 5),
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
                                        Text(
                                          '${soluteConcentration[0].toStringAsFixed(1)} - ${soluteConcentration[1].toStringAsFixed(1)} ppm',
                                          style: TextStyle(
                                            fontSize:
                                                screenWidth *
                                                0.033, // Nhỏ hơn một chút
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  //SizedBox(height: screenHeight * 0.1), // Thay vì 50
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: screenHeight * 0.02, // Thay vì 10
                                      left: screenWidth * 0.06, // Thay vì 110
                                      right: screenWidth * 0.06, // Thay vì 110
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                SizedBox(
                                                  width: screenWidth * 0.02,
                                                ),
                                                Text(
                                                  _deviceItem
                                                          ?.ioTData
                                                          ?.temperature
                                                          .toStringAsFixed(1) ??
                                                      '',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        screenWidth * 0.055,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '${temperature[0].toStringAsFixed(1)} - ${temperature[1].toStringAsFixed(1)} °C',
                                              style: TextStyle(
                                                fontSize:
                                                    screenWidth *
                                                    0.033, // Nhỏ hơn một chút
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
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
                                                SizedBox(
                                                  width: screenWidth * 0.02,
                                                ),
                                                Text(
                                                  _deviceItem?.ioTData?.ph
                                                          .toStringAsFixed(2) ??
                                                      '',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        screenWidth * 0.055,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'pH: ${ph[0].toStringAsFixed(1)} - ${ph[1].toStringAsFixed(1)}',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.033,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.water_drop,
                                                  color: Colors.white,
                                                  size: screenWidth * 0.06,
                                                ),
                                                SizedBox(
                                                  width: screenWidth * 0.02,
                                                ),
                                                Text(
                                                  _deviceItem
                                                          ?.ioTData
                                                          ?.waterLevel
                                                          .toString() ??
                                                      '',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        screenWidth * 0.055,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '${waterLevel[0]} - ${waterLevel[1]}',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.033,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: screenHeight * 0.026,
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
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
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
                                  0.3, // Tự động thay đổi theo màn hình
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
                                  vertical: screenWidth * 0.05, // Thay vì 110
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
                                              Flexible(
                                                child: Text(
                                                  _deviceItem?.serial ?? '',
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.045,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                              Flexible(
                                                child: Text(
                                                  _deviceItem?.type ?? '',
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.045,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                              Flexible(
                                                child: Text(
                                                  (_deviceItem?.isOnline ??
                                                          false)
                                                      ? 'Có'
                                                      : 'Không',
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.045,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                              Flexible(
                                                child: Text(
                                                  (_deviceItem
                                                              ?.plantName
                                                              ?.isEmpty ??
                                                          true)
                                                      ? 'Không có'
                                                      : _deviceItem!.plantName,
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.045,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                              Flexible(
                                                child: Text(
                                                  _deviceItem?.warrantyExpiryDate !=
                                                          null
                                                      ? formatDate(
                                                        _deviceItem!
                                                            .warrantyExpiryDate!,
                                                      )
                                                      : 'N/A',
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.045,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                              ), // Xoá horizontal nếu muốn full width
                              width:
                                  double
                                      .infinity, // Container chiếm toàn bộ chiều ngang
                              child: SizedBox(
                                height: screenHeight * 0.055,
                                width:
                                    double
                                        .infinity, // Nút chiếm toàn bộ chiều ngang của Container
                                child: ElevatedButton(
                                  onPressed: () async {
                                    _goToChangeName();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9F7BFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Đổi tên thiết bị',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04, // Thay vì 15
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: screenWidth * 0.45,
                                    height: screenHeight * 0.055,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        _goToChoosePlant();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF9F7BFF,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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

                                                final mqttService =
                                                    MqttService();
                                                mqttService.onRefreshData = (
                                                  message,
                                                ) {
                                                  refreshData(message);
                                                };

                                                mqttService.sendRefreshSignal(
                                                  _deviceItem?.deviceItemId
                                                          .toUpperCase() ??
                                                      '',
                                                );
                                              }
                                              : null, // disable nếu offline hoặc đang refresh
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF9F7BFF,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child:
                                          _isButtonRefreshing
                                              ? SizedBox(
                                                width: screenWidth * 0.05,
                                                height: screenWidth * 0.05,
                                                child:
                                                    CircularProgressIndicator(
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
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.01,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Giai đoạn của cây',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value:
                                        isSelectedEmpty
                                            ? null
                                            : selectedPhaseId,
                                    hint: Text("Chọn giai đoạn"),
                                    items:
                                        dropdownItems
                                            .cast<DropdownMenuItem<String>>(),
                                    onChanged: (String? newValue) {
                                      if (newValue == customOptionValue) {
                                        _goToSetPhase(null);
                                        return;
                                      }

                                      final deviceItem = _deviceItem;
                                      final phases = deviceItem?.phases;

                                      if (phases != null &&
                                          phases.any(
                                            (p) =>
                                                p.id == newValue &&
                                                !p.isDefault,
                                          )) {
                                        _goToSetPhase(newValue);
                                        return;
                                      }

                                      if (newValue != null) {
                                        setState(() {
                                          selectedPhaseId = newValue;
                                          _updatePhase();
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04, // Thay vì 15
                                vertical: screenHeight * 0.002,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                            SizedBox(height: screenHeight * 0.04),
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

  Future<void> _getCurrentPhase() async {
    if (_deviceItem?.phases == null ||
        !_deviceItem!.phases!.any((phase) => phase.isSelected)) {
      setState(() {
        soluteConcentration = [0.0, 0.0];
        temperature = [0.0, 0.0];
        ph = [0.0, 0.0];
        waterLevel = [0, 0];
      });
      return;
    } // Không cần gọi API nếu không có phaseId
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.get(
      Uri.parse(
        '${apiUrl}target-value/${_deviceItem!.plantId}/${_deviceItem!.phases!.firstWhere((phase) => phase.isSelected).id}',
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
    );

    String? newAccessToken = response.headers['new-access-token'];
    if (newAccessToken != null) {
      updateToken(newAccessToken);
    }

    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      Map<String, dynamic> data = responseJson['response']?['data'] ?? {};
      setState(() {
        currentPhase = PhaseGetModel.fromJson(data);
        _isLoading = false;
      });

      if (currentPhase?.target != null) {
        for (var entry in currentPhase!.target!) {
          switch (entry.type) {
            case 'SoluteConcentration':
              soluteConcentration = [entry.minValue, entry.maxValue];
              break;

            case 'Temperature':
              temperature = [entry.minValue, entry.maxValue];
              break;

            case 'Ph':
              ph = [entry.minValue, entry.maxValue];
              break;

            case 'WaterLevel':
              waterLevel = [entry.minValue.toInt(), entry.maxValue.toInt()];
              break;
          }
        }
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
      String statusMessage = responseJson['message'] ?? 'Đã xảy ra lỗi';
      Fluttertoast.showToast(
        msg: statusMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    }
  }

  void _goToSetPhase(String? newValue) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditPhasePage(
              phaseId: newValue,
              plantId: _deviceItem!.plantId,
              deviceItemId: _deviceItem!.deviceItemId,
              controller: widget.controller,
            ),
      ),
    );

    if (result == true) {
      // Reload lại dữ liệu khi quay về
      _getDeviceDetails();
    }
  }

  void _goToHistory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => History(
              controller: widget.controller,
              deviceId: widget.deviceId,
              deviceName: _deviceItem?.deviceItemName ?? 'Thiết bị',
            ),
      ),
    );

    if (result == true) {
      // Reload lại dữ liệu khi quay về
      _getDeviceDetails();
    }
  }

  Future<void> refreshData(String message) async {
    // Return early if message is empty (timeout case)
    if (message.isEmpty) {
      setState(() {
        _isButtonRefreshing = false;
      });
      Fluttertoast.showToast(
        msg: 'Không có dữ liệu mới',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
      return;
    }

    try {
      // Parse data to json
      Map<String, dynamic> jsonData = jsonDecode(message);

      // Check if this is a notification or refresh data
      // Refresh data should contain IoT data fields
      if (jsonData.containsKey('ph') ||
          jsonData.containsKey('soluteConcentration') ||
          jsonData.containsKey('temperature') ||
          jsonData.containsKey('waterLevel')) {
        // Update the device's IoT data with proper type conversion
        setState(() {
          // Ensure values are converted to double
          _deviceItem?.ioTData?.ph =
              jsonData['ph'] != null
                  ? double.parse(jsonData['ph'].toString())
                  : _deviceItem?.ioTData?.ph ?? 0.0;

          _deviceItem?.ioTData?.soluteConcentration =
              jsonData['soluteConcentration'] != null
                  ? double.parse(jsonData['soluteConcentration'].toString())
                  : _deviceItem?.ioTData?.soluteConcentration ?? 0.0;

          _deviceItem?.ioTData?.temperature =
              jsonData['temperature'] != null
                  ? double.parse(jsonData['temperature'].toString())
                  : _deviceItem?.ioTData?.temperature ?? 0.0;

          _deviceItem?.ioTData?.waterLevel =
              jsonData['waterLevel'] != null
                  ? int.parse(jsonData['waterLevel'].toString())
                  : _deviceItem?.ioTData?.waterLevel ?? 0;

          // Update last updated date
          _deviceItem?.lastUpdatedDate = DateTime.now();
        });

        // Send the new data to the server
        await _sendIoTDataToServer(jsonData);
      } else {
        // This is likely a notification, not a refresh response - ignore for refresh purposes
        debugPrint(
          "Received notification during refresh, ignoring for refresh purposes",
        );
      }
    } catch (e) {
      debugPrint("Error processing refresh data: $e");
      Fluttertoast.showToast(
        msg: 'Không thể xử lý dữ liệu: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    } finally {
      // Reset the button state after processing
      setState(() {
        _isButtonRefreshing = false;
      });
    }
  }

  // New method to send IoT data to server
  Future<void> _sendIoTDataToServer(Map<String, dynamic> jsonData) async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return;

    try {
      final response = await http.post(
        Uri.parse('${apiUrl}user/me/mobile/devices/${widget.deviceId}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(jsonData),
      );

      String? newAccessToken = response.headers['new-access-token'];
      if (newAccessToken != null) {
        await updateToken(newAccessToken);
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: 'Đã cập nhật dữ liệu',
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
        String getDeviceStatus = responseJson['message'];

        if (mounted) {
          Fluttertoast.showToast(
            msg: getDeviceStatus,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            textColor: Colors.black,
            fontSize: 16.0,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Không thể cập nhật dữ liệu lên máy chủ',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: Colors.black,
          fontSize: 16.0,
        );
      }
      debugPrint("Error sending IoT data to server: $e");
    }
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

  void _goToChangeName() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChangeDeviceName(
              controller: widget.controller,
              deviceId: widget.deviceId,
              deviceName: _deviceItem?.deviceItemName ?? 'Thiết bị',
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
      phaseRes =
          (data['phase'] as List<dynamic>? ?? [])
              .map((item) => phaseResModel.fromJson(item))
              .toList();

      final bool hasCustomPhase = (phaseRes ?? []).any(
        (e) => e.getIsDefault() == false,
      );

      selectedPhase = phaseRes?.firstWhere(
        (e) => e.getIsSelected(),
        orElse:
            () => phaseResModel(
              id: '',
              phaseName: '',
              isDefault: false,
              isSelected: false,
            ),
      );

      selectedPhaseId = selectedPhase?.getId() ?? '';
      isSelectedEmpty = selectedPhaseId.isEmpty;

      dropdownItems = [
        ...(phaseRes ?? []).map((phase) {
          return DropdownMenuItem<String>(
            value: phase.getId(),
            child: Text(phase.getPhaseName() ?? 'Tùy chỉnh'),
          );
        }),
        if (!hasCustomPhase)
          DropdownMenuItem<String>(
            value: customOptionValue,
            child: Text("Tùy chỉnh"),
          ),
      ];

      setState(() {
        _isLoading = false;
        _deviceItem?.setIoTData(ioTData); // Cập nhật dữ liệu IoT vào thiết bị
        _deviceItem?.setPhases(phaseRes ?? []);
      });
      await _getCurrentPhase(); // Lấy giai đoạn hiện tại
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

  Future<void> _updatePhase() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.put(
      Uri.parse('${apiUrl}device/set-phase'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'deviceItemId': widget.deviceId,
        'phaseId': selectedPhaseId,
      }),
    );

    String? newAccessToken = response.headers['new-access-token'];
    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }

    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: 'Cập nhật giai đoạn thành công',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
      setState(() {
        _isLoading = true;
        _getDeviceDetails();
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

class History extends StatefulWidget {
  const History({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.controller,
  });
  final String deviceId; // Thay thế bằng ID thiết bị thực tế
  final String deviceName; // Thay thế bằng tên thiết bị thực tế
  final PageController controller;

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  bool _isLoading = true;
  HistoryLogModel? _historyLogModel;
  String _getHistoryStatus = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getHistoryLog();
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm, dd/MM/yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.widget.deviceName),
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
                setState(() => _isLoading = true);
                // await _getListWifi();
                setState(() => _isLoading = false);
              },
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _historyLogModel != null
                      ? Column(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Lịch sử giám sát',
                                  style: TextStyle(
                                    fontSize: 20,
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
                                    _getHistoryLog();
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _historyLogModel?.ioTData?.length ?? 0,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(
                                    '${_historyLogModel?.ioTData?[index].createdAt != null ? formatDateTime(_historyLogModel!.ioTData![index].createdAt!) : 'N/A'}',
                                  ),
                                  subtitle: Text(
                                    'Nồng độ dinh dưỡng: ${_historyLogModel?.ioTData?[index].soluteConcentration}ppm',
                                  ),
                                  trailing: Text(
                                    'Nhiệt độ: ${_historyLogModel?.ioTData?[index].temperature} °C',
                                  ),
                                  onTap: () {
                                    // Xử lý khi người dùng chọn lịch sử
                                    // Có thể mở một trang chi tiết hoặc hiển thị thông tin thêm
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text('Thông tin chi tiết'),
                                            content: Text(
                                              'Nồng độ dinh dưỡng: ${_historyLogModel?.ioTData?[index].soluteConcentration}ppm\n'
                                              'Nhiệt độ: ${_historyLogModel?.ioTData?[index].temperature} °C\n'
                                              'pH: ${_historyLogModel?.ioTData?[index].ph}\n'
                                              'Mực nước: ${_historyLogModel?.ioTData?[index].waterLevel}',
                                            ),
                                            actions: [
                                              TextButton(
                                                child: const Text('Đóng'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      )
                      : const Center(
                        child: Text(
                          'Không có lịch sử nào',
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

  Future<void> _getHistoryLog() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.get(
      Uri.parse('${apiUrl}user/me/devices/${widget.deviceId}/history-log'),
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
      _historyLogModel = HistoryLogModel.fromJson(data);
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
      _getHistoryStatus = responseJson['message'];

      if (mounted) {
        Fluttertoast.showToast(
          msg: _getHistoryStatus,
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

class ChangeDeviceName extends StatefulWidget {
  const ChangeDeviceName({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.controller,
  });
  final String deviceId; // Thay thế bằng ID thiết bị thực tế
  final String deviceName; // Thay thế bằng tên thiết bị thực tế
  final PageController controller;

  @override
  State<ChangeDeviceName> createState() => _ChangeDeviceNameState();
}

class _ChangeDeviceNameState extends State<ChangeDeviceName> {
  String _newName = '';
  String _changeNameStatus = '';
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi tên thiết bị'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04, // Thay vì 15
          vertical: screenHeight * 0.025,
        ),
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: const Color(0xFF9F7BFF)),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: TextEditingController(text: widget.deviceName),
                  onChanged: (value) => _newName = value,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    label: Text('Tên thiết bị'),
                    hintText: 'Nhập tên thiết bị',
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Xử lý đổi tên thiết bị
                if (_newName.isNotEmpty) {
                  _updateDeviceName();
                } else {
                  Fluttertoast.showToast(
                    msg: 'Vui lòng nhập tên thiết bị',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    textColor: Colors.black,
                    fontSize: 16.0,
                  );
                }
              },
              child: Text('Đổi tên'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateDeviceName() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.put(
      Uri.parse('${apiUrl}user/me/mobile/devices/${widget.deviceId}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{'deviceItemName': _newName}),
    );

    String? newAccessToken = response.headers['new-access-token'];
    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }

    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: 'Cập nhật tên thiết bị thành công',
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
      _changeNameStatus = responseJson['message'];
      switch (_changeNameStatus) {
        case 'Device item not found':
          _changeNameStatus = 'Thiết bị không tồn tại';
          break;
        default:
          _changeNameStatus = 'Đã xảy ra lỗi';
      }
      if (mounted) {
        Fluttertoast.showToast(
          msg: _changeNameStatus,
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

class EditPhasePage extends StatefulWidget {
  const EditPhasePage({
    super.key,
    this.phaseId,
    required this.deviceItemId,
    required this.controller,
    required this.plantId,
  });
  final PageController controller;
  final String deviceItemId;
  final String plantId;
  final String? phaseId;

  @override
  State<EditPhasePage> createState() => _EditPhasePageState();
}

class _EditPhasePageState extends State<EditPhasePage> {
  final ScrollController _scrollController = ScrollController();
  String? _errorLowSoluteConcentrationText;
  String? _errorHighSoluteConcentrationText;
  String? _errorLowTemperatureText;
  String? _errorHighTemperatureText;
  String? _errorLowPhText;
  String? _errorHighPhText;
  String? _errorLowWaterLevelText;
  String? _errorHighWaterLevelText;
  bool _isCreatingPhase = false;
  bool _isLoading = true;
  PhaseModel? newPhase;
  PhaseGetModel? currentPhase;
  List<double> soluteConcentration = [0, 0];
  List<double> temperature = [0, 0];
  List<double> ph = [0, 0];
  List<int> waterLevel = [0, 1300];

  // FocusNodes
  final FocusNode _phaseNameFocus = FocusNode();
  final FocusNode _soluteLowFocus = FocusNode();
  final FocusNode _soluteHighFocus = FocusNode();
  final FocusNode _tempLowFocus = FocusNode();
  final FocusNode _tempHighFocus = FocusNode();
  final FocusNode _phLowFocus = FocusNode();
  final FocusNode _phHighFocus = FocusNode();
  final FocusNode _waterLowFocus = FocusNode();
  final FocusNode _waterHighFocus = FocusNode();

  final _waterLowController = TextEditingController();
  final _waterHighController = TextEditingController();
  final _soluteLowController = TextEditingController();
  final _soluteHighController = TextEditingController();
  final _tempLowController = TextEditingController();
  final _tempHighController = TextEditingController();
  final _phLowController = TextEditingController();
  final _phHighController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Gán giá trị ban đầu cho controller
    _waterLowController.text = waterLevel[0].toString();
    _waterHighController.text = waterLevel[1].toString();
    _soluteLowController.text = soluteConcentration[0].toString();
    _soluteHighController.text = soluteConcentration[1].toString();
    _tempLowController.text = temperature[0].toString();
    _tempHighController.text = temperature[1].toString();
    _phLowController.text = ph[0].toString();
    _phHighController.text = ph[1].toString();

    _phaseNameFocus.addListener(() => _scrollToFocused(_phaseNameFocus));
    _soluteLowFocus.addListener(() => _scrollToFocused(_soluteLowFocus));
    _soluteHighFocus.addListener(() => _scrollToFocused(_soluteHighFocus));
    _tempLowFocus.addListener(() => _scrollToFocused(_tempLowFocus));
    _tempHighFocus.addListener(() => _scrollToFocused(_tempHighFocus));
    _phLowFocus.addListener(() => _scrollToFocused(_phLowFocus));
    _phHighFocus.addListener(() => _scrollToFocused(_phHighFocus));
    _waterLowFocus.addListener(() => _scrollToFocused(_waterLowFocus));
    _waterHighFocus.addListener(() => _scrollToFocused(_waterHighFocus));

    _getCurrentPhase(); // nếu có load dữ liệu ban đầu
  }

  @override
  void dispose() {
    _waterLowController.dispose();
    _waterHighController.dispose();
    _soluteLowController.dispose();
    _soluteHighController.dispose();
    _tempLowController.dispose();
    _tempHighController.dispose();
    _phLowController.dispose();
    _phHighController.dispose();
    _phaseNameFocus.dispose();
    _soluteLowFocus.dispose();
    _soluteHighFocus.dispose();
    _tempLowFocus.dispose();
    _tempHighFocus.dispose();
    _phLowFocus.dispose();
    _phHighFocus.dispose();
    _waterLowFocus.dispose();
    _waterHighFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToFocused(FocusNode node) {
    if (node.hasFocus) {
      Future.delayed(Duration(milliseconds: 300), () {
        Scrollable.ensureVisible(
          node.context!,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final viewInsets = MediaQuery.of(context).viewInsets;

    Widget buildInput({
      required String label,
      required String hint,
      required TextEditingController controller,
      required Function(String) onChanged,
      required FocusNode focusNode,
      required TextInputType keyboardType,
      bool enabled = true,
      String? errorText,
    }) {
      return Container(
        height: 56,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: const Color(0xFF9F7BFF)),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              labelText: label,
              hintText: hint,
              errorText: errorText,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Tùy chỉnh'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Xử lý lưu giai đoạn
              if (widget.phaseId == null) {
                if (soluteConcentration[0] < soluteConcentration[1] &&
                    temperature[0] < temperature[1] &&
                    ph[0] < ph[1] &&
                    waterLevel[0] < waterLevel[1]) {
                  // Gọi API để lưu giai đoạn mới
                  _createPhase();
                }
                //_updatePhase();
              } else if (widget.phaseId != null) {
                if (soluteConcentration[0] < soluteConcentration[1] &&
                    temperature[0] < temperature[1] &&
                    ph[0] < ph[1] &&
                    waterLevel[0] < waterLevel[1]) {
                  // Gọi API để cập nhật giai đoạn hiện tại
                  _updatePhase();
                }
                //_updatePhase();
              } else {
                Fluttertoast.showToast(
                  msg: 'Vui lòng nhập giá trị hợp lệ',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  textColor: Colors.black,
                  fontSize: 16.0,
                );
              }
            },
            child: const Text(
              'Lưu',
              style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.04,
                        right: screenWidth * 0.04,
                        top: 16,
                        bottom:
                            viewInsets.bottom +
                            5, // 👈 Thêm padding dưới theo bàn phím
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              const Text(
                                "Nồng độ chất dinh dưỡng (ppm)",
                                style: TextStyle(fontSize: 16),
                              ),
                              buildInput(
                                label: 'Giá trị thấp nhất',
                                hint: 'Nhập giá trị thấp nhất',
                                controller: _soluteLowController,
                                focusNode: _soluteLowFocus,
                                keyboardType: TextInputType.number,
                                errorText: _errorLowSoluteConcentrationText,
                                onChanged: (value) {
                                  final parsed = double.tryParse(value);
                                  if (parsed == null || parsed < 0) {
                                    setState(
                                      () =>
                                          _errorLowSoluteConcentrationText =
                                              'Giá trị tối thiểu là 0',
                                    );
                                  } else if (parsed >= soluteConcentration[1]) {
                                    setState(() {
                                      _errorLowSoluteConcentrationText =
                                          'Giá trị thấp nhất phải nhỏ hơn giá trị cao nhất';
                                    });
                                  } else {
                                    setState(() {
                                      _errorLowSoluteConcentrationText = null;
                                      soluteConcentration[0] = parsed;
                                    });
                                  }
                                },
                              ),
                              buildInput(
                                label: 'Giá trị cao nhất',
                                hint: 'Nhập giá trị cao nhất',
                                controller: _soluteHighController,
                                focusNode: _soluteHighFocus,
                                keyboardType: TextInputType.number,
                                errorText: _errorHighSoluteConcentrationText,
                                onChanged: (value) {
                                  final parsed = double.tryParse(value);
                                  if (parsed == null || parsed < 0) {
                                    setState(
                                      () =>
                                          _errorHighSoluteConcentrationText =
                                              'Giá trị tối thiểu là 0',
                                    );
                                  } else if (parsed <= soluteConcentration[0]) {
                                    setState(() {
                                      _errorHighSoluteConcentrationText =
                                          'Giá trị cao nhất phải lớn hơn giá trị thấp nhất';
                                    });
                                  } else {
                                    setState(() {
                                      _errorHighSoluteConcentrationText = null;
                                      soluteConcentration[1] = parsed;
                                    });
                                  }
                                },
                              ),
                              const Text(
                                "Nhiệt độ (°C)",
                                style: TextStyle(fontSize: 16),
                              ),
                              buildInput(
                                label: 'Giá trị thấp nhất',
                                hint: 'Nhập giá trị thấp nhất',
                                controller: _tempLowController,
                                focusNode: _tempLowFocus,
                                keyboardType: TextInputType.number,
                                errorText: _errorLowTemperatureText,
                                onChanged: (value) {
                                  final parsed = double.tryParse(value);
                                  if (parsed == null || parsed < 0) {
                                    setState(
                                      () =>
                                          _errorLowTemperatureText =
                                              'Giá trị tối thiểu là 0',
                                    );
                                  } else if (parsed >= temperature[1]) {
                                    setState(() {
                                      _errorLowTemperatureText =
                                          'Giá trị thấp nhất phải nhỏ hơn giá trị cao nhất';
                                    });
                                  } else {
                                    setState(() {
                                      _errorLowTemperatureText = null;
                                      temperature[0] = parsed;
                                    });
                                  }
                                },
                              ),
                              buildInput(
                                label: 'Giá trị cao nhất',
                                hint: 'Nhập giá trị cao nhất',
                                controller: _tempHighController,
                                focusNode: _tempHighFocus,
                                keyboardType: TextInputType.number,
                                errorText: _errorHighTemperatureText,
                                onChanged: (value) {
                                  final parsed = double.tryParse(value);
                                  if (parsed == null || parsed < 0) {
                                    setState(
                                      () =>
                                          _errorHighTemperatureText =
                                              'Giá trị tối thiểu là 0',
                                    );
                                  } else if (parsed <= temperature[0]) {
                                    setState(() {
                                      _errorHighTemperatureText =
                                          'Giá trị cao nhất phải lớn hơn giá trị thấp nhất';
                                    });
                                  } else {
                                    setState(() {
                                      _errorHighTemperatureText = null;
                                      temperature[1] = parsed;
                                    });
                                  }
                                },
                              ),
                              const Text(
                                "Nồng độ pH",
                                style: TextStyle(fontSize: 16),
                              ),
                              buildInput(
                                label: 'Giá trị thấp nhất',
                                hint: 'Nhập giá trị thấp nhất',
                                controller: _phLowController,
                                focusNode: _phLowFocus,
                                keyboardType: TextInputType.number,
                                errorText: _errorLowPhText,
                                onChanged: (value) {
                                  final parsed = double.tryParse(value);
                                  if (parsed == null || parsed < 0) {
                                    setState(
                                      () =>
                                          _errorLowPhText =
                                              'Giá trị tối thiểu là 0',
                                    );
                                  } else if (parsed >= ph[1]) {
                                    setState(() {
                                      _errorLowPhText =
                                          'Giá trị thấp nhất phải nhỏ hơn giá trị cao nhất';
                                    });
                                  } else {
                                    setState(() {
                                      _errorLowPhText = null;
                                      ph[0] = parsed;
                                    });
                                  }
                                },
                              ),
                              buildInput(
                                label: 'Giá trị cao nhất',
                                hint: 'Nhập giá trị cao nhất',
                                controller: _phHighController,
                                focusNode: _phHighFocus,
                                keyboardType: TextInputType.number,
                                errorText: _errorHighPhText,
                                onChanged: (value) {
                                  final parsed = double.tryParse(value);
                                  if (parsed == null || parsed < 0) {
                                    setState(
                                      () =>
                                          _errorHighPhText =
                                              'Giá trị tối thiểu là 0',
                                    );
                                  } else if (parsed <= ph[0]) {
                                    setState(() {
                                      _errorHighPhText =
                                          'Giá trị cao nhất phải lớn hơn giá trị thấp nhất';
                                    });
                                  } else {
                                    setState(() {
                                      _errorHighPhText = null;
                                      ph[1] = parsed;
                                    });
                                  }
                                },
                              ),
                              const Text(
                                "Mức nước",
                                style: TextStyle(fontSize: 16),
                              ),
                              buildInput(
                                label: 'Giá trị thấp nhất',
                                hint: 'Nhập giá trị thấp nhất',
                                controller: _waterLowController,
                                focusNode: _waterLowFocus,
                                keyboardType: TextInputType.number,
                                errorText: _errorLowWaterLevelText,
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed == null || parsed < 0) {
                                    setState(
                                      () =>
                                          _errorLowWaterLevelText =
                                              'Giá trị tối thiểu là 0',
                                    );
                                  } else {
                                    setState(() {
                                      _errorLowWaterLevelText = null;
                                      waterLevel[0] = parsed;
                                    });
                                  }
                                },
                              ),
                              buildInput(
                                label: 'Giá trị cao nhất',
                                hint: 'Nhập giá trị cao nhất',
                                controller: _waterHighController,
                                focusNode: _waterHighFocus,
                                keyboardType: TextInputType.number,
                                errorText: _errorHighWaterLevelText,
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed == null || parsed > 1300) {
                                    setState(
                                      () =>
                                          _errorHighWaterLevelText =
                                              'Giá trị tối đa là 1300',
                                    );
                                  } else {
                                    setState(() {
                                      _errorHighWaterLevelText = null;
                                      waterLevel[1] = parsed;
                                    });
                                  }
                                },
                              ),
                              const Text(
                                "*Giá trị mức nước tối đa là 1300",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Future<void> _getCurrentPhase() async {
    if (widget.phaseId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    } // Không cần gọi API nếu không có phaseId
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.get(
      Uri.parse('${apiUrl}target-value/${widget.plantId}/${widget.phaseId}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
    );

    String? newAccessToken = response.headers['new-access-token'];
    if (newAccessToken != null) {
      updateToken(newAccessToken);
    }

    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      Map<String, dynamic> data = responseJson['response']?['data'] ?? {};
      setState(() {
        currentPhase = PhaseGetModel.fromJson(data);
        _isLoading = false;
      });

      if (currentPhase?.target != null) {
        for (var entry in currentPhase!.target!) {
          switch (entry.type) {
            case 'SoluteConcentration':
              soluteConcentration = [entry.minValue, entry.maxValue];
              _soluteLowController.text = entry.minValue.toString();
              _soluteHighController.text = entry.maxValue.toString();
              break;

            case 'Temperature':
              temperature = [entry.minValue, entry.maxValue];
              _tempLowController.text = entry.minValue.toString();
              _tempHighController.text = entry.maxValue.toString();
              break;

            case 'Ph':
              ph = [entry.minValue, entry.maxValue];
              _phLowController.text = entry.minValue.toString();
              _phHighController.text = entry.maxValue.toString();
              break;

            case 'WaterLevel':
              waterLevel = [entry.minValue.toInt(), entry.maxValue.toInt()];
              _waterLowController.text = entry.minValue.toInt().toString();
              _waterHighController.text = entry.maxValue.toInt().toString();
              break;
          }
        }
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
      String statusMessage = responseJson['message'] ?? 'Đã xảy ra lỗi';
      Fluttertoast.showToast(
        msg: statusMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _createPhase() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.post(
      Uri.parse('${apiUrl}device/init-custom-phase'),
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
      Fluttertoast.showToast(
        msg: 'Tạo giai đoạn thành công',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      Map<String, dynamic> data = responseJson['response']?['data'] ?? {};
      setState(() {
        newPhase = PhaseModel.fromJson(data);
      });
      _setPhaseToPlant();
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
      String statusMessage = responseJson['message'] ?? 'Đã xảy ra lỗi';
      Fluttertoast.showToast(
        msg: statusMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _setPhaseToDevice() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();
    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa
    final response = await http.put(
      Uri.parse('${apiUrl}device/set-phase'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'deviceItemId': widget.deviceItemId,
        'phaseId': newPhase?.id ?? widget.phaseId,
      }),
    );
    String? newAccessToken = response.headers['new-access-token'];
    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }
    if (!mounted) return; // Kiểm tra lại widget trước khi setState
    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: 'Cập nhật giai đoạn thành công',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
      setState(() {
        _isCreatingPhase = false;
      });
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
      setState(() {
        _isCreatingPhase = false;
      });
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      String statusMessage = responseJson['message'] ?? 'Đã xảy ra lỗi';
      Fluttertoast.showToast(
        msg: statusMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );

      setState(() {
        _isCreatingPhase = false;
      });
    }
  }

  Future<void> _setPhaseToPlant() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa
    final response = await http.post(
      Uri.parse(
        '${apiUrl}device/${widget.plantId}/phase/${newPhase?.id ?? widget.phaseId}',
      ),
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
      _setValue();
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
      setState(() {
        _isCreatingPhase = false;
      });
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      String statusMessage = responseJson['message'] ?? 'Đã xảy ra lỗi';
      Fluttertoast.showToast(
        msg: statusMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );

      setState(() {
        _isCreatingPhase = false;
      });
    }
  }

  Future<void> _setValue() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.post(
      Uri.parse('${apiUrl}device/set-value'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'deviceItemId': widget.deviceItemId,
        'phaseId': newPhase?.id ?? widget.phaseId,
        'values': [
          {
            'type': 'soluteConcentration',
            'minValue': soluteConcentration[0],
            'maxValue': soluteConcentration[1],
          },
          {
            'type': 'temperature',
            'minValue': temperature[0],
            'maxValue': temperature[1],
          },
          {'type': 'ph', 'minValue': ph[0], 'maxValue': ph[1]},
          {
            'type': 'waterLevel',
            'minValue': waterLevel[0],
            'maxValue': waterLevel[1],
          },
        ],
      }),
    );

    String? newAccessToken = response.headers['new-access-token'];
    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }
    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      _setPhaseToDevice();
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
      setState(() {
        _isCreatingPhase = false;
      });
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      String statusMessage = responseJson['message'] ?? 'Đã xảy ra lỗi';
      Fluttertoast.showToast(
        msg: statusMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );

      setState(() {
        _isCreatingPhase = false;
      });
    }
  }

  Future<void> _updatePhase() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa

    final response = await http.put(
      Uri.parse('${apiUrl}device/update-value/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'deviceItemId': widget.deviceItemId,
        'phaseId': newPhase?.id ?? widget.phaseId,
        'values': [
          {
            'type': 'soluteConcentration',
            'minValue': soluteConcentration[0],
            'maxValue': soluteConcentration[1],
          },
          {
            'type': 'temperature',
            'minValue': temperature[0],
            'maxValue': temperature[1],
          },
          {'type': 'ph', 'minValue': ph[0], 'maxValue': ph[1]},
          {
            'type': 'waterLevel',
            'minValue': waterLevel[0],
            'maxValue': waterLevel[1],
          },
        ],
      }),
    );

    String? newAccessToken = response.headers['new-access-token'];
    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }

    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      _setPhaseToDevice();
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
      String statusMessage = responseJson['message'] ?? 'Đã xảy ra lỗi';
      Fluttertoast.showToast(
        msg: statusMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
      setState(() {
        _isCreatingPhase = false;
      });
    }
  }
}
