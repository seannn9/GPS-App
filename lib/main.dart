import 'package:flutter/material.dart';
import 'screens/loading.dart';

void main() {
  runApp(const GpsApp());
}

class GpsApp extends StatelessWidget {
  const GpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData.dark(),
        home: const LoadingScreen()
    );
  }
}
