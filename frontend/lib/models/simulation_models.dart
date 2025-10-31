// 시뮬레이션 API와 통신하기 위한 데이터 모델(Request 및 Response)을 정의
// Request 모델들은 API 요청 시 보낼 데이터를 JSON으로 변환하는 'toJson' 메서드를 포함
// Response 모델들은 API 응답으로 받은 JSON을 Dart 객체로 변환하는 'fromJson' 팩토리 생성자를 포함

// --- 요청(Request) 모델 ---

// 레이스 전략의 개별 '스틴트'(타이어 교체 구간)를 정의하는 모델
// API 요청 시 JSON 직렬화를 위해 toJson 메서드를 추가
class StintRequest {
  // [변수] 사용할 타이어 컴파운드 (예: "SOFT", "MEDIUM")
  final String compound;
  // [변수] 스틴트 시작 랩 (옵션)
  final int? startLap;
  // [변수] 스틴트 종료 랩 (옵션)
  final int? endLap;

  StintRequest({
    required this.compound,
    this.startLap,
    this.endLap,
  });

  // [기능] 'toJson' 메서드
  // StintRequest 객체를 API 요청을 위한 JSON(Map) 형식으로 변환
  Map<String, dynamic> toJson() {
    return {
      'compound': compound,
      'startLap': startLap,
      'endLap': endLap,
    };
  }
}

// 사용자가 정의하는 개별 전략 시나리오 모델 (예: "공격적인 2스탑")
class Scenario {
  // [변수] 시나리오 이름
  final String name;
  // [변수] 해당 시나리오를 구성하는 StintRequest 목록
  final List<StintRequest> stints;

  Scenario({
    required this.name,
    required this.stints,
  });

  // [기능] 'toJson' 메서드
  // Scenario 객체와 내부의 StintRequest 목록을 JSON(Map) 형식으로 변환
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // stints 목록의 각 StintRequest 객체에 대해 'toJson'을 호출하여 JSON 배열로 만듬
      'stints': stints.map((stint) => stint.toJson()).toList(),
    };
  }
}

// 시뮬레이션 실행 API('/api/simulate')에 보낼 최종 요청 데이터 모델
class SimulationRequest {
  // [변수] 대상 연도
  final int year;
  // [변수] 대상 레이스 ID
  final String raceId;
  // [변수] 대상 드라이버 ID
  final String driverId;
  // [변수] 피트 스탑 시 손실되는 시간 (초)
  final double pitLossSeconds;
  // [변수] 시뮬레이션할 Scenario 목록
  final List<Scenario> scenarios;

  SimulationRequest({
    required this.year,
    required this.raceId,
    required this.driverId,
    required this.pitLossSeconds,
    required this.scenarios,
  });

  // [기능] 'toJson' 메서드
  // 전체 SimulationRequest 객체를 API 요청을 위한 JSON(Map) 형식으로 변환
  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'raceId': raceId,
      'driverId': driverId,
      'pitLossSeconds': pitLossSeconds,
      // scenarios 목록의 각 Scenario 객체에 대해 'toJson'을 호출하여 JSON 배열로 만듬
      'scenarios': scenarios.map((scenario) => scenario.toJson()).toList(),
    };
  }
}


// --- 응답(Response) 모델 ---

// 단일 전략(실제, 최적, 시나리오)의 시뮬레이션 결과 모델
class StrategyResult {
  // [변수] 전략 이름 (예: "ACTUAL", "OPTIMAL", "Scenario 1")
  final String name;
  // [변수] 레이스 완료 총 시간
  final double totalTime;
  // [변수] 피트 스탑을 수행한 랩 목록
  final List<int> pitLaps;
  // [변수] 랩별 주행 시간 목록
  final List<double> lapTimes;

  StrategyResult({
    required this.name,
    required this.totalTime,
    required this.pitLaps,
    required this.lapTimes,
  });

  // [기능] 'fromJson' 팩토리 생성자
  // API 응답 JSON(Map)을 StrategyResult 객체로 변환
  factory StrategyResult.fromJson(Map<String, dynamic> json) {
    return StrategyResult(
      name: json['name'],
      totalTime: (json['totalTime'] as num).toDouble(), // JSON의 숫자 타입을 double로 변환
      pitLaps: List<int>.from(json['pitLaps']),
      lapTimes: List<double>.from(json['lapTimes'].map((e) => (e as num).toDouble())), // JSON 숫자 리스트를 double 리스트로 변환
    );
  }
}

// 'actual', 'optimal', 'scenarios' 결과를 모두 포함하는 상위 결과 모델
class Results {
  // [변수] 실제 레이스 결과
  final StrategyResult actual;
  // [변수] 계산된 최적 전략 결과
  final StrategyResult optimal;
  // [변수] 사용자가 요청한 시나리오들의 결과 목록
  final List<StrategyResult> scenarios;

  Results({
    required this.actual,
    required this.optimal,
    required this.scenarios,
  });

  // [기능] 'fromJson' 팩토리 생성자
  // JSON(Map)의 'results' 부분을 Results 객체로 변환
  factory Results.fromJson(Map<String, dynamic> json) {
    return Results(
      // 내부 StrategyResult 객체들도 'fromJson'을 호출하여 변환
      actual: StrategyResult.fromJson(json['actual']),
      optimal: StrategyResult.fromJson(json['optimal']),
      scenarios: List<StrategyResult>.from(
        json['scenarios'].map((x) => StrategyResult.fromJson(x)),
      ),
    );
  }
}

// 시뮬레이션 실행 API('/api/simulate')에서 받은 최종 응답 데이터 모델
class SimulationResponse {
  // [변수] 생성된 리포트의 고유 ID
  final String reportId;
  // [변수] 시뮬레이션 결과 (Results 객체)
  final Results results;

  SimulationResponse({
    required this.reportId,
    required this.results,
  });

  // [기능] 'fromJson' 팩토리 생성자
  // API의 최상위 응답 JSON(Map)을 SimulationResponse 객체로 변환
  factory SimulationResponse.fromJson(Map<String, dynamic> json) {
    return SimulationResponse(
      reportId: json['reportId'],
      results: Results.fromJson(json['results']), // 'results' 객체 변환
    );
  }
}