import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/simulation_request.dart';
import 'package:frontend/providers/strategy_provider.dart';

/// 개별 스틴트(컴파운드, 시작/종료 랩)를 편집하는 위젯
class StintEditor extends ConsumerStatefulWidget {
  final int scenarioIndex;
  final int stintIndex;
  final StintRequest stint;
  final bool isAutoOptimize; // 부모(StrategyCard)로부터 자동 최적화 상태를 전달받음

  const StintEditor({
    super.key,
    required this.scenarioIndex,
    required this.stintIndex,
    required this.stint,
    required this.isAutoOptimize,
  });

  // (추가) 타이어 컴파운드별 색상과 이름을 관리하는 맵
  static const Map<String, Color> tireColors = {
    "SOFT": Colors.red,
    "MEDIUM": Colors.yellow,
    "HARD": Colors.white,
  };

  @override
  ConsumerState<StintEditor> createState() => _StintEditorState();
}

class _StintEditorState extends ConsumerState<StintEditor> {
  // 수동 랩 입력을 위한 텍스트 컨트롤러
  late final TextEditingController _startLapController;
  late final TextEditingController _endLapController;

  @override
  void initState() {
    super.initState();
    _startLapController = TextEditingController(
      text: widget.stint.startLap?.toString() ?? '',
    );
    _endLapController = TextEditingController(
      text: widget.stint.endLap?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant StintEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Provider의 상태가 변경되었을 때 (예: 스틴트 삭제/추가) 컨트롤러 텍스트 동기화
    if (widget.stint.startLap?.toString() != _startLapController.text) {
      _startLapController.text = widget.stint.startLap?.toString() ?? '';
    }
    if (widget.stint.endLap?.toString() != _endLapController.text) {
      _endLapController.text = widget.stint.endLap?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _startLapController.dispose();
    _endLapController.dispose();
    super.dispose();
  }

  // 랩 입력값 변경 시 Provider 업데이트
  void _updateLapProvider() {
    final strategyNotifier = ref.read(strategyProvider.notifier);
    strategyNotifier.updateStintLaps(
      widget.scenarioIndex,
      widget.stintIndex,
      startLap: int.tryParse(_startLapController.text),
      endLap: int.tryParse(_endLapController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strategyNotifier = ref.read(strategyProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white, // (수정) 배경을 흰색으로
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. 헤더: "스틴트 1" 및 "제거" 버튼 ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '스틴트 ${widget.stintIndex + 1}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('제거', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  strategyNotifier.removeStint(
                    widget.scenarioIndex,
                    widget.stintIndex,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- 2. 컴파운드 선택 드롭다운 ---
          const Text('컴파운드', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 4), // (추가) 간격
          DropdownButtonFormField<String>(
            value: widget.stint.compound,
            isExpanded: true,
            decoration: InputDecoration(
              // (수정) 입력 필드 스타일
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            items: StintEditor.tireColors.keys
                .map(
                  (compound) =>
                      DropdownMenuItem(value: compound, child: Text(compound)),
                )
                .toList(),
            onChanged: (newCompound) {
              if (newCompound != null) {
                strategyNotifier.updateStintCompound(
                  widget.scenarioIndex,
                  widget.stintIndex,
                  newCompound,
                );
              }
            },
          ),
          const SizedBox(height: 12),

          // --- 3. 랩 입력 (자동 최적화가 꺼져있을 때만 표시) ---
          if (!widget.isAutoOptimize)
            Row(
              children: [
                // 시작 랩
                Expanded(
                  child: TextField(
                    controller: _startLapController,
                    decoration: InputDecoration(
                      // (수정) 입력 필드 스타일
                      labelText: '시작 랩',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _updateLapProvider(),
                  ),
                ),
                const SizedBox(width: 12),
                // 종료 랩
                Expanded(
                  child: TextField(
                    controller: _endLapController,
                    decoration: InputDecoration(
                      // (수정) 입력 필드 스타일
                      labelText: '종료 랩',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _updateLapProvider(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
