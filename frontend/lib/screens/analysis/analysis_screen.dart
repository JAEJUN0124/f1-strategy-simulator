import 'package:frontend/providers/recent_reports_provider.dart';
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:frontend/screens/analysis/detailed_lap_chart_tab.dart';
import 'package:frontend/screens/analysis/summary_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(simulationResultProvider);

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analysis Report')),
        body: const Center(
          child: Text(
            'No simulation result found. Go back and run a simulation.',
          ),
        ),
      );
    }

    final unselectedColor = Colors.grey.shade600;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            '분석 리포트',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: TabBar(
            indicatorColor: Colors.black87,
            labelColor: Colors.black87,
            unselectedLabelColor: unselectedColor,
            tabs: [
              Tab(
                text: '요약',
                icon: Icon(Icons.bar_chart, color: unselectedColor),
                iconMargin: const EdgeInsets.only(bottom: 4.0),
              ),
              Tab(
                text: '상세 랩 차트',
                icon: Icon(Icons.show_chart, color: unselectedColor),
                iconMargin: const EdgeInsets.only(bottom: 4.0),
              ),
            ],
          ),
        ),
        body: const TabBarView(children: [SummaryTab(), DetailedLapChartTab()]),
        // (추가) 하단 고정 삭제 버튼
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700, // 회색 버튼
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              // 삭제 확인 다이얼로그
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('리포트 삭제'),
                  content: const Text('이 리포트를 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        '삭제',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldDelete == true) {
                // 리포트 삭제 및 화면 닫기
                await ref
                    .read(recentReportsProvider.notifier)
                    .removeReport(result.reportId);
                if (context.mounted) {
                  Navigator.pop(context); // 대시보드로 돌아가기
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('리포트가 삭제되었습니다.')),
                  );
                }
              }
            },
            child: const Text(
              '리포트 삭제',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
