import 'package:frontend/models/simulation_request.dart';
import 'package:flutter_riverpod/legacy.dart';

/// (v4) 3.4. 시뮬레이터의 전략 시나리오 목록 상태를 관리하는 Notifier
class StrategyNotifier extends StateNotifier<List<Scenario>> {
  StrategyNotifier() : super([]); // 초기 상태는 빈 리스트

  /// 새 시나리오 추가
  void addScenario(Scenario scenario) {
    state = [...state, scenario];
  }

  /// 시나리오 삭제 (index 기준)
  void removeScenario(int index) {
    if (index < 0 || index >= state.length) return;
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
  }

  /// (v4) 3.5. 스틴트 추가
  void addStint(int scenarioIndex, StintRequest stint) {
    if (scenarioIndex < 0 || scenarioIndex >= state.length) return;
    
    final updatedScenario = state[scenarioIndex].copyWith(
      stints: [...state[scenarioIndex].stints, stint],
    );
    _updateScenario(scenarioIndex, updatedScenario);
  }

  /// (v4) 3.5. 스틴트 삭제
  void removeStint(int scenarioIndex, int stintIndex) {
    if (scenarioIndex < 0 || scenarioIndex >= state.length) return;
    final scenario = state[scenarioIndex];
    if (stintIndex < 0 || stintIndex >= scenario.stints.length) return;

    final updatedStints = [
      for (int i = 0; i < scenario.stints.length; i++)
        if (i != stintIndex) scenario.stints[i],
    ];
    _updateScenario(scenarioIndex, scenario.copyWith(stints: updatedStints));
  }

  /// (v4) 3.5. 스틴트의 타이어 컴파운드 변경
  void updateStintCompound(int scenarioIndex, int stintIndex, String newCompound) {
    if (scenarioIndex < 0 || scenarioIndex >= state.length) return;
    final scenario = state[scenarioIndex];
    if (stintIndex < 0 || stintIndex >= scenario.stints.length) return;

    final updatedStint = scenario.stints[stintIndex].copyWith(compound: newCompound);
    
    final updatedStints = [...scenario.stints];
    updatedStints[stintIndex] = updatedStint;
    
    _updateScenario(scenarioIndex, scenario.copyWith(stints: updatedStints));
  }

  /// 특정 시나리오를 업데이트하는 내부 헬퍼
  void _updateScenario(int index, Scenario scenario) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) scenario else state[i],
    ];
  }
}

/// (v4) 3.4. 전략 시나리오 목록 Provider
final strategyProvider =
    StateNotifierProvider<StrategyNotifier, List<Scenario>>((ref) {
  return StrategyNotifier();
});

// --- SimulationRequest 모델 수정 ---
// StateNotifier에서 상태를 쉽게 변경하기 위해 Scenario와 StintRequest에
// copyWith 메서드를 추가합니다.

// (v4) 3.5. 상태 관리를 위한 copyWith 추가
// frontend/lib/models/simulation_request.dart 파일의
// StintRequest와 Scenario 클래스에 아래 메서드들을 추가하세요.

/*
// --- StintRequest 클래스에 추가 ---
StintRequest copyWith({
  String? compound,
  int? startLap,
  int? endLap,
}) {
  return StintRequest(
    compound: compound ?? this.compound,
    startLap: startLap ?? this.startLap,
    endLap: endLap ?? this.endLap,
  );
}

// --- Scenario 클래스에 추가 ---
Scenario copyWith({
  String? name,
  List<StintRequest>? stints,
}) {
  return Scenario(
    name: name ?? this.name,
    stints: stints ?? this.stints,
  );
}
*/