class RaceEvent {
  final String type; // 'SC', 'VSC', 'RedFlag'
  final int startLap;
  final int endLap;

  RaceEvent({
    required this.type,
    required this.startLap,
    required this.endLap,
  });

  factory RaceEvent.fromJson(Map<String, dynamic> json) {
    return RaceEvent(
      type: json['type'] ?? 'UNKNOWN',
      startLap: json['startLap'] ?? 0,
      endLap: json['endLap'] ?? 0,
    );
  }

  // 로컬 저장을 위한 toJson 메서드
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'startLap': startLap,
      'endLap': endLap,
    };
  }
}