import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/simulator/simulator_screen.dart';
import 'package:frontend/services/local_storage_service.dart';

// main 함수를 async로 변경
Future<void> main() async {
  
  // Flutter 바인딩 초기화 (async main 실행 시 필수)
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences를 로드하여 LocalStorageService 인스턴스 생성
  final localStorage = await LocalStorageService.create();

  runApp(
    // ProviderScope에 생성된 서비스 인스턴스를 주입(override)
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorage),
      ],
      child: const MyApp(),
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