import 'package:frontend/models/simulation_request.dart';
import 'package:flutter_riverpod/legacy.dart';

/// 시뮬레이터의 전략 시나리오 목록 상태를 관리하는 Notifier
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

  /// 스틴트 추가
  void addStint(int scenarioIndex, StintRequest stint) {
    if (scenarioIndex < 0 || scenarioIndex >= state.length) return;
    
    final updatedScenario = state[scenarioIndex].copyWith(
      stints: [...state[scenarioIndex].stints, stint],
    );
    _updateScenario(scenarioIndex, updatedScenario);
  }

  /// 스틴트 삭제
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

  /// 스틴트의 타이어 컴파운드 변경
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

/// 전략 시나리오 목록 Provider
final strategyProvider =
    StateNotifierProvider<StrategyNotifier, List<Scenario>>((ref) {
  return StrategyNotifier();
});