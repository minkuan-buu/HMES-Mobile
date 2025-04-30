import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/models/wifi.dart';
import 'package:hmes/pages/home.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class TutorialConnectScreen extends StatefulWidget {
  const TutorialConnectScreen({super.key});

  @override
  State<TutorialConnectScreen> createState() => _TutorialConnectScreenState();
}

class _TutorialConnectScreenState extends State<TutorialConnectScreen> {
  bool _isLoading = true; // Thêm trạng thái tải

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Hướng dẫn kết nối',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Image(
                    image: const AssetImage('assets/images/connection.png'),
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    '1. Hãy kết nối thiết bị IoT với nguồn điện',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Image(
                    image: const AssetImage('assets/images/wifi_tutorial.png'),
                    width: 400,
                    height: 400,
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    '2. Kết nối với wifi có tên "HMES-Kit" với mật khẩu là "12345678". Sau đó bấm Tiếp tục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 50),
                Center(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WifiConnection(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9F7BFF),
                        ),
                        child: const Text(
                          'Tiếp tục',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WifiConnection extends StatefulWidget {
  const WifiConnection({super.key});

  @override
  State<WifiConnection> createState() => _WifiConnectionState();
}

class _WifiConnectionState extends State<WifiConnection> {
  List<WifiModel> wifiList = [];
  bool _isLoading = true;
  bool _allowGetWifiList = false;
  late Timer _timer;
  final info = NetworkInfo();
  String? _currentSSID; // Thêm biến để lưu SSID hiện tại

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_allowGetWifiList) {
        _getListWifi();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await _requestPermission();
    await _getWifiSSID();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _requestPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cần quyền vị trí để lấy thông tin WiFi.'),
          ),
        );
      }
    }
  }

  Future<void> _getWifiSSID() async {
    try {
      _currentSSID = await info.getWifiName();
      if (_currentSSID != null) {
        _currentSSID = _currentSSID!.substring(1, _currentSSID!.length - 1);
      }
      _allowGetWifiList = _currentSSID == "HMES-Kit";
      if (_allowGetWifiList) {
        _getListWifi();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng kết nối với wifi HMES-Kit')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error getting SSID: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể lấy SSID.')));
      }
    }
  }

  Future<void> _getListWifi() async {
    try {
      final response = await http.get(Uri.parse('${kitUrl}scan'));
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);
        List<dynamic> data = responseJson['networks'];
        setState(() {
          wifiList = data.map((item) => WifiModel.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải danh sách WiFi.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load WiFi list: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi tải danh sách WiFi.')),
        );
      }
    }
  }

  int getSignalStrength(int rssi) {
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }

  Icon getWiFiIcon(int rssi) {
    int level = getSignalStrength(rssi);
    switch (level) {
      case 4:
      case 3:
        return const Icon(Icons.wifi, color: Colors.green);
      case 2:
        return const Icon(Icons.wifi_2_bar, color: Colors.orange);
      case 1:
        return const Icon(Icons.wifi_1_bar, color: Colors.red);
      default:
        return const Icon(Icons.wifi_off, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết nối Wifi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _getListWifi();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _allowGetWifiList
              ? RefreshIndicator(
                onRefresh: _getListWifi,
                child: ListView.builder(
                  itemCount: wifiList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(wifiList[index].getSsid()),
                      trailing: getWiFiIcon(wifiList[index].getRssi()),
                      onTap: () {
                        _timer.cancel();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => InputWifiPassword(
                                  ssid: wifiList[index].getSsid(),
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
              : const Center(
                child: Text(
                  'Vui lòng kết nối với wifi HMES-Kit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
    );
  }
}

class InputWifiPassword extends StatefulWidget {
  final String ssid;
  const InputWifiPassword({super.key, required this.ssid});

  @override
  State<InputWifiPassword> createState() => _InputWifiPasswordState();
}

class _InputWifiPasswordState extends State<InputWifiPassword> {
  late String Password = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập mật khẩu Wifi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              widget.ssid,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Mật khẩu Wifi',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (value) {
                setState(() {
                  Password = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: SizedBox(
                  width: double.infinity, // Nút kéo dài hết chiều ngang
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => WifiConnection(),
                      //   ),
                      // );
                      setState(() {
                        _isLoading = true;
                      });
                      _connectToWifi(widget.ssid, Password);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9F7BFF),
                    ),
                    child:
                        !_isLoading
                            ? Text(
                              'Kết nối',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                            : SizedBox(
                              width: screenWidth * 0.05,
                              height: screenWidth * 0.05,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectToWifi(String ssid, String password) async {
    String token = (await getToken()).toString();
    String refreshToken = Uri.encodeComponent(
      await getRefreshToken() ?? '',
    ); // 🔹 Decode trước khi gửi
    String deviceId = (await getDeviceId()).toString();

    final response = await http.post(
      Uri.parse('${kitUrl}connect'),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body:
          'ssid=$ssid&password=$password&token=$token&deviceId=$deviceId&refreshToken=$refreshToken',
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      Map<String, dynamic>? dataMap = responseJson['response']?['data'];
      if (dataMap != null) {
        Map<String, dynamic> token = dataMap;
        // Sử dụng token
        await updateToken(jsonEncode(token));
      } else {
        // Xử lý trường hợp map null.
        print('Data map is null');
      }
      setState(() {
        _isLoading = false; // Đặt lại trạng thái tải
      });
      // ✅ Kết nối thành công
      Navigator.pushNamedAndRemoveUntil(context, HomePage.id, (route) => false);
    } else {
      // ❌ Kết nối thất bại
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Lỗi kết nối'),
              content: const Text(
                'Không thể kết nối đến WiFi. Hãy kiểm tra lại mật khẩu và thử lại.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Đóng dialog
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      setState(() {
        _isLoading = false; // Đặt lại trạng thái tải
      });
    }
  }
}
