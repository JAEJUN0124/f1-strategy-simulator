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

    // 시즌 캘린더 데이터 로드
    final AsyncValue<List<RaceInfo>> races = ref.watch(racesProvider);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- 1. 시즌 캘린더 섹션 ---
        races.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (err, stack) => Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Error: $err'),
            ),
          ),
          data: (raceList) {
            // 미리보기 위젯 (최대 3개 + '...')과 전체 위젯 생성
            Widget previewWidget = _buildRaceList(
              context,
              raceList,
              isPreview: true,
            );
            Widget fullWidget = _buildRaceList(
              context,
              raceList,
              isPreview: false,
            );

            return CollapsibleSection(
              title: '시즌 캘린더',
              icon: Icons.calendar_today_outlined,
              initialIsExpanded: false, // 기본적으로 접힘 상태
              previewChild: previewWidget, // 접혔을 때 보일 위젯
              child: fullWidget, // 펼쳤을 때 보일 위젯
            );
          },
        ),

        // --- 2. 최근 리포트 섹션 ---
        CollapsibleSection(
          title: '최근 리포트',
          icon: Icons.article_outlined,
          initialIsExpanded: false, // 기본적으로 접힘 상태
          previewChild: _buildReportList(
            context,
            ref,
            recentReports,
            isPreview: true,
          ),
          child: _buildReportList(
            context,
            ref,
            recentReports,
            isPreview: false,
          ),
        ),
      ],
    );
  }

  /// 시간 포맷팅 함수 (초 단위 -> h m s)
  String _formatTime(double totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final double seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds.toStringAsFixed(2)}s';
    } else {
      return '${minutes}m ${seconds.toStringAsFixed(2)}s';
    }
  }

  /// 캘린더 리스트 빌더 (미리보기 지원)
  Widget _buildRaceList(
    BuildContext context,
    List<RaceInfo> raceList, {
    required bool isPreview,
  }) {
    if (raceList.isEmpty) {
      return const Center(child: Text('시즌 캘린더 정보가 없습니다.'));
    }

    // 미리보기 모드일 때 최대 3개까지만 표시
    final int itemCount = isPreview
        ? (raceList.length > 3 ? 3 : raceList.length)
        : raceList.length;
    // 3개 초과 시 '...' 아이콘 표시 여부
    final bool showEllipsis = isPreview && raceList.length > 3;

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final race = raceList[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                title: Text(race.name),
                subtitle: Text('라운드 ${race.round}'),
              ),
            );
          },
        ),
        // 미리보기 상태에서 항목이 더 있을 경우 '...' 아이콘 표시
        if (showEllipsis)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Icon(Icons.more_horiz, color: Colors.grey),
          ),
      ],
    );
  }

  /// 리포트 리스트 빌더 (미리보기 지원)
  Widget _buildReportList(
    BuildContext context,
    WidgetRef ref,
    List<SimulationResponse> reports, {
    required bool isPreview,
  }) {
    if (reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('아직 저장된 리포트가 없습니다.\n시뮬레이터를 실행해 보세요!')),
      );
    }

    // 미리보기 모드일 때 최대 3개까지만 표시
    final int itemCount = isPreview
        ? (reports.length > 3 ? 3 : reports.length)
        : reports.length;
    final bool showEllipsis = isPreview && reports.length > 3;

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final report = reports[index];
            final StrategyResult actual = report.actual;

            // 리포트 번호 계산
            final int reportNumber = reports.length - index;
            final totalTime = actual.totalTime;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                title: Text('리포트 #$reportNumber'),
                subtitle: Text(
                  '기록: ${_formatTime(totalTime)}\n'
                  '저장일: ${DateFormat.yMd().add_jm().format(DateTime.now())}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                isThreeLine: true,
                onTap: () {
                  ref.read(simulationResultProvider.notifier).state = report;
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
        // 미리보기 상태에서 항목이 더 있을 경우 '...' 아이콘 표시
        if (showEllipsis)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Icon(Icons.more_horiz, color: Colors.grey),
          ),
      ],
    );
  }
}
