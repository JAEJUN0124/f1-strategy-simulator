import 'package:frontend/models/simulation_response.dart';
import 'package:frontend/providers/recent_reports_provider.dart';
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:frontend/screens/analysis/analysis_screen.dart';
import 'package:frontend/screens/settings/settings_screen.dart';
import 'package:frontend/screens/simulator/simulator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// (수정) StrategyResult 모델 임포트 추가
import 'package:frontend/models/strategy_result.dart'; 

/// 대시보드 화면
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 로컬 저장소에서 최근 리포트 목록 로드
    final List<SimulationResponse> recentReports =
        ref.watch(recentReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('F1 Simulator Dashboard'),
        actions: [
          // 설정 화면으로 이동
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- 시뮬레이터 실행 버튼 ---
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Go to Simulator'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SimulatorScreen()),
              );
            },
          ),
          const SizedBox(height: 24),

          // --- 최근 리포트 목록 ---
          Text(
            'Recent Reports',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(),
          if (recentReports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text('No recent reports found. Run a simulation!'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentReports.length,
              itemBuilder: (context, index) {
                final report = recentReports[index];
                
                // (수정) 'results' 맵 대신 객체의 속성에 직접 접근
                final StrategyResult actual = report.actual;
                final StrategyResult optimal = report.optimal;
                
                // (수정) 데이터 접근 방식 변경 (as StrategyResult 불필요)
                final driverId = optimal.name; // (기존 로직 유지 - Optimal의 이름)
                final totalTime = actual.totalTime;

                return Card(
                  child: ListTile(
                    title: Text('Report: ${report.reportId.substring(0, 8)}'),
                    subtitle: Text(
                      // (수정) 'actual?' 대신 'totalTime' 변수 사용
                      'Driver: $driverId / Time: ${totalTime.toStringAsFixed(2)}s\n'
                      'Saved: ${DateFormat.yMd().add_jm().format(DateTime.now())}', // (참고: 이 시간은 저장된 시간이 아닌 '지금' 시간입니다)
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    isThreeLine: true,
                    onTap: () {
                      // 탭 시 AnalysisScreen으로 이동
                      
                      // 1. 선택한 리포트를 simulationResultProvider에 설정
                      ref.read(simulationResultProvider.notifier).state = report;
                      
                      // 2. AnalysisScreen으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalysisScreen(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}