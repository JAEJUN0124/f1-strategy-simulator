import 'package:frontend/models/driver_info.dart';
import 'package:frontend/models/race_info.dart';
import 'package:frontend/providers/data_provider.dart';
import 'package:frontend/providers/simulator_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 시뮬레이터 화면
/// Riverpod의 ConsumerWidget을 사용하여 Provider 상태를 실시간으로 반영
class SimulatorScreen extends ConsumerWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. providers/simulator_config_provider.dart의 상태와 Notifier를 가져옴
    final config = ref.watch(simulatorConfigProvider);
    final configNotifier = ref.read(simulatorConfigProvider.notifier);

    // 2. providers/data_providers.dart의 FutureProvider 상태를 가져옴
    final AsyncValue<List<RaceInfo>> races = ref.watch(racesProvider);
    final AsyncValue<List<DriverInfo>> drivers = ref.watch(driversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('F1 Strategy Simulator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. 연도 선택 드롭다운 ---
            // 연도 선택
            DropdownButtonFormField<int>(
              initialValue: config.selectedYear,
              decoration: const InputDecoration(labelText: 'Year'),
              items: [2024, 2023, 2022] // 임시 연도 목록
                  .map((year) => DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      ))
                  .toList(),
              onChanged: (year) {
                if (year != null) {
                  // 연도 변경 시 상태 업데이트
                  configNotifier.setYear(year);
                }
              },
            ),
            const SizedBox(height: 16),

            // --- 2. 그랑프리 선택 드롭다운 ---
            // 그랑프리 선택 (racesProvider 사용)
            // racesProvider는 FutureProvider이므로 when을 사용하여 로딩/오류/데이터 상태 처리
            races.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
              data: (raceList) {
                return DropdownButtonFormField<String>(
                  initialValue: config.selectedRaceId,
                  hint: const Text('Select Grand Prix'),
                  decoration: const InputDecoration(labelText: 'Grand Prix'),
                  isExpanded: true,
                  items: raceList
                      .map((race) => DropdownMenuItem(
                            value: race.raceId,
                            child: Text(race.name),
                          ))
                      .toList(),
                  onChanged: (raceId) {
                    if (raceId != null) {
                      // (v4) 3.4. 레이스 변경 시 상태 업데이트
                      configNotifier.setRace(raceId);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // --- 3. 드라이버 선택 드롭다운 ---
            // 드라이버 선택 (driversProvider 사용)
            drivers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
              data: (driverList) {
                // 레이스가 선택되지 않았거나(driverList가 비어있음)
                // 레이스 변경으로 선택이 초기화된 경우 드롭다운 비활성화
                bool isDisabled = driverList.isEmpty;

                return DropdownButtonFormField<String>(
                  initialValue: config.selectedDriverId,
                  hint: const Text('Select Driver'),

                  disabledHint: config.selectedRaceId == null
                      ? const Text('Select a Grand Prix first')
                      : const Text('Loading drivers...'),
                  
                  decoration: const InputDecoration(
                    labelText: 'Driver',
                  ),
                  isExpanded: true,
                  items: driverList
                      .map((driver) => DropdownMenuItem(
                            value: driver.driverId,
                            child: Text(driver.name),
                          ))
                      .toList(),
                  onChanged: isDisabled
                      ? null // 비활성화
                      : (driverId) {
                          if (driverId != null) {
                            configNotifier.setDriver(driverId);
                          }
                        },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
