import 'package:flutter/material.dart';
import 'package:hmes/pages/home.dart';
import 'package:hmes/pages/login.dart';
import 'package:hmes/pages/register.dart';
// import 'package:hmes/pages/welcome.dart';
// import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: const TextTheme(bodyMedium: TextStyle(fontFamily: 'Ubuntu')),
      ),
      initialRoute: HomePage.id,
      routes: {
        HomePage.id: (context) => HomePage(),
        LoginPage.id: (context) => LoginPage(),
        SignUpPage.id: (context) => SignUpPage(),
        // WelcomeScreen.id: (context) => WelcomeScreen(),
      },
    );
  }
}
