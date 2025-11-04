import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/simulator/simulator_screen.dart';

void main() {
  runApp(
    // 2. ProviderScope로 앱 전체를 감쌈? 감싸다?
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
      home: const SimulatorScreen(),
    );
  }
}

// TODO: 임시 MyHomePage. 나중에 screens/dashboard/dashboard_screen.dart로 대체
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