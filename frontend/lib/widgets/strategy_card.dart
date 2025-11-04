import 'package:frontend/models/simulation_request.dart';
import 'package:frontend/providers/strategy_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 개별 전략 시나리오 카드 위젯
class StrategyCard extends ConsumerWidget {
  final Scenario scenario;
  final int scenarioIndex;

  const StrategyCard({
    super.key,
    required this.scenario,
    required this.scenarioIndex,
  });

  // 타이어 컴파운드별 색상 (임시)
  Map<String, Color> get tireColors => {
        "SOFT": Colors.red,
        "MEDIUM": Colors.yellow,
        "HARD": Colors.white,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strategyNotifier = ref.read(strategyProvider.notifier);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 카드 헤더: 제목 및 삭제 버튼 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  scenario.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    strategyNotifier.removeScenario(scenarioIndex);
                  },
                ),
              ],
            ),
            
            // 스틴트 시각화
            _buildStintVisualization(context),
            const Divider(height: 24),

            // --- 스틴트 편집 UI (ListView) ---
            // 스틴트 편집 UI
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: scenario.stints.length,
              itemBuilder: (context, stintIndex) {
                final stint = scenario.stints[stintIndex];
                return _buildStintEditor(
                  context,
                  ref,
                  stint,
                  stintIndex,
                );
              },
            ),

            // --- 스틴트 추가 버튼 ---
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Stint'),
              onPressed: () {
                // 스틴트 추가 (기본값: MEDIUM)
                strategyNotifier.addStint(
                  scenarioIndex,
                  StintRequest(compound: "MEDIUM"),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 스틴트 시각화 (Row + 색상 컨테이너)
  Widget _buildStintVisualization(BuildContext context) {
    if (scenario.stints.isEmpty) {
      return const Text("No stints added.", style: TextStyle(color: Colors.grey));
    }
    return Row(
      children: scenario.stints.map((stint) {
        return Expanded(
          child: Container(
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: tireColors[stint.compound] ?? Colors.grey,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black54),
            ),
            child: Center(
              child: Text(
                stint.compound[0], // S, M, H
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 개별 스틴트 편집 UI (드롭다운, 삭제 버튼)
  Widget _buildStintEditor(
    BuildContext context,
    WidgetRef ref,
    StintRequest stint,
    int stintIndex,
  ) {
    final strategyNotifier = ref.read(strategyProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('Stint ${stintIndex + 1}:'),
          const SizedBox(width: 16),
          // --- 타이어 컴파운드 변경 드롭다운 ---
          DropdownButton<String>(
            value: stint.compound,
            items: tireColors.keys
                .map((compound) => DropdownMenuItem(
                      value: compound,
                      child: Text(compound),
                    ))
                .toList(),
            onChanged: (newCompound) {
              if (newCompound != null) {
                strategyNotifier.updateStintCompound(
                  scenarioIndex,
                  stintIndex,
                  newCompound,
                );
              }
            },
          ),
          const Spacer(),
          // --- 스틴트 삭제 버튼 ---
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: () {
              strategyNotifier.removeStint(scenarioIndex, stintIndex);
            },
          ),
        ],
      ),
    );
  }
}