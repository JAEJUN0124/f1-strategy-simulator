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
    final config = ref.watch(simulatorConfigProvider);
    final configNotifier = ref.read(simulatorConfigProvider.notifier);
    final scenarios = ref.watch(strategyProvider);
    final strategyNotifier = ref.read(strategyProvider.notifier);
    final AsyncValue<List<RaceInfo>> races = ref.watch(racesProvider);
    final AsyncValue<List<DriverInfo>> drivers = ref.watch(driversProvider);
    final pitStopSeconds = ref.watch(pitStopProvider);

    final textTheme = Theme.of(context).textTheme;

    // [수정] 드라이버 데이터 로드 에러 감지 로직 개선
    ref.listen<AsyncValue<List<DriverInfo>>>(driversProvider, (previous, next) {
      // 상태가 Error로 변경되었을 때만 실행
      next.whenOrNull(
        error: (error, stackTrace) {
          final errorMsg = error.toString();
          // 404 에러이거나 'not found' 메시지가 포함된 경우 (데이터 없음)
          if (errorMsg.contains('404') || errorMsg.contains('not found')) {
            Future.microtask(() {
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false, // 확인 버튼을 눌러야만 닫히도록
                  builder: (context) => AlertDialog(
                    title: const Text('데이터 없음'),
                    content: const Text(
                      '선택하신 경기의 데이터가 아직 업데이트되지 않았습니다.\n다른 경기를 선택해주세요.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // 다이얼로그 닫기
                          // (선택 사항) 필요하다면 여기서 레이스 선택을 초기화할 수도 있음
                          // configNotifier.setRace(null);
                        },
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              }
            });
          }
        },
      );
    });

    // 시나리오 추가 제한 로직 (3개 미만일 때만 추가 가능)
    final bool canAddScenario = scenarios.length < 3;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. 경기 데이터 선택 카드 (연도 드롭다운 포함)
                _buildDataSelectionCard(
                  context,
                  textTheme,
                  config,
                  configNotifier,
                  races,
                  drivers,
                ),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '2. 전략 시나리오 정의',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${scenarios.length} / 3',
                        style: TextStyle(
                          color: canAddScenario ? Colors.grey : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  icon: const Icon(Icons.add_chart_rounded),
                  label: const Text('비교 시나리오 추가'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: canAddScenario
                        ? Colors.black87
                        : Colors.grey,
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(
                      color: canAddScenario
                          ? Colors.grey.shade300
                          : Colors.grey.shade200,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: canAddScenario
                      ? () {
                          strategyNotifier.addScenario(
                            Scenario(
                              name: "시나리오 ${scenarios.length + 1}",
                              stints: [],
                            ),
                          );
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('시나리오는 최대 3개까지만 추가 가능합니다.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 16),

                ...scenarios.asMap().entries.map((entry) {
                  int index = entry.key;
                  Scenario scenario = entry.value;
                  return StrategyCard(scenario: scenario, scenarioIndex: index);
                }),

                const SizedBox(height: 24),
              ],
            ),
          ),

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

  Widget _buildDataSelectionCard(
    BuildContext context,
    TextTheme textTheme,
    SimulatorConfigState config,
    SimulatorConfigNotifier configNotifier,
    AsyncValue<List<RaceInfo>> races,
    AsyncValue<List<DriverInfo>> drivers,
  ) {
    const inputDecoration = InputDecoration(isDense: true);

    // 시뮬레이터용 연도 리스트 자동 생성 로직 (2016 ~ Future)
    final int currentYear = DateTime.now().year;

    // 최소 2025년까지는 보장하고, 그 이후는 현재 연도까지
    final int maxYear = currentYear < 2025 ? 2025 : currentYear;
    final int minYear = 2016;

    // 최신 연도부터 내림차순 정렬
    final List<int> yearList = List.generate(
      maxYear - minYear + 1,
      (index) => maxYear - index,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. 경기 데이터 선택',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('시즌 연도'),
            DropdownButtonFormField<int>(
              value: config.selectedYear,
              decoration: inputDecoration,
              items: yearList
                  .map(
                    (year) =>
                        DropdownMenuItem(value: year, child: Text('$year 시즌')),
                  )
                  .toList(),
              onChanged: (year) {
                if (year != null) {
                  configNotifier.setYear(year);
                }
              },
            ),
            const SizedBox(height: 16),

            _buildLabel('그랑프리'),
            races.when(
              loading: () =>
                  const Center(child: LinearProgressIndicator(minHeight: 2)),
              error: (err, stack) => Text(
                '목록 로드 실패: $err',
                style: const TextStyle(color: Colors.red),
              ),
              data: (raceList) {
                final currentRaceId =
                    raceList.any((r) => r.raceId == config.selectedRaceId)
                    ? config.selectedRaceId
                    : null;
                return DropdownButtonFormField<String>(
                  value: currentRaceId,
                  hint: const Text('경기 선택'),
                  isExpanded: true,
                  items: raceList
                      .map(
                        (race) => DropdownMenuItem(
                          value: race.raceId,
                          child: Text(
                            "${race.round}R. ${race.name}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (raceId) {
                    if (raceId != null) configNotifier.setRace(raceId);
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            _buildLabel('드라이버'),
            drivers.when(
              loading: () =>
                  const Center(child: LinearProgressIndicator(minHeight: 2)),
              // [수정] 에러 발생 시 텍스트 표시 대신 빈 컨테이너나 안내 메시지 (다이얼로그가 뜨므로)
              error: (err, stack) {
                // 이미 팝업으로 처리하므로 여기서는 간단히 표시하거나 숨김
                return const Text(
                  '데이터 없음',
                  style: TextStyle(color: Colors.red),
                );
              },
              data: (driverList) {
                final currentDriverId =
                    driverList.any((d) => d.driverId == config.selectedDriverId)
                    ? config.selectedDriverId
                    : null;
                bool isDisabled = driverList.isEmpty;
                return DropdownButtonFormField<String>(
                  value: currentDriverId,
                  hint: const Text('드라이버 선택'),
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
                          if (driverId != null)
                            configNotifier.setDriver(driverId);
                        },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildRunSimulationButton(
    BuildContext context,
    WidgetRef ref,
    SimulatorConfigState config,
    List<Scenario> scenarios,
    double pitStopSeconds,
  ) {
    final bool canRun =
        config.selectedRaceId != null &&
        config.selectedDriverId != null &&
        scenarios.isNotEmpty &&
        scenarios.every((s) => s.stints.isNotEmpty);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canRun
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: canRun ? 4 : 0,
          shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
        ),
        onPressed: !canRun
            ? null
            : () async {
                final api = ref.read(apiServiceProvider);
                final request = SimulationRequest(
                  year: config.selectedYear,
                  raceId: config.selectedRaceId!,
                  driverId: config.selectedDriverId!,
                  pitLossSeconds: pitStopSeconds,
                  scenarios: scenarios,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('시뮬레이션 데이터를 분석 중입니다...')),
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
                    const SnackBar(content: Text('시뮬레이션 실패. 서버 상태를 확인해주세요.')),
                  );
                }
              },
        child: const Text(
          '시뮬레이션 실행',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
