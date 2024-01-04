import 'package:flutter/material.dart';
import 'screens/loading_screen.dart';

void main() {
  runApp(const GpsApp());
}

class GpsApp extends StatelessWidget {
  const GpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: const LoadingScreen(),
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
    );
  }
}
