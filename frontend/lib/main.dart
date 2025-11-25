import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/main_screen.dart';
import 'package:frontend/services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localStorage = await LocalStorageService.create();

  runApp(
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
    // F1 스타일의 강렬한 레드 컬러 정의
    const primaryColor = Color(0xFFFF1801);

    return MaterialApp(
      title: 'F1 Strategy Simulator',
      debugShowCheckedModeBanner: false, // 디버그 배너 제거 (깔끔하게)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          // 배경색을 완전 흰색이 아닌 아주 연한 회색으로 설정하여 카드와 구분감 형성
          surface: Colors.white,
          background: const Color(0xFFF5F7FA),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA), // 앱 배경색 변경
        // AppBar 테마 (상단 바 스타일)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w800, // 폰트 굵기 강화
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: Colors.black87),
        ),

        // 카드 테마 (입체감 부여)
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2, // 그림자 추가
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // 더 둥근 모서리
            side: BorderSide.none, // 테두리 제거하고 그림자로 대체
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),

        // 입력 필드 테마 (깔끔한 스타일)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F2F5), // 연한 회색 배경
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),

        // 버튼 테마
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
