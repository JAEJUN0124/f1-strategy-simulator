// frontend/lib/models/simulator_config_state.dart

import 'package:flutter/foundation.dart';

@immutable
class SimulatorConfigState {
  final int selectedYear;
  final String? selectedRaceId;
  final String? selectedDriverId;

  const SimulatorConfigState({
    required this.selectedYear,
    this.selectedRaceId,
    this.selectedDriverId,
  });

  // 상태 변경 시 복사를 위한 copyWith
  SimulatorConfigState copyWith({
    int? selectedYear,
    String? selectedRaceId,
    String? selectedDriverId,
  }) {
    return SimulatorConfigState(
      selectedYear: selectedYear ?? this.selectedYear,
      selectedRaceId: selectedRaceId ?? this.selectedRaceId,
      selectedDriverId: selectedDriverId ?? this.selectedDriverId,
    );
  }
}