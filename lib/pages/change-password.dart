import 'package:flutter/material.dart';
import 'package:hmes/constants.dart';
import 'package:loading_overlay/loading_overlay.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thay đổi mật khẩu')),
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
                      SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(width: 2.5, color: kTextColor),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            // _email = value;
                          },
                          style: const TextStyle(fontSize: 20),
                          decoration: kTextInputDecoration.copyWith(
                            hintText: 'Mật khẩu cũ',
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(width: 2.5, color: kTextColor),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            // _email = value;
                          },
                          style: const TextStyle(fontSize: 20),
                          decoration: kTextInputDecoration.copyWith(
                            hintText: 'Mật khẩu mới',
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(width: 2.5, color: kTextColor),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            // _email = value;
                          },
                          style: const TextStyle(fontSize: 20),
                          decoration: kTextInputDecoration.copyWith(
                            hintText: 'Nhập lại mật khẩu mới',
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
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
}
