// frontend/lib/models/simulation_request.dart

// API 요청 시 사용할 모델 (JSON 직렬화)

class StintRequest {
  final String compound;
  final int? startLap;
  final int? endLap;

  StintRequest({
    required this.compound,
    this.startLap,
    this.endLap,
  });

  Map<String, dynamic> toJson() {
    return {
      'compound': compound,
      'startLap': startLap,
      'endLap': endLap,
    };
  }
}

class Scenario {
  final String name;
  final List<StintRequest> stints;

  Scenario({required this.name, required this.stints});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'stints': stints.map((e) => e.toJson()).toList(),
    };
  }
}

class SimulationRequest {
  final int year;
  final String raceId;
  final String driverId;
  final double pitLossSeconds;
  final List<Scenario> scenarios;

  SimulationRequest({
    required this.year,
    required this.raceId,
    required this.driverId,
    required this.pitLossSeconds,
    required this.scenarios,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'raceId': raceId,
      'driverId': driverId,
      'pitLossSeconds': pitLossSeconds,
      'scenarios': scenarios.map((e) => e.toJson()).toList(),
    };
  }
}