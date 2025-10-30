// (v2).txt 3.2, 1.3 (시뮬레이션 관련 모델)

// --- 요청(Request) 모델 ---

// (v2).txt 1.3 - StintRequest 모델 (Dart용)
// API 요청 시 JSON 직렬화를 위해 toJson 메서드를 추가합니다.
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

// (v2).txt 1.3 - Scenario 모델 (Dart용)
class Scenario {
  final String name;
  final List<StintRequest> stints;

  Scenario({
    required this.name,
    required this.stints,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'stints': stints.map((stint) => stint.toJson()).toList(),
    };
  }
}

// (v2).txt 1.3 - SimulationRequest 모델 (Dart용)
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
      'scenarios': scenarios.map((scenario) => scenario.toJson()).toList(),
    };
  }
}


// --- 응답(Response) 모델 ---

// (v2).txt 1.3 - StrategyResult 모델
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
      name: json['name'],
      totalTime: (json['totalTime'] as num).toDouble(),
      pitLaps: List<int>.from(json['pitLaps']),
      lapTimes: List<double>.from(json['lapTimes'].map((e) => (e as num).toDouble())),
    );
  }
}

// (v2).txt 1.3 - Results 모델
class Results {
  final StrategyResult actual;
  final StrategyResult optimal;
  final List<StrategyResult> scenarios;

  Results({
    required this.actual,
    required this.optimal,
    required this.scenarios,
  });

  factory Results.fromJson(Map<String, dynamic> json) {
    return Results(
      actual: StrategyResult.fromJson(json['actual']),
      optimal: StrategyResult.fromJson(json['optimal']),
      scenarios: List<StrategyResult>.from(
        json['scenarios'].map((x) => StrategyResult.fromJson(x)),
      ),
    );
  }
}

// (v2).txt 1.3 - SimulationResponse 모델
class SimulationResponse {
  final String reportId;
  final Results results;

  SimulationResponse({
    required this.reportId,
    required this.results,
  });

  factory SimulationResponse.fromJson(Map<String, dynamic> json) {
    return SimulationResponse(
      reportId: json['reportId'],
      results: Results.fromJson(json['results']),
    );
  }
}