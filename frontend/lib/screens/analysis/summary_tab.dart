import 'package:frontend/models/strategy_result.dart';
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:frontend/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

/// 분석 리포트 - '요약' 탭
class SummaryTab extends ConsumerWidget {
  const SummaryTab({super.key});

  // 시간 포맷팅 함수 (시, 분, 초)
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(simulationResultProvider);
    if (result == null) {
      return const Center(child: Text('No simulation data.'));
    }

    final actual = result.actual;
    final optimal = result.optimal;
    final scenarios = result.scenarios;

    // 중복 제거 및 데이터 구성 로직 개선
    // scenarios 리스트에 optimal이 포함되어 있을 수 있으므로 필터링하거나,
    // 단순 명료하게 Actual과 Optimal만 비교하고, 추가 시나리오가 있다면 그 뒤에 붙임
    final List<StrategyResult> allStrategies = [
      actual,
      if (actual.name != optimal.name) optimal, // 이름이 다를 때만 추가 (혹시 모를 중복 방지)
      // scenarios에서 optimal과 이름이 같은 것은 제외하고 추가
      ...scenarios.where(
        (s) => s.name != optimal.name && s.name != actual.name,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // StatCard (시간 포맷팅 적용)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          children: [
            StatCard(
              title: '실제 총 시간', // (나의 기록)
              value: _formatTime(actual.totalTime), // 포맷 적용
            ),
            StatCard(
              title: '최적 총 시간',
              value: _formatTime(optimal.totalTime), // 포맷 적용
              color: Colors.green[700],
            ),
            StatCard(title: '실제 피트 스톱', value: '${actual.pitLaps.length} 회'),
            StatCard(title: '최적 피트 스톱', value: '${optimal.pitLaps.length} 회'),
          ],
        ),
        const SizedBox(height: 32),

        // BarChart
        Text(
          '전략별 총 시간 비교',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              // ... (기존 설정 유지)
              alignment: BarChartAlignment.spaceAround,
              barGroups: _buildBarGroups(allStrategies, optimal),
              minY: _calculateMinY(allStrategies),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        _bottomTitles(value, meta, allStrategies),
                    reservedSize: 60,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.grey.shade200, strokeWidth: 1),
              ),
              // ... (툴팁 설정 유지)
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper Functions ---

  double _calculateMinY(List<StrategyResult> strategies) {
    if (strategies.isEmpty) return 0;
    final minVal = strategies
        .map((e) => e.totalTime)
        .reduce((a, b) => a < b ? a : b);
    // 최소값에서 약간의 여유(20초)를 뺀 값을 시작점으로 설정하여 차이를 부각
    return (minVal - 20).floorToDouble();
  }

  List<BarChartGroupData> _buildBarGroups(
    List<StrategyResult> strategies,
    StrategyResult optimal,
  ) {
    return strategies.asMap().entries.map((entry) {
      final index = entry.key;
      final strategy = entry.value;
      final isOptimal = strategy.name == optimal.name;
      // 첫 번째 항목(Actual)을 '나의 기록'으로 간주하여 색상 지정
      final isActual = index == 0;

      Color barColor;
      if (isOptimal) {
        barColor = Colors.green;
      } else if (isActual) {
        barColor = Colors.grey.shade700;
      } else {
        barColor = Colors.grey.shade400;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: strategy.totalTime,
            color: barColor,
            width: 24,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(show: false),
          ),
        ],
      );
    }).toList();
  }

  Widget _bottomTitles(
    double value,
    TitleMeta meta,
    List<StrategyResult> strategies,
  ) {
    final index = value.toInt();
    if (index < 0 || index >= strategies.length) return const SizedBox();

    // 텍스트가 길 경우를 대비해 줄바꿈 처리
    String text = strategies[index].name;
    if (text == "Actual") text = "실제 경기 기록";
    if (text == "Optimal") text = "최적 전략";

    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
