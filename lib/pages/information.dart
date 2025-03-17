import 'package:flutter/material.dart';

class InfomationPage extends StatefulWidget {
  const InfomationPage({super.key});

  @override
  State<InfomationPage> createState() => _InfomationPageState();
}

class _InfomationPageState extends State<InfomationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Thông tin cá nhân')));
  }
}
