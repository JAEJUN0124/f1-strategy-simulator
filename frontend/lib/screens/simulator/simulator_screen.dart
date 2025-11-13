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
import 'package:frontend/providers/simulation_result_provider.dart';
import 'package:frontend/screens/analysis/analysis_screen.dart';
import 'package:frontend/providers/settings_provider.dart';
import 'package:frontend/providers/recent_reports_provider.dart';
import 'package:frontend/models/simulator_config_state.dart';

class SimulatorScreen extends ConsumerWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- 1. Provider 감시 (Watch) ---
    final config = ref.watch(simulatorConfigProvider);
    final configNotifier = ref.read(simulatorConfigProvider.notifier);
    final scenarios = ref.watch(strategyProvider);
    final strategyNotifier = ref.read(strategyProvider.notifier);
    final AsyncValue<List<RaceInfo>> races = ref.watch(racesProvider);
    final AsyncValue<List<DriverInfo>> drivers = ref.watch(driversProvider);
    final pitStopSeconds = ref.watch(pitStopProvider);

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // 새 UI에서는 하단 버튼 고정을 위해 Scaffold 사용
      // 기존 ListView를 Column으로 변경
      body: Column(
        children: [
          Expanded(
            // --- 스크롤 영역 ---
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- 1. 경기 데이터 선택 카드 ---
                _buildDataSelectionCard(
                  context,
                  textTheme,
                  config,
                  configNotifier,
                  races,
                  drivers,
                ),
                const SizedBox(height: 24),

                // --- 2. 전략 시나리오 정의 ---
                Text(
                  '2. 전략 시나리오 정의',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // --- 2.1. 시나리오 추가 버튼 ---
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('비교 시나리오 추가'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    strategyNotifier.addScenario(
                      Scenario(
                        name: "시나리오 ${scenarios.length + 1}",
                        stints: [],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // --- 2.2. 전략 시나리오 목록 ---
                ...scenarios.asMap().entries.map((entry) {
                  int index = entry.key;
                  Scenario scenario = entry.value;
                  return StrategyCard(scenario: scenario, scenarioIndex: index);
                }),
              ],
            ),
          ),

          // --- 3. 하단 고정 시뮬레이션 실행 버튼 ---
          _buildRunSimulationButton(
            context,
            ref,
            config,
            scenarios,
            pitStopSeconds,
          ),
        ],
      ),
    );
  }

  /// 1. 경기 데이터 선택 카드 위젯
  Widget _buildDataSelectionCard(
    BuildContext context,
    TextTheme textTheme,
    SimulatorConfigState config,
    SimulatorConfigNotifier configNotifier,
    AsyncValue<List<RaceInfo>> races,
    AsyncValue<List<DriverInfo>> drivers,
  ) {
    // 공통 드롭다운 스타일
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none, // (수정) 테두리 제거
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none, // (수정) 테두리 제거
      ),
      filled: true,
      // (수정) 입력 필드 배경색을 회색으로
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
    );

    return Card(
      // (수정) CardTheme을 사용하므로 color, elevation, shape 제거
      // elevation: 0,
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(12),
      //   side: BorderSide(color: Colors.grey.shade300),
      // ),
      // color: Colors.white, // CardTheme이 흰색으로 설정함
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. 경기 데이터 선택',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // --- 연도 선택 ---
            const Text('연도', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              value: config.selectedYear,
              decoration: inputDecoration,
              items: [2024, 2023, 2022]
                  .map(
                    (year) => DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    ),
                  )
                  .toList(),
              onChanged: (year) {
                if (year != null) {
                  configNotifier.setYear(year);
                }
              },
            ),
            const SizedBox(height: 16),

            // --- 그랑프리 선택 ---
            const Text('그랑프리', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            races.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
              data: (raceList) {
                final currentRaceId =
                    raceList.any((r) => r.raceId == config.selectedRaceId)
                    ? config.selectedRaceId
                    : null;
                return DropdownButtonFormField<String>(
                  value: currentRaceId,
                  hint: const Text('경기 선택'),
                  decoration: inputDecoration,
                  isExpanded: true,
                  items: raceList
                      .map(
                        (race) => DropdownMenuItem(
                          value: race.raceId,
                          child: Text(
                            race.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
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

            // --- 드라이버 선택 ---
            const Text('드라이버', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            drivers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
              data: (driverList) {
                final currentDriverId =
                    driverList.any((d) => d.driverId == config.selectedDriverId)
                    ? config.selectedDriverId
                    : null;
                bool isDisabled = driverList.isEmpty;
                return DropdownButtonFormField<String>(
                  value: currentDriverId,
                  hint: const Text('드라이버 선택'),
                  decoration: inputDecoration.copyWith(
                    // (수정) 비활성화 시 더 연한 회색으로
                    fillColor: isDisabled
                        ? Colors.grey.shade200
                        : Colors.grey.shade100,
                  ),
                  isExpanded: true,
                  items: driverList
                      .map(
                        (driver) => DropdownMenuItem(
                          value: driver.driverId,
                          child: Text(driver.name),
                        ),
                      )
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
          ],
        ),
      ),
    );
  }

  /// 3. 하단 고정 시뮬레이션 실행 버튼 위젯
  Widget _buildRunSimulationButton(
    BuildContext context,
    WidgetRef ref,
    SimulatorConfigState config,
    List<Scenario> scenarios,
    double pitStopSeconds,
  ) {
    // 버튼 활성화 조건
    final bool canRun =
        config.selectedRaceId != null &&
        config.selectedDriverId != null &&
        scenarios.isNotEmpty &&
        scenarios.every((s) => s.stints.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white, // (수정) 버튼 컨테이너 배경색
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          // 회색 버튼 스타일
          backgroundColor: canRun ? Colors.grey.shade700 : Colors.grey.shade300,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: !canRun
            ? null // 필수값 없으면 비활성화
            : () async {
                // 기존 시뮬레이션 실행 로직
                final api = ref.read(apiServiceProvider);
                final request = SimulationRequest(
                  year: config.selectedYear,
                  raceId: config.selectedRaceId!,
                  driverId: config.selectedDriverId!,
                  pitLossSeconds: pitStopSeconds,
                  scenarios: scenarios,
                );

                // 로딩 인디케이터
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('시뮬레이션을 실행합니다...')),
                );

                final response = await api.runSimulation(request);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if (response != null) {
                  ref.read(simulationResultProvider.notifier).state = response;
                  ref.read(recentReportsProvider.notifier).addReport(response);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalysisScreen(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('시뮬레이션 실패! API 서버 연결을 확인하세요.'),
                    ),
                  );
                }
              },
        child: const Text(
          '시뮬레이션 실행',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
