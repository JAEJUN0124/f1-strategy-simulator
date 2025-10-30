// frontend/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. import 추가

void main() {
  runApp(
    // 2. ProviderScope로 앱 전체를 감쌉니다. 
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Strategy Simulator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MyHomePage(), // TODO: 나중에 DashboardScreen으로 변경
    );
  }
}

// TODO: 임시 MyHomePage. 나중에 screens/dashboard/dashboard_screen.dart로 대체합니다.
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('F1 Simulator'),
      ),
      body: const Center(
        child: Text('환경 설정 완료'),
      ),
    );
  }
}