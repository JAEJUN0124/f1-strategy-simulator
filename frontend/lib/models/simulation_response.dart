import 'race_event.dart';
import 'strategy_result.dart';

class SimulationResponse {
  final String reportId;
  final StrategyResult actual;
  final StrategyResult optimal;
  final List<StrategyResult> scenarios;
  final List<RaceEvent> raceEvents; 

  SimulationResponse({
    required this.reportId,
    required this.actual,
    required this.optimal,
    required this.scenarios,
    required this.raceEvents,
  });

  factory SimulationResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> results = json['results'] ?? {};
    
    return SimulationResponse(
      reportId: json['reportId'] ?? '',
      
      // 'results' 맵 내부의 각 항목을 파싱합니다.
      actual: StrategyResult.fromJson(results['actual'] ?? {}),
      optimal: StrategyResult.fromJson(results['optimal'] ?? {}),
      
      scenarios: (results['scenarios'] as List<dynamic>? ?? [])
          .map((e) => StrategyResult.fromJson(e as Map<String, dynamic>))
          .toList(),
          
      // (v4) 레이스 이벤트 목록 파싱 
      raceEvents: (json['raceEvents'] as List<dynamic>? ?? [])
          .map((e) => RaceEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}