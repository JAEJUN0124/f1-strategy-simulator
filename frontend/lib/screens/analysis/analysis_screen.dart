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

        // 하단 고정 삭제 버튼 영역
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(
            16.0,
            16.0,
            16.0,
            16.0 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              // [수정] 디자인이 적용된 삭제 확인 다이얼로그
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white, // 흰색 배경
                  surfaceTintColor: Colors.white, // 틴트 제거
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // 둥근 모서리
                  ),
                  title: const Text(
                    '리포트 삭제',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  content: const Text(
                    '이 리포트를 영구적으로 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  actionsPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  actions: [
                    // 취소 버튼 (회색)
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    // 삭제 버튼 (메인 컬러 - 빨강)
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        '삭제',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldDelete == true) {
                await ref
                    .read(recentReportsProvider.notifier)
                    .removeReport(result.reportId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('리포트가 삭제되었습니다.'),
                      duration: Duration(seconds: 2),
                    ),
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
