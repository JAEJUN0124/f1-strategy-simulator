class RaceInfo {
  final String raceId;
  final String name;
  final int round;

  RaceInfo({
    required this.raceId,
    required this.name,
    required this.round,
  });

  // JSON 파싱을 위한 fromJson 팩토리 생성자
  factory RaceInfo.fromJson(Map<String, dynamic> json) {
    return RaceInfo(
      raceId: json['raceId'] ?? '',
      name: json['name'] ?? 'Unknown Race',
      round: json['round'] ?? 0,
    );
  }
}