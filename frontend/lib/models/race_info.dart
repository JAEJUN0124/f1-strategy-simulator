class RaceInfo {
  final String raceId;
  final String name;
  final int round;

  // 상세 정보
  final String date;
  final String location;
  final String officialName;

  RaceInfo({
    required this.raceId,
    required this.name,
    required this.round,
    required this.date,
    required this.location,
    required this.officialName,
  });

  // JSON 파싱을 위한 fromJson 팩토리 생성자
  factory RaceInfo.fromJson(Map<String, dynamic> json) {
    return RaceInfo(
      raceId: json['raceId'] ?? '',
      name: json['name'] ?? 'Unknown Race',
      round: json['round'] ?? 0,
      date: json['date'] ?? '',
      location: json['location'] ?? 'Unknown Location',
      officialName: json['officialName'] ?? '',
    );
  }
}
