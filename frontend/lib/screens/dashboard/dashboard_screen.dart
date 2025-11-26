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

    final int currentYear = DateTime.now().year;
    final int maxYear = currentYear < 2025 ? 2025 : currentYear;
    final int minYear = 2016;

    final List<int> yearList = List.generate(
      maxYear - minYear + 1,
      (index) => maxYear - index,
    );

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        races.when(
          loading: () =>
              _buildLoadingSection(context, selectedYear, yearList, ref),
          error: (err, stack) =>
              _buildErrorSection(context, err, selectedYear, yearList, ref),
          data: (raceList) {
            return CollapsibleSection(
              title: '시즌 캘린더',
              icon: Icons.calendar_month_rounded,
              initialIsExpanded: false,
              action: _buildYearDropdown(context, selectedYear, yearList, ref),
              previewChild: _buildRaceList(context, raceList, isPreview: true),
              child: _buildRaceList(context, raceList, isPreview: false),
            );
          },
        ),

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
      initialIsExpanded: false,
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

  // [추가] 상세 정보 보기 (바텀 시트)
  void _showRaceDetails(BuildContext context, RaceInfo race) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // 날짜 포맷팅 (예: 2024-03-02T15:00:00 -> 2024년 3월 2일 15:00)
        DateTime? eventDate;
        try {
          eventDate = DateTime.parse(race.date);
        } catch (e) {
          eventDate = null;
        }

        final formattedDate = eventDate != null
            ? DateFormat('yyyy년 M월 d일 HH:mm').format(eventDate)
            : race.date;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 드래그 핸들
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 공식 대회명 (제목)
              Text(
                race.officialName.isNotEmpty ? race.officialName : race.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),

              // 상세 정보 아이템들
              _buildDetailRow(Icons.calendar_today, "일시", formattedDate),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.location_on_outlined, "개최지", race.location),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.flag_outlined,
                "라운드",
                "Round ${race.round}",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.black54),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
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
                // [추가] 탭 이벤트 연결
                onTap: () => _showRaceDetails(context, race),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                // [추가] 더보기 아이콘 표시 (클릭 가능함 암시)
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.grey.shade400,
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
