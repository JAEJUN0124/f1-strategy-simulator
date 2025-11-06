import 'package:frontend/models/simulation_response.dart';
import 'package:flutter_riverpod/legacy.dart';

/// 시뮬레이션 결과 상태 관리
/// API 응답(SimulationResponse)을 저장하며, null일 수 있음
final simulationResultProvider =
    StateProvider<SimulationResponse?>((ref) {
  return null;
});