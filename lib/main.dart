import 'package:flutter/material.dart';

void main() {
  runApp(const AquaOpsApp());
}

class AquaOpsApp extends StatelessWidget {
  const AquaOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaOps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('AquaOps Initialized'),
        ),
      ),
    );
  }
}