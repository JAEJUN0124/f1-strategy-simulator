import 'tire_stint.dart';

class StrategyResult {
  final String name;
  final double totalTime;
  final List<int> pitLaps;
  final List<double> lapTimes;
  final List<TireStint> tireStints;

  StrategyResult({
    required this.name,
    required this.totalTime,
    required this.pitLaps,
    required this.lapTimes,
    required this.tireStints,
  });

  factory StrategyResult.fromJson(Map<String, dynamic> json) {
    return StrategyResult(
      name: json['name'] ?? 'N/A',
      totalTime: (json['totalTime'] ?? 0.0).toDouble(),
      pitLaps: List<int>.from(json['pitLaps'] ?? []),

      // lapTimes 파싱
      lapTimes: List<double>.from(
        (json['lapTimes'] ?? []).map((e) => e.toDouble()),
      ),

      // tireStints 파싱 (Null 처리 및 리스트 변환)
      tireStints: (json['tireStints'] as List<dynamic>? ?? [])
          .map((e) => TireStint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'totalTime': totalTime,
      'pitLaps': pitLaps,
      'lapTimes': lapTimes,
      'tireStints': tireStints.map((e) => e.toJson()).toList(),
    };
  }
}
