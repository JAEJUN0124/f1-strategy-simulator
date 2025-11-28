import 'package:flutter_riverpod/legacy.dart';
import '../models/simulator_config_state.dart';

/// 사용자의 시뮬레이터 옵션 선택 상태를 관리하는 Notifier
class SimulatorConfigNotifier extends StateNotifier<SimulatorConfigState> {
  // [수정] 초기 상태를 고정값(2024)이 아닌 동적 최신 연도로 설정
  SimulatorConfigNotifier()
    : super(SimulatorConfigState(selectedYear: _getInitialYear()));

  /// 초기 연도 계산 (현재 연도와 2025년 중 더 큰 값)
  /// SimulatorScreen의 목록 생성 로직과 동일하게 맞춤
  static int _getInitialYear() {
    final int currentYear = DateTime.now().year;
    // 최소 2025년까지는 보장하고, 시간이 흘러 2026년이 되면 2026년 반환
    return currentYear < 2025 ? 2025 : currentYear;
  }

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

/// 시뮬레이터 설정 상태 Provider
final simulatorConfigProvider =
    StateNotifierProvider<SimulatorConfigNotifier, SimulatorConfigState>((ref) {
      return SimulatorConfigNotifier();
    });
