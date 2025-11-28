class TireStint {
  final String compound;
  final int startLap;
  final int endLap;

  TireStint({
    required this.compound,
    required this.startLap,
    required this.endLap,
  });

  factory TireStint.fromJson(Map<String, dynamic> json) {
    return TireStint(
      compound: json['compound'] ?? 'UNKNOWN',
      startLap: json['startLap'] ?? 0,
      endLap: json['endLap'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'compound': compound, 'startLap': startLap, 'endLap': endLap};
  }
}
