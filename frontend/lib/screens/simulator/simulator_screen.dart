import 'package:frontend/models/driver_info.dart';
import 'package:frontend/models/race_info.dart';
import 'package:frontend/models/simulation_request.dart';
import 'package:frontend/providers/api_service_provider.dart';
import 'package:frontend/providers/data_provider.dart';
import 'package:frontend/providers/simulator_config_provider.dart';
import 'package:frontend/providers/strategy_provider.dart';
import 'package:frontend/widgets/strategy_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SimulatorScreen extends ConsumerWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- 1. Provider 감시 (Watch) ---
    final config = ref.watch(simulatorConfigProvider);
    final configNotifier = ref.read(simulatorConfigProvider.notifier);
    
    // 전략 목록 Provider 감시
    final scenarios = ref.watch(strategyProvider);
    final strategyNotifier = ref.read(strategyProvider.notifier);

    final AsyncValue<List<RaceInfo>> races = ref.watch(racesProvider);
    final AsyncValue<List<DriverInfo>> drivers = ref.watch(driversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('F1 Strategy Simulator'),
      ),
      // (수정) 스크롤 가능하도록 ListView로 변경
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- 1. 연도 선택 (이전과 동일) ---
          DropdownButtonFormField<int>(
            initialValue: config.selectedYear,
            decoration: const InputDecoration(labelText: 'Year'),
            items: [2024, 2023, 2022]
                .map((year) => DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    ))
                .toList(),
            onChanged: (year) {
              if (year != null) {
                configNotifier.setYear(year);
              }
            },
          ),
          const SizedBox(height: 16),

          // --- 2. 그랑프리 선택 (이전과 동일) ---
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
                    configNotifier.setRace(raceId);
                  }
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // --- 3. 드라이버 선택 (이전과 동일) ---
          drivers.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error: $err'),
            data: (driverList) {
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
                    ? null
                    : (driverId) {
                        if (driverId != null) {
                          configNotifier.setDriver(driverId);
                        }
                      },
              );
            },
          ),
          const Divider(height: 32),

          // --- 4. 전략 시나리오 목록 (신규) ---
          // StrategyCard 목록
          ...scenarios.asMap().entries.map((entry) {
            int index = entry.key;
            Scenario scenario = entry.value;
            return StrategyCard(
              scenario: scenario,
              scenarioIndex: index,
            );
          }),

          // --- 5. 시나리오 추가 버튼 (신규) ---
          OutlinedButton.icon(
            icon: const Icon(Icons.add_chart),
            label: const Text('Add Strategy Scenario'),
            onPressed: () {
              // 새 시나리오 추가
              strategyNotifier.addScenario(
                Scenario(
                  name: "Scenario ${scenarios.length + 1}",
                  // 기본 스틴트 (예: SOFT 1개)
                  stints: [StintRequest(compound: "SOFT")],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // --- 6. 시뮬레이션 실행 버튼 (신규) ---
          // 시뮬레이션 실행 버튼
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run Simulation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: (config.selectedRaceId == null ||
                    config.selectedDriverId == null ||
                    scenarios.isEmpty)
                ? null // 필수값 없으면 비활성화
                : () async {
                    // 시뮬레이션 API 호출
                    final api = ref.read(apiServiceProvider);
                    
                    // 1. SimulationRequest 객체 생성
                    final request = SimulationRequest(
                      year: config.selectedYear,
                      raceId: config.selectedRaceId!,
                      driverId: config.selectedDriverId!,
                      pitLossSeconds: 23.0, // 임시 피트 손실 시간 (설정 화면에서 가져와야 함)
                      scenarios: scenarios,
                    );

                    // 2. 로딩 인디케이터 표시 (임시)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Running simulation...')),
                    );

                    // 3. API 호출
                    final response = await api.runSimulation(request);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();

                    // 4. 결과 처리 (임시)
                    if (response != null) {
                      // 결과 수신 시 AnalysisScreen으로 이동 (다음 단계에서 구현)
                      debugPrint('Simulation Success: ${response.reportId}');
                      // TODO: ref.read(simulationResultProvider.notifier).state = response;
                      // TODO: Navigator.push(context, ... AnalysisScreen ...);
                    } else {
                      // API 오류 알림
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Simulation Failed!')),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}