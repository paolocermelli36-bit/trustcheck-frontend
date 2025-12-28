import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TrustCheckApp());
}

class TrustCheckApp extends StatelessWidget {
  const TrustCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrustCheck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      home: const HomeScreen(),
    );
  }
}