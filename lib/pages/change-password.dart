import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hmes/components/components.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/helper/logout.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key, required this.controller});
  final PageController controller;

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  late String _oldPassword;
  late String _newPassword;
  late String _confirmPassword;
  late String _changePasswordStatus = '';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Thay đổi mật khẩu')),
      body: LoadingOverlay(
        isLoading: _saving,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              children: [
                //const TopScreenImage(screenImageName: 'welcome.png'),
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Container(
                        width: screenWidth * 0.85,
                        height: screenHeight * 0.06,
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
                            onChanged: (value) => {_oldPassword = value},
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              label: Text('Mật khẩu mới'),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: screenWidth * 0.85,
                        height: screenHeight * 0.06,
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
                            onChanged: (value) {
                              _newPassword = value;
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              label: Text('Mật khẩu mới'),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: screenWidth * 0.85,
                        height: screenHeight * 0.06,
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
                            onChanged: (value) {
                              _confirmPassword = value;
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              label: Text('Nhập lại mật khẩu mới'),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(height: 20),
                      CustomBottomScreen(
                        textButton: 'Thay đổi',
                        heroTag: 'change_password_btn',
                        question: '',
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
                            await _changePassword();
                            if (context.mounted) {
                              setState(() {
                                _saving = false;
                                Navigator.pop(context);
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
                          // signUpAlert(
                          //   onPressed: () async {
                          //     // await FirebaseAuth.instance
                          //     //     .sendPasswordResetEmail(email: _email);
                          //   },
                          //   title: 'RESET YOUR PASSWORD',
                          //   desc: 'Click on the button to reset your password',
                          //   btnText: 'Reset Now',
                          //   context: context,
                          // ).show();
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
    );
  }

  Future _changePassword() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();
    final response = await http.post(
      Uri.parse('${apiUrl}auth/me/change-password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'oldPassword': _oldPassword,
        'newPassword': _newPassword,
        'confirmPassword': _confirmPassword,
      }),
    );

    String? newAccessToken = response.headers['New-Access-Token'];

    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }

    if (response.statusCode == 200) {
      _changePasswordStatus = 'Đã cập nhật mật khẩu mới!';
      Fluttertoast.showToast(
        msg: _changePasswordStatus,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    } else if (response.statusCode == 401) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Logout(controller: widget.controller),
        ),
      );
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _changePasswordStatus = responseJson['message'];
      switch (_changePasswordStatus) {
        case "Old password is incorrect":
          _changePasswordStatus = "Mật khẩu cũ không chính xác";
          break;
        case "User not found":
          _changePasswordStatus = "Người dùng không tồn tại";
          break;
        case "New password and confirm password are not matched":
          _changePasswordStatus =
              "Mật khẩu mới và nhập lại mật khẩu mới không khớp";
          break;
        default:
      }

      Fluttertoast.showToast(
        msg: _changePasswordStatus,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );

      throw _changePasswordStatus;
    }
  }
}
