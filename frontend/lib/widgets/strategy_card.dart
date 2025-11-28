import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/simulation_request.dart';
import 'package:frontend/providers/strategy_provider.dart';
import 'package:frontend/widgets/simulator/stint_editor.dart';

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
  late final TextEditingController _nameController;
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
    if (widget.scenario.name != _nameController.text) {
      _nameController.text = widget.scenario.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strategyNotifier = ref.read(strategyProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      // 메인 테마의 Card 스타일을 자동으로 따릅니다 (둥근 모서리, 그림자 등)
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. 카드 헤더 ---
            Row(
              children: [
                // 시나리오 이름 입력 (밑줄 스타일로 변경하여 깔끔하게)
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: '시나리오 이름',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    onEditingComplete: () {
                      strategyNotifier.updateScenarioName(
                        widget.scenarioIndex,
                        _nameController.text,
                      );
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                // 삭제 버튼
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: () {
                    strategyNotifier.removeScenario(widget.scenarioIndex);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- 2. 스틴트 시각화 (개선된 디자인) ---
            _buildStintVisualization(context, widget.scenario.stints),
            const SizedBox(height: 20),

            // --- 3. 옵션 스위치 ---
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA), // 내부 섹션 배경색
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile.adaptive(
                // OS 스타일에 맞는 스위치
                title: const Text(
                  '피트 랩 자동 최적화',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'AI가 최적의 타이밍을 계산합니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: _isAutoOptimize,
                activeColor: colorScheme.primary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                onChanged: (newValue) {
                  setState(() {
                    _isAutoOptimize = newValue;
                  });
                },
              ),
            ),

            if (!widget.scenario.stints.isEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                "스틴트 상세 설정",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // --- 4. 스틴트 리스트 ---
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.scenario.stints.length,
              itemBuilder: (context, stintIndex) {
                final stint = widget.scenario.stints[stintIndex];
                return StintEditor(
                  scenarioIndex: widget.scenarioIndex,
                  stintIndex: stintIndex,
                  stint: stint,
                  isAutoOptimize: _isAutoOptimize,
                );
              },
            ),

            const SizedBox(height: 12),

            // --- 5. 스틴트 추가 버튼 ---
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  strategyNotifier.addStint(
                    widget.scenarioIndex,
                    StintRequest(compound: "MEDIUM"),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("스틴트 추가"),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFF0F2F5),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 타이어 시각화 (원형 디자인 적용)
  Widget _buildStintVisualization(
    BuildContext context,
    List<StintRequest> stints,
  ) {
    if (stints.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.tire_repair, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              "전략을 구성해주세요",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    List<Widget> items = [];
    for (int i = 0; i < stints.length; i++) {
      final stint = stints[i];
      items.add(_buildTireBadge(stint.compound));

      // 화살표 대신 얇은 선으로 연결
      if (i < stints.length - 1) {
        items.add(
          Expanded(
            child: Container(
              height: 2,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 간격 균등 배분
        children: items.length > 1 ? items : [items.first, const Spacer()],
      ),
    );
  }

  // 타이어 배지 (원형, 실제 타이어 색상)
  Widget _buildTireBadge(String compound) {
    final color = StintEditor.tireColors[compound] ?? Colors.grey;
    final isHard = compound == "HARD";

    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isHard ? Colors.white : color,
            shape: BoxShape.circle,
            // HARD 타이어는 흰색이라 테두리를 두껍게 주어 구분
            border: Border.all(
              color: isHard ? Colors.black : color,
              width: isHard ? 5 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              compound[0], // S, M, H
              style: TextStyle(
                color: isHard ? Colors.black : Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          compound,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
