import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hmes/components/components.dart';
import 'package:hmes/constants.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:hmes/pages/home.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

Future<void> saveToken(
  String token,
  String refreshToken,
  String deviceId,
) async {
  await storage.write(key: 'token', value: token);
  await storage.write(key: 'refreshToken', value: refreshToken);
  await storage.write(key: 'deviceId', value: deviceId);
}
// import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static String id = 'login_screen';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // final _auth = FirebaseAuth.instance;
  late String _email;
  late String _password;
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
                        ScreenTitle(title: 'Login', pageId: LoginPage.id),
                        SizedBox(height: 20),
                        CustomTextField(
                          textField: TextField(
                            onChanged: (value) {
                              _email = value;
                            },
                            style: const TextStyle(fontSize: 20),
                            decoration: kTextInputDecoration.copyWith(
                              hintText: 'Email',
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        CustomTextField(
                          textField: TextField(
                            obscureText: true,
                            onChanged: (value) {
                              _password = value;
                            },
                            style: const TextStyle(fontSize: 20),
                            decoration: kTextInputDecoration.copyWith(
                              hintText: 'Password',
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        CustomBottomScreen(
                          textButton: 'Login',
                          heroTag: 'login_btn',
                          question: 'Forgot password?',
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
                              _login();
                              if (context.mounted) {
                                setState(() {
                                  _saving = false;
                                  Navigator.popAndPushNamed(
                                    context,
                                    LoginPage.id,
                                  );
                                });
                                // Navigator.pushNamed(context, WelcomeScreen.id);
                              }
                            } catch (e) {
                              signUpAlert(
                                context: context,
                                onPressed: () {
                                  setState(() {
                                    _saving = false;
                                  });
                                  Navigator.popAndPushNamed(
                                    context,
                                    LoginPage.id,
                                  );
                                },
                                title: 'WRONG PASSWORD OR EMAIL',
                                desc:
                                    'Confirm your email and password and try again',
                                btnText: 'Try Now',
                              ).show();
                            }
                          },
                          questionPressed: () {
                            signUpAlert(
                              onPressed: () async {
                                // await FirebaseAuth.instance
                                //     .sendPasswordResetEmail(email: _email);
                              },
                              title: 'RESET YOUR PASSWORD',
                              desc:
                                  'Click on the button to reset your password',
                              btnText: 'Reset Now',
                              context: context,
                            ).show();
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

  void _login() async {
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
        // Chia thành danh sách các cookie
        List<String> cookies = setCookie.split(',');

        // Tạo Map để lưu trữ cookie
        Map<String, String> cookieMap = {};

        for (var cookie in cookies) {
          List<String> parts = cookie.split(';')[0].split('=');
          if (parts.length == 2) {
            cookieMap[parts[0].trim()] = parts[1].trim();
          }
        }

        // Lấy giá trị của từng cookie
        String? deviceId = cookieMap['DeviceId'];
        String? refreshToken = cookieMap['RefreshToken'];
        // Chuyển response.body từ String thành Map
        Map<String, dynamic> responseJson = jsonDecode(response.body);

        // Truy xuất token từ response
        String? token = responseJson['auth']?['token'];
        if (token != null && refreshToken != null && deviceId != null) {
          saveToken(token, refreshToken, deviceId);
        }
      } else {
        print('Không tìm thấy cookie.');
      }
    } else {
      print('Login failed');
    }
  }
}
