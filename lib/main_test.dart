import 'package:flutter/material.dart';
import 'dart:io';
import 'screens/qr_test_screen.dart';

void main() {
  runApp(const QRTestApp());
}

class QRTestApp extends StatelessWidget {
  const QRTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Test App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const QRTestScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
