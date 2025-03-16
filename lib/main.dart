import 'package:flutter/material.dart';
import 'package:hmes/pages/home.dart';
import 'package:hmes/pages/login.dart';
import 'package:hmes/pages/register.dart';
import 'package:hmes/helper/tokenHelper.dart';
// import 'package:hmes/pages/welcome.dart';
// import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await removeToken();
  String token = (await getToken()).toString();
  String refreshToken = (await getRefreshToken()).toString();
  String deviceId = (await getDeviceId()).toString();
  print('Token: $token');
  print('Refresh Token: $refreshToken');
  print('Device ID: $deviceId');
  final bool isLoggedIn =
      token.isNotEmpty && refreshToken.isNotEmpty && deviceId.isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: const TextTheme(bodyMedium: TextStyle(fontFamily: 'Ubuntu')),
      ),
      home: HomePage(isLoggedIn: isLoggedIn), // ✅ Truyền trực tiếp vào HomePage
      routes: {
        LoginPage.id: (context) => LoginPage(),
        SignUpPage.id: (context) => SignUpPage(),
      },
    );
  }
}
