import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hmes/components/components.dart';
import 'package:hmes/pages/home.dart';
import 'package:hmes/pages/login.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:http/http.dart' as http;
import 'package:hmes/constants.dart';
import 'package:loading_overlay/loading_overlay.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  static String id = 'signup_screen';
  static String backId = 'home_screen';

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late String _name = '';
  late String _email = '';
  late String _phone = '';
  late String _password = '';
  late String _confirmPass = '';
  bool _saving = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.popAndPushNamed(context, HomePage.id);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LoadingOverlay(
          isLoading: _saving,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ScreenTitle(
                            title: 'Đăng ký',
                            backId: SignUpPage.backId,
                          ),
                          const SizedBox(height: 20),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                onChanged: (value) => _name = value,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  label: Text('Họ và tên'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                onChanged: (value) => _email = value,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  label: Text('Email'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                onChanged: (value) => _phone = value,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  label: Text('Số điện thoại'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
                          const SizedBox(height: 15),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                obscureText: true,
                                onChanged: (value) => _confirmPass = value,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  label: Text('Xác nhận mật khẩu'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          if (_errorMessage.isNotEmpty)
                            Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 15),
                          CustomBottomScreen(
                            textButton: 'Đăng ký',
                            heroTag: 'signup_btn',
                            question: 'Đã có tài khoản?',
                            buttonPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();

                              // Validate input
                              if (_name.isEmpty ||
                                  _email.isEmpty ||
                                  _phone.isEmpty ||
                                  _password.isEmpty ||
                                  _confirmPass.isEmpty) {
                                setState(() {
                                  _errorMessage =
                                      'Vui lòng điền đầy đủ thông tin';
                                });
                                return;
                              }

                              // Validate phone number
                              if (_phone.length != 10 ||
                                  !_phone.startsWith('0')) {
                                setState(() {
                                  _errorMessage =
                                      'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0';
                                });
                                return;
                              }

                              // Validate password match
                              if (_confirmPass != _password) {
                                setState(() {
                                  _errorMessage =
                                      'Mật khẩu xác nhận không khớp';
                                });
                                return;
                              }

                              setState(() {
                                _saving = true;
                                _errorMessage = '';
                              });

                              try {
                                await _register();

                                if (context.mounted) {
                                  setState(() {
                                    _saving = false;
                                  });

                                  signUpAlert(
                                    context: context,
                                    title: 'Đăng ký thành công',
                                    desc:
                                        'Tài khoản của bạn đã được tạo thành công',
                                    btnText: 'Đăng nhập ngay',
                                    onPressed: () {
                                      // Get the page controller
                                      final pageController = PageController();

                                      // Navigate to login page with the required controller
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => LoginPage(
                                                controller: pageController,
                                              ),
                                        ),
                                      );
                                    },
                                  ).show();
                                }
                              } catch (e) {
                                setState(() {
                                  _saving = false;
                                  _errorMessage = e.toString();
                                });
                              }
                            },
                            questionPressed: () async {
                              // Create a page controller to pass to LoginPage
                              final pageController = PageController();

                              // Navigate to login page with the required controller
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          LoginPage(controller: pageController),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    final response = await http.post(
      Uri.parse('${apiUrl}auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': _name,
        'email': _email,
        'phone': _phone,
        'password': _password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Registration successful
      return;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      String errorMessage = responseJson['message'] ?? 'Đăng ký thất bại';
      throw errorMessage;
    }
  }
}
