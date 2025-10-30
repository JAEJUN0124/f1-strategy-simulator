// (v2).txt 3.2, 1.3 (RaceInfo 모델)
class RaceInfo {
  final String raceId;
  final String name;
  final int round;

  RaceInfo({
    required this.raceId,
    required this.name,
    required this.round,
  });

  // (v2).txt 3.2 - fromJson 팩토리 생성자
  factory RaceInfo.fromJson(Map<String, dynamic> json) {
    return RaceInfo(
      raceId: json['raceId'],
      name: json['name'],
      round: json['round'],
    );
  }
}