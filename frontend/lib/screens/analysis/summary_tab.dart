import 'package:frontend/models/strategy_result.dart';
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:frontend/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryTab extends ConsumerWidget {
  const SummaryTab({super.key});

  // 시간 포맷팅 헬퍼 함수
  String _formatTime(double totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final double seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds.toStringAsFixed(1)}s';
    }
    return '${minutes}m ${seconds.toStringAsFixed(2)}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(simulationResultProvider);
    if (result == null) return const Center(child: Text('No data'));

    final actual = result.actual;
    final optimal = result.optimal;

    // 중복 제거 로직 적용 (Optimal 이름 중복 방지)
    final customScenarios = result.scenarios.where((s) {
      return s.name != 'Optimal' && s.name != 'Actual';
    }).toList();

    final List<StrategyResult> allStrategies = [
      actual,
      optimal,
      ...customScenarios,
    ];

    final double diff = actual.totalTime - optimal.totalTime;
    final String diffText = diff > 0
        ? "-${diff.toStringAsFixed(2)}초 (단축)"
        : "+${diff.abs().toStringAsFixed(2)}초 (지연)";
    final Color diffColor = diff > 0 ? Colors.green : Colors.red;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 1. 핵심 요약 카드
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          mainAxisSpacing: 12.0,
          crossAxisSpacing: 12.0,
          children: [
            StatCard(title: '나의 기록', value: _formatTime(actual.totalTime)),
            StatCard(
              title: '최적 전략',
              value: _formatTime(optimal.totalTime),
              color: Colors.green,
            ),
            StatCard(title: '시간 차이', value: diffText, color: diffColor),
            StatCard(title: '최적 피트 스톱', value: '${optimal.pitLaps.length}회'),
          ],
        ),

        const SizedBox(height: 32),

        // 2. 차트 섹션
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '전략별 총 시간 비교',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      // [수정] 툴팁 커스터마이징 추가
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) =>
                              Colors.blueGrey.shade800, // 툴팁 배경색
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            // rod.toY는 초 단위 시간
                            return BarTooltipItem(
                              _formatTime(rod.toY), // 포맷팅된 시간 문자열 사용
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                      ),
                      barGroups: _buildBarGroups(
                        context,
                        allStrategies,
                        optimal,
                      ),
                      minY: _calculateMinY(allStrategies),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) =>
                                _bottomTitles(value, meta, allStrategies),
                            reservedSize: 40,
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
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _calculateMinY(List<StrategyResult> strategies) {
    if (strategies.isEmpty) return 0;
    final minVal = strategies
        .map((e) => e.totalTime)
        .reduce((a, b) => a < b ? a : b);
    return (minVal - 15).floorToDouble();
  }

  List<BarChartGroupData> _buildBarGroups(
    BuildContext context,
    List<StrategyResult> strategies,
    StrategyResult optimal,
  ) {
    return strategies.asMap().entries.map((entry) {
      final index = entry.key;
      final strategy = entry.value;
      // 이름으로 비교하거나 인덱스로 비교 (여기서는 인덱스 1이 최적)
      final isOptimal = index == 1;
      final isActual = index == 0;

      Color barColor;
      if (isOptimal) {
        barColor = Colors.green;
      } else if (isActual) {
        barColor = Colors.grey.shade800;
      } else {
        barColor = Colors.grey.shade300;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: strategy.totalTime,
            color: barColor,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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

    // 인덱스 기반으로 이름 매핑
    String text = strategies[index].name;
    if (index == 0)
      text = "실제";
    else if (index == 1)
      text = "최적";

    // 시나리오 이름이 너무 길 경우 처리 (선택 사항)
    if (text.length > 8) {
      text = text.substring(0, 8) + "..";
    }

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}
