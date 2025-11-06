import 'package:frontend/models/race_event.dart';
import 'package:frontend/models/strategy_result.dart';
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 분석 리포트 - '상세 랩 차트' 탭
class DetailedLapChartTab extends ConsumerWidget {
  const DetailedLapChartTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(simulationResultProvider);
    if (result == null) {
      return const Center(child: Text('No simulation data.'));
    }

    final actual = result.actual;
    final optimal = result.optimal;
    final scenarios = result.scenarios;
    
    // 실제 피트 스톱 및 레이스 이벤트 데이터
    final actualPitLaps = actual.pitLaps; 
    final raceEvents = result.raceEvents;

    // 차트에 표시할 모든 랩 타임 데이터
    final allLineBars = [
      _buildLineBar(actual, Colors.blue, 3), // 실제 (파란색, 굵게)
      _buildLineBar(optimal, Colors.green),  // 최적 (녹색)
      ...scenarios.map((s) => _buildLineBar(s, Colors.grey.withValues(alpha: 128))),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          // 레이스 이벤트 (SC/VSC) 음영 처리
          rangeAnnotations: RangeAnnotations(
            verticalRangeAnnotations: _buildRaceEventAnnotations(raceEvents),
          ),
          
          // 실제 피트 스톱 아이콘(라인)
          extraLinesData: ExtraLinesData(
            verticalLines: _buildPitStopLines(actualPitLaps),
          ),
          
          lineBarsData: allLineBars,
          titlesData: _buildTitlesData(),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
          
          // 차트 인터랙션 (툴팁 등)
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(

              // 1. 툴팁 배경색 (API: 'getTooltipColor' 사용)
              getTooltipColor: (LineBarSpot touchedSpot) {
                // 함수(콜백) 형태로 색상을 반환합니다.
                return Colors.blueGrey.withValues(alpha: 204); // 255 * 0.8
              },
              
              // 2. 툴팁 모서리 둥글기 (API: 'tooltipBorderRadius' 사용)
              tooltipBorderRadius: BorderRadius.circular(4.0),

              // 3. 툴팁 텍스트 내용 및 스타일 설정
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  
                  // 텍스트 스타일
                  final textStyle = TextStyle(
                    color: touchedSpot.bar.color ?? Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  );
                  
                  return LineTooltipItem(
                    '${touchedSpot.x.toInt()} Lap\n${touchedSpot.y} s', // 툴팁 텍스트
                    textStyle,
                    textAlign: TextAlign.left,
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 랩 타임 데이터를 LineChartBarData로 변환
  LineChartBarData _buildLineBar(StrategyResult strategy, Color color,
      [double width = 2]) {
    return LineChartBarData(
      spots: strategy.lapTimes.asMap().entries.map((entry) {
        // X축: 랩 (1부터 시작), Y축: 랩 타임
        return FlSpot((entry.key + 1).toDouble(), entry.value);
      }).toList(),
      color: color,
      barWidth: width,
      isCurved: false,
      dotData: const FlDotData(show: false), // 점 숨기기
    );
  }

  /// RaceEvent 목록을 VerticalRangeAnnotation 목록으로 변환
  List<VerticalRangeAnnotation> _buildRaceEventAnnotations(
      List<RaceEvent> events) {
    return events.map((event) {
      Color eventColor;
      switch (event.type) {
        case 'SC':
          eventColor = Colors.yellow.withValues(alpha: 77); 
          break;
        case 'VSC':
          eventColor = Colors.yellow.withValues(alpha: 51); 
          break;
        case 'RedFlag':
          eventColor = Colors.red.withValues(alpha: 77); 
          break;
        default:
          eventColor = Colors.grey.withValues(alpha: 51); 
      }

      return VerticalRangeAnnotation(
        x1: event.startLap.toDouble(),
        x2: event.endLap.toDouble(),
        color: eventColor,
      );
    }).toList();
  }

  /// 실제 피트 스톱 랩을 VerticalLineAnnotation 목록으로 변환
  List<VerticalLine> _buildPitStopLines(List<int> pitLaps) {
    return pitLaps.map((lap) {
      return VerticalLine(
        x: lap.toDouble(),
        color: Colors.redAccent,
        strokeWidth: 2,
        dashArray: [4, 4], // 점선
        label: VerticalLineLabel(
          show: true,
          labelResolver: (_) => 'P', // 'P' 아이콘
          alignment: Alignment.topRight,
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white,
          ),
        ),
      );
    }).toList();
  }

  /// X/Y축 레이블 설정
  FlTitlesData _buildTitlesData() {
    return const FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 5),
        axisNameWidget: Text('Lap'),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
        axisNameWidget: Text('Lap Time (s)'),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}