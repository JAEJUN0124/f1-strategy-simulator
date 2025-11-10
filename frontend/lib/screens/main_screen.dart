import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/screens/settings/settings_screen.dart';
import 'package:frontend/screens/simulator/simulator_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DefaultTabController를 사용하여 3개의 탭을 관리합니다.
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('F1 전략 최적화'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '대시보드', icon: Icon(Icons.dashboard_outlined)),
              Tab(text: '시뮬레이터', icon: Icon(Icons.play_arrow_outlined)),
              Tab(text: '설정', icon: Icon(Icons.settings_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // 1. 대시보드 화면 (곧 수정될 파일)
            DashboardScreen(),
            
            // 2. 시뮬레이터 화면 (기존 파일 재사용)
            SimulatorScreen(),
            
            // 3. 설정 화면 (기존 파일 재사용)
            SettingsScreen(),
          ],
        ),
      ),
    );
  }
}