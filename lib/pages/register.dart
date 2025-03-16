import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hmes/components/components.dart';
import 'package:hmes/pages/home.dart';
import 'package:hmes/pages/login.dart';
// import 'package:firebase_auth/firebase_auth.dart';
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
  // final _auth = FirebaseAuth.instance;
  late String _email;
  late String _password;
  late String _confirmPass;
  bool _saving = false;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TopScreenImage(screenImageName: 'signup.png'),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ScreenTitle(
                            title: 'Sign Up',
                            backId: SignUpPage.backId,
                          ),
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
                          CustomTextField(
                            textField: TextField(
                              obscureText: true,
                              onChanged: (value) {
                                _confirmPass = value;
                              },
                              style: const TextStyle(fontSize: 20),
                              decoration: kTextInputDecoration.copyWith(
                                hintText: 'Confirm Password',
                              ),
                            ),
                          ),
                          CustomBottomScreen(
                            textButton: 'Sign Up',
                            heroTag: 'signup_btn',
                            question: 'Have an account?',
                            buttonPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              setState(() {
                                _saving = true;
                              });
                              if (_confirmPass == _password) {
                                try {
                                  // await _auth.createUserWithEmailAndPassword(
                                  //   email: _email,
                                  //   password: _password,
                                  // );

                                  if (context.mounted) {
                                    signUpAlert(
                                      context: context,
                                      title: 'GOOD JOB',
                                      desc: 'Go login now',
                                      btnText: 'Login Now',
                                      onPressed: () {
                                        setState(() {
                                          _saving = false;
                                          Navigator.popAndPushNamed(
                                            context,
                                            SignUpPage.id,
                                          );
                                        });
                                        Navigator.pushNamed(
                                          context,
                                          LoginPage.id,
                                        );
                                      },
                                    ).show();
                                  }
                                } catch (e) {
                                  signUpAlert(
                                    context: context,
                                    onPressed: () {
                                      SystemNavigator.pop();
                                    },
                                    title: 'SOMETHING WRONG',
                                    desc: 'Close the app and try again',
                                    btnText: 'Close Now',
                                  );
                                }
                              } else {
                                showAlert(
                                  context: context,
                                  title: 'WRONG PASSWORD',
                                  desc:
                                      'Make sure that you write the same password twice',
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ).show();
                              }
                            },
                            questionPressed: () async {
                              Navigator.pushNamed(context, LoginPage.id);
                            },
                          ),
                        ],
                      ),
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
}
