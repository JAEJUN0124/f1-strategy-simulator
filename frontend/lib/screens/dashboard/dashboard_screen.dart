import 'package:frontend/models/race_info.dart';
import 'package:frontend/models/simulation_response.dart';
import 'package:frontend/providers/data_provider.dart';
import 'package:frontend/providers/recent_reports_provider.dart';
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:frontend/screens/analysis/analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/widgets/collapsible_section.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<SimulationResponse> recentReports = ref.watch(
      recentReportsProvider,
    );
    final AsyncValue<List<RaceInfo>> races = ref.watch(dashboardRacesProvider);
    final int selectedYear = ref.watch(dashboardYearProvider);

    // [수정] 대시보드용 연도 리스트 자동 생성 로직 (2016 ~ Future)
    final int currentYear = DateTime.now().year;

    // 최소 2025년까지는 보장하고, 시간이 흘러 2026년이 되면 2026년도 포함
    final int maxYear = currentYear < 2025 ? 2025 : currentYear;
    final int minYear = 2016; // 2016년부터 시작

    // 최신 연도부터 내림차순 정렬
    final List<int> yearList = List.generate(
      maxYear - minYear + 1,
      (index) => maxYear - index,
    );

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 1. 시즌 캘린더 섹션
        races.when(
          loading: () =>
              _buildLoadingSection(context, selectedYear, yearList, ref),
          error: (err, stack) =>
              _buildErrorSection(context, err, selectedYear, yearList, ref),
          data: (raceList) {
            return CollapsibleSection(
              title: '시즌 캘린더',
              icon: Icons.calendar_month_rounded,
              // 초기 상태를 닫힘(false)으로 설정
              initialIsExpanded: false,

              // 연도 선택 드롭다운
              action: _buildYearDropdown(context, selectedYear, yearList, ref),

              previewChild: _buildRaceList(context, raceList, isPreview: true),
              child: _buildRaceList(context, raceList, isPreview: false),
            );
          },
        ),

        // 2. 최근 리포트 섹션
        CollapsibleSection(
          title: '최근 리포트',
          icon: Icons.history_rounded,
          initialIsExpanded: true,
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

  Widget _buildYearDropdown(
    BuildContext context,
    int selectedYear,
    List<int> years,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      height: 32,
      child: DropdownButton<int>(
        value: selectedYear,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, size: 18),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        items: years.map((year) {
          return DropdownMenuItem<int>(value: year, child: Text('$year'));
        }).toList(),
        onChanged: (newYear) {
          if (newYear != null) {
            ref.read(dashboardYearProvider.notifier).state = newYear;
          }
        },
      ),
    );
  }

  Widget _buildLoadingSection(
    BuildContext context,
    int year,
    List<int> years,
    WidgetRef ref,
  ) {
    return CollapsibleSection(
      title: '시즌 캘린더',
      icon: Icons.calendar_month_rounded,
      action: _buildYearDropdown(context, year, years, ref),
      initialIsExpanded: false, // 로딩 중에도 닫힘 상태 유지
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorSection(
    BuildContext context,
    Object err,
    int year,
    List<int> years,
    WidgetRef ref,
  ) {
    return CollapsibleSection(
      title: '시즌 캘린더',
      icon: Icons.calendar_month_rounded,
      action: _buildYearDropdown(context, year, years, ref),
      initialIsExpanded: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('데이터 로드 실패: $err'),
      ),
    );
  }

  String _formatTime(double totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final double seconds = totalSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m ${seconds.toStringAsFixed(1)}s';
  }

  Widget _buildRaceList(
    BuildContext context,
    List<RaceInfo> raceList, {
    required bool isPreview,
  }) {
    if (raceList.isEmpty) return const Center(child: Text('정보가 없습니다.'));

    final int itemCount = isPreview
        ? (raceList.length > 3 ? 3 : raceList.length)
        : raceList.length;

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final race = raceList[index];
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    "${race.round}",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  race.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
        if (isPreview && raceList.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              "+ ${raceList.length - 3} more races",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildReportList(
    BuildContext context,
    WidgetRef ref,
    List<SimulationResponse> reports, {
    required bool isPreview,
  }) {
    if (reports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.note_add_outlined,
                size: 40,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),
              Text(
                '저장된 리포트가 없습니다.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final int itemCount = isPreview
        ? (reports.length > 3 ? 3 : reports.length)
        : reports.length;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final report = reports[index];
        final actual = report.actual;
        final reportNumber = reports.length - index;

        return InkWell(
          onTap: () {
            ref.read(simulationResultProvider.notifier).state = report;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalysisScreen()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '리포트 #$reportNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(actual.totalTime),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.MMMd().format(DateTime.now()),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
