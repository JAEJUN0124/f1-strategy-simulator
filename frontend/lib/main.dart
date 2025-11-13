import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/main_screen.dart';
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
      overrides: [localStorageServiceProvider.overrideWithValue(localStorage)],
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
        // (수정) 앱의 기본 배경색을 흰색으로 설정
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,

        // (오류 수정) CardTheme -> CardThemeData로 변경
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0, // 기본 elevation 제거
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            // (수정) 0xFFE0E0E0 -> 0xFFEEEEEE (더 연한 회색)
            side: BorderSide(color: Color(0xFFEEEEEE)),
          ),
        ),
      ),
      // 시작 화면을 MainScreen으로 변경
      home: MainScreen(),
    );
  }
}
