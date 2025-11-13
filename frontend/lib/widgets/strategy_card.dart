import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/simulation_request.dart';
import 'package:frontend/providers/strategy_provider.dart';
import 'package:frontend/widgets/simulator/stint_editor.dart';

/// 개별 전략 시나리오 카드 위젯
class StrategyCard extends ConsumerStatefulWidget {
  final Scenario scenario;
  final int scenarioIndex;

  const StrategyCard({
    super.key,
    required this.scenario,
    required this.scenarioIndex,
  });

  @override
  ConsumerState<StrategyCard> createState() => _StrategyCardState();
}

class _StrategyCardState extends ConsumerState<StrategyCard> {
  // 시나리오 이름 수정을 위한 컨트롤러
  late final TextEditingController _nameController;

  // "피트 랩 자동 최적화" 스위치 상태
  bool _isAutoOptimize = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scenario.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StrategyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Provider에서 이름이 변경되었을 때 (거의 발생하지 않음) 컨트롤러 동기화
    if (widget.scenario.name != _nameController.text) {
      _nameController.text = widget.scenario.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strategyNotifier = ref.read(strategyProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      // (수정) CardTheme을 따르되, 배경색만 회색으로 변경
      color: Colors.grey.shade50,
      // (수정) CardTheme을 사용하므로 elevation, shape 제거
      // elevation: 0,
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(12),
      //   side: BorderSide(color: Colors.grey.shade300),
      // ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. 카드 헤더: 시나리오 이름 (수정 가능) 및 삭제 버튼 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // (추가) 입력 필드 배경을 회색으로
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200, // 회색 배경
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: '시나리오 이름',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      // 수정이 끝나면 Provider에 이름 업데이트
                      onEditingComplete: () {
                        strategyNotifier.updateScenarioName(
                          widget.scenarioIndex,
                          _nameController.text,
                        );
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    strategyNotifier.removeScenario(widget.scenarioIndex);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 2. 스틴트 시각화 ---
            _buildStintVisualization(context, widget.scenario.stints),
            const SizedBox(height: 16),

            // --- 3. 피트 랩 자동 최적화 스위치 ---
            // (수정) SwitchListTile 배경색 투명하게
            SwitchListTile(
              title: const Text('피트 랩 자동 최적화'),
              value: _isAutoOptimize,
              onChanged: (newValue) {
                setState(() {
                  _isAutoOptimize = newValue;
                });
                // (참고: 자동 최적화가 꺼지면 StintEditor의 랩 입력란이 나타남)
              },
              contentPadding: EdgeInsets.zero,
              // (추가) 배경색을 카드와 동일하게
              tileColor: Colors.transparent,
            ),
            const Divider(),

            // --- 4. 스틴트 편집 UI (ListView) ---
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.scenario.stints.length,
              itemBuilder: (context, stintIndex) {
                final stint = widget.scenario.stints[stintIndex];
                // 새로 만든 StintEditor 위젯 사용
                return StintEditor(
                  scenarioIndex: widget.scenarioIndex,
                  stintIndex: stintIndex,
                  stint: stint,
                  isAutoOptimize: _isAutoOptimize, // 자동 최적화 상태 전달
                );
              },
            ),

            // --- 5. 스틴트 추가 버튼 ---
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('스틴트 추가'),
              style: OutlinedButton.styleFrom(
                // (수정) 회색 배경
                backgroundColor: Colors.grey.shade200,
                minimumSize: const Size(double.infinity, 44), // 버튼을 가로로 꽉 채움
                side: BorderSide.none, // (수정) 테두리 제거
              ),
              onPressed: () {
                // 스틴트 추가 (기본값: MEDIUM)
                strategyNotifier.addStint(
                  widget.scenarioIndex,
                  StintRequest(compound: "MEDIUM"),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 스틴트 시각화 (image_4fb981.png - S -> M -> S 형태)
  Widget _buildStintVisualization(
    BuildContext context,
    List<StintRequest> stints,
  ) {
    if (stints.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text("스틴트를 추가해 주세요."),
      );
    }

    List<Widget> items = [];
    for (int i = 0; i < stints.length; i++) {
      final stint = stints[i];
      // 타이어 컴파운드 뱃지
      items.add(_buildTireBadge(stint.compound));

      // 마지막 스틴트가 아니면 화살표 추가
      if (i < stints.length - 1) {
        items.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: items),
    );
  }

  /// 타이어 뱃지 (S, M, H)
  Widget _buildTireBadge(String compound) {
    // StintEditor.tireColors를 사용하기 위해 StintEditor 위젯 임포트 필요
    final color = StintEditor.tireColors[compound] ?? Colors.grey;
    final isHard = compound == "HARD";
    // (수정) HARD 타이어일 때 흰색이 아닌 회색 배경 사용
    final badgeColor = isHard ? Colors.grey.shade200 : color;
    final textColor = isHard ? Colors.black : Colors.white;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: badgeColor, // (수정)
        borderRadius: BorderRadius.circular(4),
        border: isHard ? Border.all(color: Colors.black54) : null,
      ),
      child: Center(
        child: Text(
          compound[0], // S, M, H
          style: TextStyle(
            color: textColor, // (수정)
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
