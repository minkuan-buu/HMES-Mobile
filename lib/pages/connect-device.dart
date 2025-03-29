import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hmes/components/components.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/models/wifi.dart';
import 'package:hmes/pages/home.dart';
import 'package:http/http.dart' as http;

class TutorialConnectScreen extends StatefulWidget {
  const TutorialConnectScreen({super.key});

  @override
  State<TutorialConnectScreen> createState() => _TutorialConnectScreenState();
}

class _TutorialConnectScreenState extends State<TutorialConnectScreen> {
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
            // 👈 Thêm phần này
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Căn giữa nội dung
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Image(
                    image: AssetImage('assets/images/connection.png'),
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    '1. Hãy kết nối thiết bị IoT với nguồn điện',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center, // Căn giữa nội dung
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Image(
                    image: AssetImage('assets/images/wifi_tutorial.png'),
                    width: 400,
                    height: 400,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    '2. Kết nối với wifi có tên "HMES-Kit" với mật khẩu là "12345678". Sau đó bấm Tiếp tục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center, // Căn giữa nội dung
                  ),
                ),
                const SizedBox(height: 50),
                Center(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: SizedBox(
                      width: double.infinity, // Nút kéo dài hết chiều ngang
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
  late Timer _timer; // 👈 Thêm Timer

  @override
  void initState() {
    super.initState();
    _getListWifi();

    // 👇 Gọi hàm mỗi 10 giây
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _getListWifi();
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // 👈 Hủy Timer khi màn hình bị đóng
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết nối Wifi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // Biểu tượng nút refresh
            onPressed: () {
              setState(() => _isLoading = true); // Hiện vòng tròn loading
              _getListWifi();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                // 👈 Kéo xuống để làm mới
                onRefresh: _getListWifi,
                child: ListView.builder(
                  itemCount: wifiList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(wifiList[index].getSsid()),
                      trailing: getWiFiIcon(wifiList[index].getRssi()),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => InputWifiPassword(
                                  ssid: wifiList[index].getSsid(),
                                ),
                          ),
                        );
                        // Handle tap event
                      },
                    );
                  },
                ),
              ),
    );
  }

  Future<void> _getListWifi() async {
    final response = await http.get(
      Uri.parse('${kitUrl}scan'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      List<dynamic> data = responseJson['networks'];

      setState(() {
        wifiList = data.map((item) => WifiModel.fromJson(item)).toList();
        _isLoading = false;
      });
    } else {
      print('Failed to load WiFi list');
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
}

class InputWifiPassword extends StatefulWidget {
  final String ssid;
  const InputWifiPassword({super.key, required this.ssid});

  @override
  State<InputWifiPassword> createState() => _InputWifiPasswordState();
}

class _InputWifiPasswordState extends State<InputWifiPassword> {
  late String Password = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập mật khẩu Wifi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${widget.ssid}',
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
                      _connectToWifi(widget.ssid, Password);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9F7BFF),
                    ),
                    child: const Text(
                      'Kết nối',
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
          ],
        ),
      ),
    );
  }

  Future<void> _connectToWifi(String ssid, String password) async {
    final response = await http.post(
      Uri.parse('${kitUrl}connect'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'ssid': ssid, 'password': password}),
    );

    if (response.statusCode == 200) {
      // Kết nối thành công
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomePage.id,
        (route) => false, // Xóa tất cả màn hình trước đó
      );
    } else {
      // Kết nối thất bại
      print('Failed to connect to WiFi');
    }
  }
}
