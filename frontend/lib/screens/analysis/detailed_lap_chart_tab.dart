import 'package:frontend/models/strategy_result.dart';
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailedLapChartTab extends ConsumerWidget {
  const DetailedLapChartTab({super.key});

  // 타이어별 색상 정의
  static const Color softColor = Color(0xFFFF3B30); // Red
  static const Color mediumColor = Color(0xFFFFCC00); // Yellow
  static const Color hardColor = Colors.grey; // Hard
  static const Color interColor = Colors.green;
  static const Color wetColor = Colors.blue;

  Color _getTireColor(String compound) {
    switch (compound.toUpperCase()) {
      case 'SOFT':
        return softColor;
      case 'MEDIUM':
        return mediumColor;
      case 'HARD':
        return hardColor;
      case 'INTERMEDIATE':
        return interColor;
      case 'WET':
        return wetColor;
      default:
        return Colors.black;
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

    // Y축 범위 자동 계산
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    void updateMinMax(List<double> times) {
      if (times.isEmpty) return;
      for (var t in times) {
        if (t < minY) minY = t;
        if (t > maxY) maxY = t;
      }
    }

    updateMinMax(actual.lapTimes);
    updateMinMax(optimal.lapTimes);

    // 그래프 여백 확보
    final double padding = (maxY - minY) * 0.1;
    if (padding == 0) {
      minY -= 1;
      maxY += 1;
    } else {
      minY -= padding;
      maxY += padding;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "랩 타임 상세 비교 (타이어별)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "실선: 실제 기록 / 점선: 시뮬레이션(최적)",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          // 범례
          Row(
            children: [
              _buildLegendItem(softColor, "Soft"),
              const SizedBox(width: 12),
              _buildLegendItem(mediumColor, "Medium"),
              const SizedBox(width: 12),
              _buildLegendItem(hardColor, "Hard"),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => Colors.white,
                    tooltipBorder: const BorderSide(color: Colors.grey),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        // 툴팁에서 어떤 라인인지 구분 표시
                        final isActual = barSpot.barIndex == 0;
                        final label = isActual ? "실제" : "최적";
                        return LineTooltipItem(
                          '$label: ${barSpot.y.toStringAsFixed(2)} s',
                          TextStyle(
                            color:
                                barSpot.bar.gradient?.colors.first ??
                                barSpot.bar.color,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (val, meta) => Text(
                        val.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (maxY - minY) / 5,
                      getTitlesWidget: (val, meta) => Text(
                        val.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade200),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),

                lineBarsData: [
                  // 1. 실제 기록 (실선, 타이어 색상 적용)
                  _buildColoredLineBar(actual, isDashed: false, opacity: 1.0),

                  // 2. 최적 기록 (점선, 타이어 색상 적용, 약간 투명하게)
                  // 이제 최적 전략도 타이어 정보(tireStints)를 기반으로 색상이 입혀집니다.
                  _buildColoredLineBar(optimal, isDashed: true, opacity: 0.7),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // 타이어 스틴트에 따라 그라데이션 라인 생성
  LineChartBarData _buildColoredLineBar(
    StrategyResult strategy, {
    required bool isDashed,
    required double opacity,
  }) {
    final List<Color> colors = [];
    final List<double> stops = [];

    final totalLaps = strategy.lapTimes.length.toDouble();

    // 데이터가 없거나 타이어 정보가 없는 경우 기본 검정색 처리
    if (strategy.tireStints.isEmpty) {
      return LineChartBarData(
        spots: strategy.lapTimes
            .asMap()
            .entries
            .map((e) => FlSpot((e.key + 1).toDouble(), e.value))
            .toList(),
        color: Colors.black.withOpacity(opacity),
        barWidth: 3,
        isCurved: true,
        dotData: const FlDotData(show: false),
        dashArray: isDashed ? [5, 5] : null,
      );
    }

    // 그라데이션 정지점 생성 로직
    for (var stint in strategy.tireStints) {
      final color = _getTireColor(stint.compound).withOpacity(opacity);

      // X축 비율 계산 (0.0 ~ 1.0)
      final startStop = (stint.startLap - 1) / totalLaps;
      final endStop = stint.endLap / totalLaps;

      // 색상이 섞이지 않고 딱 끊어지도록 같은 위치에 점 두 개 추가
      colors.add(color);
      stops.add(startStop);
      colors.add(color);
      stops.add(endStop);
    }

    return LineChartBarData(
      spots: strategy.lapTimes
          .asMap()
          .entries
          .map((e) => FlSpot((e.key + 1).toDouble(), e.value))
          .toList(),
      // gradient 적용
      gradient: LinearGradient(
        colors: colors,
        stops: stops,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      barWidth: 3,
      isCurved: true,
      dotData: const FlDotData(show: false),
      dashArray: isDashed ? [5, 5] : null, // 점선 옵션
    );
  }
}
