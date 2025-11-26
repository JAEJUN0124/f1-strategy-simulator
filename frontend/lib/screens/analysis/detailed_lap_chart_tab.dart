import 'package:frontend/models/strategy_result.dart';
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// [중요] 클래스 이름이 DetailedLapChartTab 이어야 합니다. (SummaryTab이 아니어야 함)
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

  /// 전략 인덱스에 따라 점선 패턴을 다르게 반환하는 헬퍼 함수
  List<int>? _getDashArray(int index) {
    if (index == 0) return null; // 실제: 실선
    if (index == 1) return [5, 5]; // 최적: 보통 점선

    // 사용자 시나리오들을 위한 패턴 목록
    const customPatterns = [
      [2, 2], // 시나리오 2: 촘촘한 점선
      [10, 5], // 시나리오 3: 긴 점선
      [2, 5, 10, 5], // 시나리오 4: 점-대시 혼합
    ];

    // Custom Scenarios는 index 2부터 시작하므로 -2
    final patternIndex = (index - 2) % customPatterns.length;
    return customPatterns[patternIndex];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(simulationResultProvider);
    if (result == null) return const Center(child: Text('No data'));

    final actual = result.actual;
    final optimal = result.optimal;

    // 중복 제거 로직: 이름이 Optimal이나 Actual인 시나리오는 제외
    final customScenarios = result.scenarios.where((s) {
      return s.name != 'Optimal' && s.name != 'Actual';
    }).toList();

    // 모든 전략 리스트 결합
    final allStrategies = [actual, optimal, ...customScenarios];

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    void updateMinMax(List<double> times) {
      if (times.isEmpty) return;
      for (var t in times) {
        if (t < minY) minY = t;
        if (t > maxY) maxY = t;
      }
    }

    for (var strategy in allStrategies) {
      updateMinMax(strategy.lapTimes);
    }

    // 차트 Y축 여백 확보
    final double padding = (maxY - minY) * 0.1;
    minY -= padding;
    maxY += padding;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 1. 타이어 색상 범례
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
          const SizedBox(height: 12),

          // 2. 라인 스타일 범례 (시나리오별 이름 표시)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12.0,
            runSpacing: 8.0,
            children: [
              // 고정: 실제, 최적
              _buildLineStyleLegend(_getDashArray(0), "실제"),
              _buildLineStyleLegend(_getDashArray(1), "최적"),

              // 동적: 사용자 정의 시나리오들
              ...customScenarios.asMap().entries.map((entry) {
                final index = entry.key;
                final scenario = entry.value;
                // 전체 전략 리스트에서의 인덱스는 2 + index
                return _buildLineStyleLegend(
                  _getDashArray(2 + index),
                  scenario.name,
                );
              }),
            ],
          ),
          const SizedBox(height: 24),

          // 3. 차트
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
                        final index = barSpot.barIndex;
                        String name = "";
                        if (index == 0) {
                          name = "실제";
                        } else if (index == 1) {
                          name = "최적";
                        } else {
                          // customScenarios 인덱스 매핑
                          final scenarioIndex = index - 2;
                          if (scenarioIndex < customScenarios.length) {
                            name = customScenarios[scenarioIndex].name;
                          }
                        }

                        return LineTooltipItem(
                          '$name: ${barSpot.y.toStringAsFixed(2)}s',
                          TextStyle(
                            color:
                                barSpot.bar.gradient?.colors.first ??
                                barSpot.bar.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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

                // 모든 전략을 차트에 반영
                lineBarsData: allStrategies.asMap().entries.map((entry) {
                  final index = entry.key;
                  final strategy = entry.value;

                  double opacity = (index < 2) ? 1.0 : 0.7;

                  return _buildColoredLineBar(
                    strategy,
                    dashArray: _getDashArray(index),
                    opacity: opacity,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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

  Widget _buildLineStyleLegend(List<int>? dashArray, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 12,
          color: Colors.transparent,
          child: CustomPaint(painter: _LineStylePainter(dashArray: dashArray)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  LineChartBarData _buildColoredLineBar(
    StrategyResult strategy, {
    required List<int>? dashArray,
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
        dashArray: dashArray,
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
      dashArray: dashArray,
    );
  }
}

class _LineStylePainter extends CustomPainter {
  final List<int>? dashArray;

  _LineStylePainter({this.dashArray});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double y = size.height / 2;

    if (dashArray == null) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    } else {
      double startX = 0;
      int index = 0;
      while (startX < size.width) {
        final double dashWidth = dashArray![index % dashArray!.length]
            .toDouble();
        final double gapWidth = dashArray![(index + 1) % dashArray!.length]
            .toDouble();

        final double endX = (startX + dashWidth > size.width)
            ? size.width
            : startX + dashWidth;

        canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);

        startX += dashWidth + gapWidth;
        index += 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
