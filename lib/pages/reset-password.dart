import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hmes/components/components.dart';

import 'package:hmes/components/otp_form.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/helper/sharedPreferencesHelper.dart';
import 'package:hmes/pages/home.dart';
import 'package:hmes/pages/login.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:http/http.dart' as http;

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.controller});
  final PageController controller;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _saving = false;
  late String _resetPassword = '';

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LoadingOverlay(
        isLoading: _saving,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Padding(
                //   padding: const EdgeInsets.only(top: 13, right: 15),
                //   child: Image.asset(
                //     "assets/images/vector-3.png",
                //     width: 428,
                //     height: 457,
                //   ),
                // ),
                const SizedBox(height: 18),
                Container(
                  child: Column(
                    // textDirection: TextDirection.ltr,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // const Text(
                      //   'Reset Password\n',
                      //   style: TextStyle(
                      //     color: Color(0xFF755DC1),
                      //     fontSize: 25,
                      //     // fontFamily: 'Poppins',
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),
                      ScreenTitle(
                        title: "Khôi phục mật khẩu",
                        backId: LoginPage.backId,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nhập email của bạn để nhận mã xác nhận',
                        style: TextStyle(
                          color: Color(0xFF837E93),
                          fontSize: 14,
                          // fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                            controller: _emailController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              label: Text('Email'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                        child: SizedBox(
                          width: screenWidth * 0.85,
                          height: screenHeight * 0.06,
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _saving = true;
                              });
                              try {
                                await _sendOTP();
                                if (context.mounted) {
                                  setState(() {
                                    _saving = false;
                                  });
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => VerifyScreen(
                                            controller: widget.controller,
                                          ),
                                    ),
                                  );
                                  // Navigator.pushNamed(context, WelcomeScreen.id);
                                }
                              } catch (e) {
                                setState(() {
                                  _saving = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9F7BFF),
                            ),
                            child: const Text(
                              'Tiếp tục',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                // fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
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

  Future _sendOTP() async {
    if (_emailController.value.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Vui lòng nhập email của bạn!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
      return;
    }

    final response = await http.post(
      Uri.parse('${apiUrl}otp/send'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(_emailController.value.text),
    );
    Map<String, String> key = {'email': _emailController.value.text};
    await saveTempKey(key);

    if (response.statusCode != 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _resetPassword = responseJson['message'];
      switch (_resetPassword) {
        case "Can not send OTP right now!":
          _resetPassword = "Không thể gửi mã OTP lúc này!";
          break;
        case "User not found!":
          _resetPassword = "Người dùng không tồn tại";
          break;
        default:
      }
      Fluttertoast.showToast(
        msg: _resetPassword,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );

      throw _resetPassword;
    } else {
      _resetPassword = 'Mã xác thực đã được gửi đến email của bạn!';
      Fluttertoast.showToast(
        msg: _resetPassword,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    }
  }
}

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key, required this.controller});
  final PageController controller;
  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  String? verifyCode;
  String? _email;
  String _verfiyOTPStatus = '';
  bool isResendDisabled = true; // Ban đầu disable nút Resend
  bool showTimer = true; // Ban đầu hiển thị Timer
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    String? email = await getTempKey('email');
    if (mounted && email != null) {
      setState(() {
        _email = email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Trả về false để chặn nút quay lại
        return false;
      },
      child: LoadingOverlay(
        isLoading: _saving,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Padding(
              //   padding: const EdgeInsets.only(top: 13, right: 15),
              //   child: Image.asset(
              //     "assets/images/vector-3.png",
              //     width: 428,
              //     height: 457,
              //   ),
              // ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  textDirection: TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ScreenTitle(title: 'Xác thực OTP'),
                    const SizedBox(height: 16),
                    Focus(
                      autofocus: true,
                      child: Container(
                        width: 600,
                        height: 75,
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
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: OtpForm(
                            callBack: (code) {
                              verifyCode = code;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: SizedBox(
                        width: 329,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              _saving = true;
                            });
                            try {
                              await _verifyOTP();
                              if (context.mounted) {
                                setState(() {
                                  _saving = false;
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => InputPassword(
                                          controller: widget.controller,
                                        ),
                                  ),
                                );
                                // Navigator.pushNamed(context, WelcomeScreen.id);
                              }
                            } catch (e) {
                              setState(() {
                                _saving = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9F7BFF),
                          ),
                          child: const Text(
                            'Tiếp tục',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          // onPressed: isResendDisabled ? null : _resendOtp,
                          onPressed: () {},
                          child: Text(
                            'Gửi lại mã OTP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  isResendDisabled
                                      ? Colors.grey
                                      : const Color(0xFF755DC1),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        if (showTimer)
                          TimerCountdown(
                            spacerWidth: 0,
                            enableDescriptions: false,
                            colonsTextStyle: const TextStyle(
                              color: Color(0xFF755DC1),
                              fontSize: 13,
                              // fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                            timeTextStyle: const TextStyle(
                              color: Color(0xFF755DC1),
                              fontSize: 13,
                              //  fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                            format: CountDownTimerFormat.minutesSeconds,
                            endTime: DateTime.now().add(
                              const Duration(minutes: 2, seconds: 0),
                            ),
                            onEnd: () {
                              setState(() {
                                isResendDisabled = false; // Bật nút Resend
                                showTimer = false; // Ẩn Timer
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      // onPressed: isResendDisabled ? null : _resendOtp,
                      onPressed: () async {
                        await removeTempKey('email');
                        await removeKey('tempToken');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    LoginPage(controller: widget.controller),
                          ),
                        );
                      },
                      child: Text(
                        '< Quay trở lại đăng nhập',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF755DC1),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 37),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: InkWell(
                  onTap: () {
                    widget.controller.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease,
                    );
                  },
                  child: Text(
                    'Mã xác thực 6 số đã được gửi tới email: $_email',
                    style: TextStyle(
                      color: Color(0xFF837E93),
                      fontSize: 11,
                      // fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _verifyOTP() async {
    String? email = await getTempKey('email');
    if (email == null) {
      _verfiyOTPStatus = 'Có lỗi xảy ra. Vu lòng thử lại sau!';
      Fluttertoast.showToast(
        msg: _verfiyOTPStatus,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
      await removeTempKey('email');
      throw _verfiyOTPStatus;
    }

    if (verifyCode == null) {
      _verfiyOTPStatus = 'Vui long nhập mã OTP!';
      Fluttertoast.showToast(
        msg: _verfiyOTPStatus,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
      throw _verfiyOTPStatus;
    }

    final response = await http.post(
      Uri.parse('${apiUrl}otp/verify'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'otpCode': verifyCode!,
      }),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      String? token = responseJson['response']?['data']?['tempToken'];

      if (token != null) {
        Map<String, String> key = {'tempToken': token};
        await saveKey(key);
      }

      _verfiyOTPStatus = 'Xác thực thành công!';
      Fluttertoast.showToast(
        msg: _verfiyOTPStatus,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _verfiyOTPStatus = responseJson['message'];
      switch (_verfiyOTPStatus) {
        case "The OTP is expired!":
          _verfiyOTPStatus = "Mã OTP đã hết hạn!";
          break;
        case "User not found":
          _verfiyOTPStatus = "Người dùng không tồn tại";
          break;
        default:
      }
      Fluttertoast.showToast(
        msg: _verfiyOTPStatus,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );

      throw _verfiyOTPStatus;
    }
  }
}

class InputPassword extends StatefulWidget {
  const InputPassword({super.key, required this.controller});
  final PageController controller;

  @override
  State<InputPassword> createState() => _InputPasswordState();
}

class _InputPasswordState extends State<InputPassword> {
  bool _saving = false;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  late String _inputPasswordStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: WillPopScope(
        onWillPop: () async {
          // Trả về false để chặn nút quay lại
          return false;
        },
        child: LoadingOverlay(
          isLoading: _saving,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 13, right: 15),
                  //   child: Image.asset(
                  //     "assets/images/vector-3.png",
                  //     width: 428,
                  //     height: 457,
                  //   ),
                  // ),
                  const SizedBox(height: 18),
                  Container(
                    child: Column(
                      // textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // const Text(
                        //   'Reset Password\n',
                        //   style: TextStyle(
                        //     color: Color(0xFF755DC1),
                        //     fontSize: 25,
                        //     // fontFamily: 'Poppins',
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                        ScreenTitle(title: "Khôi phục mật khẩu"),
                        const SizedBox(height: 16),
                        const Text(
                          'Nhập mật khẩu bạn muốn thay đổi',
                          style: TextStyle(
                            color: Color(0xFF837E93),
                            fontSize: 11,
                            // fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                              controller: _newPasswordController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                label: Text('Mật khẩu mới'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                              controller: _confirmPasswordController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                label: Text('Xác nhận mật khẩu'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                          child: SizedBox(
                            width: 329,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                setState(() {
                                  _saving = true;
                                });
                                try {
                                  await _inputPassword();
                                  if (context.mounted) {
                                    setState(() {
                                      _saving = false;
                                    });
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => HomePage(
                                              isLoggedIn: false,
                                              controller: widget.controller,
                                            ),
                                      ),
                                    );
                                    // Navigator.pushNamed(context, WelcomeScreen.id);
                                  }
                                } catch (e) {
                                  setState(() {
                                    _saving = false;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9F7BFF),
                              ),
                              child: const Text(
                                'Send',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  // fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
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

  Future _inputPassword() async {
    String token = (await getKey("tempToken")).toString();
    final response = await http.post(
      Uri.parse('${apiUrl}auth/me/reset-password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'newPassword': _newPasswordController.value.text,
        'confirmPassword': _confirmPasswordController.value.text,
      }),
    );

    if (response.statusCode == 200) {
      await removeKey('tempToken');
      await removeTempKey('email');
      _inputPasswordStatus = 'Khôi phục mật khẩu thành công!';
      Fluttertoast.showToast(
        msg: _inputPasswordStatus,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _inputPasswordStatus = responseJson['message'];
      switch (_inputPasswordStatus) {
        case "New password and confirm password is not match!":
          _inputPasswordStatus =
              "Mật khẩu mới và xác nhận mật khẩu không khớp!";
          break;
        case "User not found!":
          _inputPasswordStatus = "Người dùng không tồn tại";
          break;
        case "Password must be at least 6 characters!":
          _inputPasswordStatus = "Mật khẩu phải chứa ít nhất 6 ký tự!";
          break;
        default:
      }
      Fluttertoast.showToast(
        msg: _inputPasswordStatus,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        textColor: Colors.black,
        fontSize: 16.0,
      );

      throw _inputPasswordStatus;
    }
  }
}
