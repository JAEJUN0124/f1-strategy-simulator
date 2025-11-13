import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/screens/settings/settings_screen.dart';
import 'package:frontend/screens/simulator/simulator_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color unselectedColor = Colors.grey.shade600;

    // DefaultTabController를 사용하여 3개의 탭을 관리합니다.
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0, // 그림자 제거
          surfaceTintColor: Colors.white, // 스크롤 시 색상 변경 방지
          title: Text(
            'F1 전략 최적화',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            // (수정) 탭바 인디케이터 및 라벨 색상
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: unselectedColor,
            tabs: [
              Tab(
                text: '대시보드',
                icon: Icon(Icons.dashboard_outlined, color: unselectedColor),
                iconMargin: const EdgeInsets.only(bottom: 4.0),
              ),
              Tab(
                text: '시뮬레이터',
                icon: Icon(Icons.play_arrow_outlined, color: unselectedColor),
                iconMargin: const EdgeInsets.only(bottom: 4.0),
              ),
              Tab(
                text: '설정',
                icon: Icon(Icons.settings_outlined, color: unselectedColor),
                iconMargin: const EdgeInsets.only(bottom: 4.0),
              ),
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
