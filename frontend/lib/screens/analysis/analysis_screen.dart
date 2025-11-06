import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:frontend/screens/analysis/summary_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 분석 리포트 화면 (ConsumerWidget)
class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(simulationResultProvider);

    if (result == null) {
      // 혹시라도 결과 없이 이 화면에 접근한 경우
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('No simulation result found. Go back and run a simulation.'),
        ),
      );
    }

    // TabBar/TabBarView 사용
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analysis Report'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Summary', icon: Icon(Icons.bar_chart)),
              Tab(text: 'Detailed Lap Chart', icon: Icon(Icons.show_chart)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. 요약 탭
            const SummaryTab(),
            
            // 2. 상세 랩 차트 탭
            // (다음 단계에서 여기에 LineChart와 RaceEvent 음영 처리를 구현)
            Container(
              alignment: Alignment.center,
              child: const Text('Detailed Lap Chart (WIP)'),
            ),
          ],
        ),
      ),
    );
  }
}