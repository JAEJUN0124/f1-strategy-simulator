import 'package:frontend/models/strategy_result.dart';
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:frontend/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // intl 임포트
import 'package:fl_chart/fl_chart.dart'; // fl_chart 임포트

/// 분석 리포트 - '요약' 탭
class SummaryTab extends ConsumerWidget {
  const SummaryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(simulationResultProvider);
    if (result == null) {
      return const Center(child: Text('No simulation data.'));
    }

    final actual = result.actual;
    final optimal = result.optimal;
    final scenarios = result.scenarios;

    // 바 차트에 표시할 모든 전략 (Actual, Optimal, Scenarios)
    final allStrategies = [actual, optimal, ...scenarios];

    // 시간 포맷터
    final timeFormatter = NumberFormat('0.000');

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // StatCard (실제 vs 최적)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          children: [
            StatCard(
              title: 'Actual Total Time',
              value: '${timeFormatter.format(actual.totalTime)} s',
            ),
            StatCard(
              title: 'Optimal Total Time',
              value: '${timeFormatter.format(optimal.totalTime)} s',
              color: Colors.green[700],
            ),
            StatCard(
              title: 'Actual Pit Stops',
              value: actual.pitLaps.length.toString(),
            ),
            StatCard(
              title: 'Optimal Pit Stops',
              value: optimal.pitLaps.length.toString(),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // BarChart (전략 비교)
        Text(
          'Strategy Comparison (Total Time)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: _buildBarGroups(allStrategies, optimal),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        _bottomTitles(value, meta, allStrategies),
                    reservedSize: 38,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) =>
                        _leftTitles(value, meta, allStrategies),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),
      ],
    );
  }

  // --- BarChart 헬퍼 함수 ---

  List<BarChartGroupData> _buildBarGroups(
      List<StrategyResult> strategies, StrategyResult optimal) {
    return strategies.asMap().entries.map((entry) {
      final index = entry.key;
      final strategy = entry.value;
      final isOptimal = strategy.name == optimal.name;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: strategy.totalTime,
            color: isOptimal ? Colors.green : Colors.blueGrey,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  Widget _bottomTitles(
      double value, TitleMeta meta, List<StrategyResult> strategies) {
    final index = value.toInt();
    if (index < 0 || index >= strategies.length) return const SizedBox();

    final text = strategies[index].name;
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _leftTitles(
      double value, TitleMeta meta, List<StrategyResult> strategies) {
    // 가장 느린 시간(max)과 빠른 시간(min)을 기준으로 Y축 레이블 생성
    final minTime = strategies
        .map((e) => e.totalTime)
        .reduce((a, b) => a < b ? a : b);
    
    // Y축은 0부터 시작하지 않고 최소값 기준으로 표시
    if (value == minTime) {
      return Text(NumberFormat('0,000').format(value), style: const TextStyle(fontSize: 10));
    }
    if (value == meta.max) {
       return Text(NumberFormat('0,000').format(value), style: const TextStyle(fontSize: 10));
    }
    return const SizedBox();
  }
}