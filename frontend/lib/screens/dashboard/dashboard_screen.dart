import 'package:frontend/models/race_info.dart';
import 'package:frontend/models/simulation_response.dart';
import 'package:frontend/providers/data_provider.dart';
import 'package:frontend/providers/recent_reports_provider.dart';
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:frontend/screens/analysis/analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/strategy_result.dart';
import 'package:frontend/widgets/collapsible_section.dart';

/// 대시보드 화면
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 로컬 저장소에서 최근 리포트 목록 로드
    final List<SimulationResponse> recentReports = ref.watch(
      recentReportsProvider,
    );

    // (추가) 시즌 캘린더 데이터 로드 (가장 최근 연도)
    // providers/simulator_config_provider.dart에서 기본값이 2024년이므로
    // racesProvider가 자동으로 2024년 캘린더를 가져옴
    // (참고: 연도가 바뀌면 simulator_config_provider의 기본값을 변경해야 함. 일단은 24년 데이터)
    final AsyncValue<List<RaceInfo>> races = ref.watch(racesProvider);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- 1. 시즌 캘린더 섹션 (CollapsibleSection 사용) ---
        CollapsibleSection(
          title: '시즌 캘린더',
          icon: Icons.calendar_today_outlined,
          initialIsExpanded: true, // 기본으로 펼쳐진 상태
          child: races.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('캘린더 로드 실패: $err'),
            data: (raceList) {
              if (raceList.isEmpty) {
                return const Center(child: Text('시즌 캘린더 정보가 없습니다.'));
              }
              // 카드 리스트 생성
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: raceList.length,
                itemBuilder: (context, index) {
                  final race = raceList[index];
                  // (날짜 포맷팅은 API 응답에 날짜가 없으므로 임시로 제외)
                  return Card(
                    // (수정) elevation 및 margin 변경
                    elevation: 0, // CardTheme이 0으로 설정함
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    // (수정) 입력 부분이 아니므로 흰색 배경
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      title: Text(race.name),
                      subtitle: Text('라운드 ${race.round}'),
                      // (날짜가 있다면 여기에 표시)
                      // trailing: Text('3월 2일'),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // --- 2. 최근 리포트 섹션 (CollapsibleSection 사용) ---
        CollapsibleSection(
          title: '최근 리포트',
          icon: Icons.article_outlined,
          initialIsExpanded: true, // 기본으로 펼쳐진 상태
          child: recentReports.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text('아직 저장된 리포트가 없습니다.\n시뮬레이터를 실행해 보세요!'),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentReports.length,
                  itemBuilder: (context, index) {
                    final report = recentReports[index];
                    final StrategyResult actual = report.actual;
                    final StrategyResult optimal = report.optimal;
                    final driverId = optimal.name;
                    final totalTime = actual.totalTime;

                    return Card(
                      // (수정) elevation 및 margin 변경
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      // (수정) 입력 부분이 아니므로 흰색 배경
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        title: Text('리포트: ${report.reportId.substring(0, 8)}'),
                        subtitle: Text(
                          '드라이버: $driverId / 기록: ${totalTime.toStringAsFixed(2)}초\n'
                          '저장일: ${DateFormat.yMd().add_jm().format(DateTime.now())}', // (참고: 이 시간은 저장된 시간이 아닌 '지금' 시간)
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        isThreeLine: true,
                        onTap: () {
                          ref.read(simulationResultProvider.notifier).state =
                              report;
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
        ),
      ],
    );
  }
}
