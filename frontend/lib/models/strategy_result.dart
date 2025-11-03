class StrategyResult {
  final String name;
  final double totalTime;
  final List<int> pitLaps;
  final List<double> lapTimes;

  StrategyResult({
    required this.name,
    required this.totalTime,
    required this.pitLaps,
    required this.lapTimes,
  });

  factory StrategyResult.fromJson(Map<String, dynamic> json) {
    return StrategyResult(
      name: json['name'] ?? 'N/A',
      totalTime: (json['totalTime'] ?? 0.0).toDouble(),
      pitLaps: List<int>.from(json['pitLaps'] ?? []),
      lapTimes: List<double>.from(
          (json['lapTimes'] ?? []).map((e) => e.toDouble())),
    );
  }
}