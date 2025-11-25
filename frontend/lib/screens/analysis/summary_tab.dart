import 'package:frontend/models/strategy_result.dart';
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:frontend/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryTab extends ConsumerWidget {
  const SummaryTab({super.key});

  String _formatTime(double totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final double seconds = totalSeconds % 60;
    if (hours > 0)
      return '${hours}h ${minutes}m ${seconds.toStringAsFixed(1)}s';
    return '${minutes}m ${seconds.toStringAsFixed(2)}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(simulationResultProvider);
    if (result == null) return const Center(child: Text('No data'));

    final actual = result.actual;
    final optimal = result.optimal;
    final scenarios = result.scenarios;

    final List<StrategyResult> allStrategies = [
      actual,
      if (actual.name != optimal.name) optimal,
      ...scenarios.where(
        (s) => s.name != optimal.name && s.name != actual.name,
      ),
    ];

    // 최적 전략이 실제보다 얼마나 빠른지 계산
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
              // (수정) 텍스트 변경: 'AI 최적 전략' -> '최적 전략'
              title: '최적 전략',
              value: _formatTime(optimal.totalTime),
              // (수정) 색상 복구: 테마색(빨강) -> 초록색
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
      final isOptimal = strategy.name == optimal.name;
      final isActual = index == 0;

      Color barColor;
      if (isOptimal) {
        // (수정) 그래프 색상 복구: 빨간색 -> 초록색
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

    String text = strategies[index].name;
    if (text == "Actual") text = "실제";
    if (text == "Optimal") text = "최적";

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
