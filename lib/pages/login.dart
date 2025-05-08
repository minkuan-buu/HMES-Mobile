import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hmes/components/components.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/helper/sharedPreferencesHelper.dart';
import 'package:hmes/pages/home.dart';
import 'package:hmes/pages/reset-password.dart';
import 'package:hmes/services/foreground_service.dart';
import 'package:hmes/services/mqtt-service.dart';
import 'package:http/http.dart' as http;
import 'package:loading_overlay/loading_overlay.dart';

// import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});
  static String id = 'login_screen';
  static String backId = 'home_screen';
  final PageController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // final _auth = FirebaseAuth.instance;
  late String _email;
  late String _password;
  late String _loginStatus = '';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.popAndPushNamed(context, HomePage.id);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LoadingOverlay(
          isLoading: _saving,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  //const TopScreenImage(screenImageName: 'welcome.png'),
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ScreenTitle(
                          title: 'Đăng nhập',
                          backId: LoginPage.backId,
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: 329,
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: const Color(0xFF9F7BFF),
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextField(
                              onChanged: (value) => _email = value,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                label: Text('Email'),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: 329,
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: const Color(0xFF9F7BFF),
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextField(
                              obscureText: true,
                              onChanged: (value) => _password = value,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                label: Text('Mật khẩu'),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        _loginStatus.isNotEmpty
                            ? Text(
                              _loginStatus,
                              style: TextStyle(color: Colors.red, fontSize: 20),
                            )
                            : Container(),
                        SizedBox(height: 20),
                        CustomBottomScreen(
                          textButton: 'Đăng nhập',
                          heroTag: 'login_btn',
                          question: 'Quên mật khẩu?',
                          buttonPressed: () async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() {
                              _saving = true;
                            });
                            try {
                              // await _auth.signInWithEmailAndPassword(
                              //   email: _email,
                              //   password: _password,
                              // );
                              await _login();
                              if (context.mounted) {
                                setState(() {
                                  _saving = false;
                                });

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => HomePage(
                                          isLoggedIn: true,
                                          controller: widget.controller,
                                        ),
                                  ),
                                );
                                // Navigator.pushNamed(context, WelcomeScreen.id);
                              }
                            } catch (e) {
                              // signUpAlert(
                              // context: context,
                              // onPressed: () {
                              setState(() {
                                _saving = false;
                              });
                              //Navigator.popAndPushNamed(context, LoginPage.id);
                              // },
                              // ).show();
                            }
                          },
                          questionPressed: () {
                            // signUpAlert(
                            //   onPressed: () async {
                            //     // await FirebaseAuth.instance
                            //     //     .sendPasswordResetEmail(email: _email);
                            //   },
                            //   title: 'RESET YOUR PASSWORD',
                            //   desc:
                            //       'Click on the button to reset your password',
                            //   btnText: 'Reset Now',
                            //   context: context,
                            // ).show();
                            // widget.controller.animateToPage(
                            //   2,
                            //   duration: const Duration(milliseconds: 500),
                            //   curve: Curves.ease,
                            // );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ResetPasswordPage(
                                      controller: widget.controller,
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future _login() async {
    final response = await http.post(
      Uri.parse('${apiUrl}auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': _email,
        'password': _password,
      }),
    );

    if (response.statusCode == 200) {
      String? setCookie = response.headers['set-cookie'];

      if (setCookie != null) {
        // Split into cookie list
        setCookie = Uri.decodeFull(setCookie);
        List<String> cookies = setCookie.split(',');

        // Create Map to store cookies
        Map<String, String> cookieMap = {};

        for (var cookie in cookies) {
          String keyValue = cookie.split(';')[0]; // Get key=value part before ;
          int index = keyValue.indexOf('='); // Find position of first '='

          if (index != -1) {
            String key = keyValue.substring(0, index).trim();
            String value = keyValue.substring(index + 1).trim();
            cookieMap[key] = value;
          }
        }

        // Get value of each cookie
        String? deviceId = cookieMap['DeviceId'];
        String? refreshToken = cookieMap['RefreshToken'];
        // Convert response.body from String to Map
        Map<String, dynamic> responseJson = jsonDecode(response.body);

        // Get token from response
        Map<String, dynamic> data = responseJson['response']?['data'];
        String? token = data['auth']?['token'];
        if (token != null && refreshToken != null && deviceId != null) {
          await saveToken(token, refreshToken, deviceId);
        }
        Map<String, String> key = {'userId': data['id']};
        await saveTempKey(key);

        // Reconnect MQTT service with the new credentials
        try {
          // Check if foreground service is running
          bool isServiceRunning =
              await ForegroundServiceHelper.isServiceRunning();

          if (isServiceRunning) {
            // Just reconnect MQTT with new credentials
            MqttService mqttService = MqttService();
            await mqttService.connect(source: 'login_page');
            debugPrint('MQTT reconnected after login');
          } else {
            // Start foreground service if it's not running
            await ForegroundServiceHelper.startForegroundService();
            debugPrint('Foreground service started after login');
          }
        } catch (e) {
          debugPrint('Error reconnecting MQTT after login: $e');
          // Continue login process even if MQTT connection fails
          // The foreground service will retry later
        }
      } else {
        print('Không tìm thấy cookie.');
      }
    } else {
      print('Login failed');
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _loginStatus = responseJson['message'];
      throw _loginStatus;
    }
  }
}
