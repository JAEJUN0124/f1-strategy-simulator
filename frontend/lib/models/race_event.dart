// frontend/lib/models/race_event.dart

// (v4) 3.2. RaceEvent Dart 클래스 [cite: 420]
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
}