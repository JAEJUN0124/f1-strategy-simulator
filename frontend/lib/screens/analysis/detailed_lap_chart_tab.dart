import 'package:frontend/models/strategy_result.dart';
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailedLapChartTab extends ConsumerWidget {
  const DetailedLapChartTab({super.key});

  static const Color softColor = Color(0xFFFF3B30);
  static const Color mediumColor = Color(0xFFFFCC00);
  static const Color hardColor = Color(0xFFFFFFFF);
  static const Color hardColorDisplay = Color(0xFF9E9E9E);

  Color _getTireColor(String compound) {
    switch (compound.toUpperCase()) {
      case 'SOFT':
        return softColor;
      case 'MEDIUM':
        return mediumColor;
      case 'HARD':
        return hardColorDisplay;
      case 'INTERMEDIATE':
        return Colors.green;
      case 'WET':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(simulationResultProvider);
    if (result == null) return const Center(child: Text('No data'));

    final actual = result.actual;
    final optimal = result.optimal;

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

    final double padding = (maxY - minY) * 0.1;
    minY -= padding;
    maxY += padding;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(softColor, "Soft"),
                  _buildLegendItem(mediumColor, "Medium"),
                  _buildLegendItem(hardColorDisplay, "Hard"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLineStyleLegend(false, "실제 기록 (실선)"), // (수정) 한글로 변경
              const SizedBox(width: 16),
              _buildLineStyleLegend(true, "최적 전략 (점선)"), // (수정) 한글로 변경
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
                    tooltipBorder: BorderSide(color: Colors.grey.shade300),
                    getTooltipItems: (spots) {
                      return spots.map((barSpot) {
                        final isActual = barSpot.barIndex == 0;
                        return LineTooltipItem(
                          '${isActual ? "실제" : "최적"}: ${barSpot.y.toStringAsFixed(2)}s', // (수정) 한글로 변경
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
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),

                lineBarsData: [
                  _buildColoredLineBar(actual, isDashed: false, opacity: 1.0),
                  _buildColoredLineBar(optimal, isDashed: true, opacity: 0.6),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildLineStyleLegend(bool isDashed, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 2,
          color: Colors.black54,
          child: isDashed
              ? const Center(
                  child: Text("- - -", style: TextStyle(fontSize: 6)),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  LineChartBarData _buildColoredLineBar(
    StrategyResult strategy, {
    required bool isDashed,
    required double opacity,
  }) {
    final List<Color> colors = [];
    final List<double> stops = [];
    final totalLaps = strategy.lapTimes.length.toDouble();

    if (strategy.tireStints.isEmpty) {
      return LineChartBarData(
        spots: strategy.lapTimes
            .asMap()
            .entries
            .map((e) => FlSpot((e.key + 1).toDouble(), e.value))
            .toList(),
        color: Colors.black.withOpacity(opacity),
        barWidth: 2,
        isCurved: true,
        dotData: const FlDotData(show: false),
        dashArray: isDashed ? [5, 5] : null,
      );
    }

    for (var stint in strategy.tireStints) {
      final color = _getTireColor(stint.compound).withOpacity(opacity);
      final startStop = (stint.startLap - 1) / totalLaps;
      final endStop = stint.endLap / totalLaps;
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
      gradient: LinearGradient(colors: colors, stops: stops),
      barWidth: 3,
      isCurved: true,
      dotData: const FlDotData(show: false),
      dashArray: isDashed ? [5, 5] : null,
    );
  }
}
