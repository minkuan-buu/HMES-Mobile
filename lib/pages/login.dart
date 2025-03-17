import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hmes/components/components.dart';
import 'package:hmes/constants.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/helper/tokenHelper.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:hmes/pages/home.dart';
import 'package:http/http.dart' as http;

// import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static String id = 'login_screen';
  static String backId = 'home_screen';

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
                              hintText: 'Mật khẩu',
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        _loginStatus != null
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return HomePage(isLoggedIn: true);
                                      },
                                    ),
                                  );
                                });
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
        // Chia thành danh sách các cookie
        setCookie = Uri.decodeFull(setCookie);
        List<String> cookies = setCookie.split(',');

        // Tạo Map để lưu trữ cookie
        Map<String, String> cookieMap = {};

        for (var cookie in cookies) {
          String keyValue =
              cookie.split(';')[0]; // Lấy phần key=value trước dấu ;
          int index = keyValue.indexOf('='); // Tìm vị trí dấu '=' đầu tiên

          if (index != -1) {
            String key = keyValue.substring(0, index).trim();
            String value = keyValue.substring(index + 1).trim();
            cookieMap[key] = value;
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
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _loginStatus = responseJson['message'];
      throw _loginStatus;
    }
  }
}
