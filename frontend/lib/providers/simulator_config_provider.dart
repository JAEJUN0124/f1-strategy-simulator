import 'package:flutter_riverpod/legacy.dart';
import '../models/simulator_config_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 사용자의 시뮬레이터 옵션 선택 상태를 관리하는 Notifier
class SimulatorConfigNotifier extends StateNotifier<SimulatorConfigState> {
  // 초기 상태 설정 (예: 2024년)
  SimulatorConfigNotifier()
      : super(const SimulatorConfigState(selectedYear: 2024));

  /// 연도 선택
  void setYear(int year) {
    // 연도가 변경되면 하위 선택(레이스, 드라이버)을 초기화
    state = SimulatorConfigState(selectedYear: year);
  }

  /// 레이스 선택
  void setRace(String raceId) {
    // 레이스가 변경되면 드라이버 선택을 초기화
    state = state.copyWith(selectedRaceId: raceId, selectedDriverId: null);
  }

  /// 드라이버 선택
  void setDriver(String driverId) {
    state = state.copyWith(selectedDriverId: driverId);
  }
}

/// (v4) 3.4. 시뮬레이터 설정 상태 Provider
final simulatorConfigProvider =
    StateNotifierProvider<SimulatorConfigNotifier, SimulatorConfigState>((ref) {
  return SimulatorConfigNotifier();
});