import 'package:frontend/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 설정 화면
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Provider에서 초기 피트 스톱 시간 로드
    final pitStopSeconds = ref.read(pitStopProvider);
    _controller = TextEditingController(text: pitStopSeconds.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final newTime = double.tryParse(_controller.text);
    if (newTime != null && newTime > 0) {
      // Provider를 통해 값 업데이트 및 저장
      ref.read(pitStopProvider.notifier).setPitStopSeconds(newTime);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 완료: 피트 스톱 시간 ${newTime}초')));
      FocusScope.of(context).unfocus(); // 키보드 숨기기
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('유효하지 않은 값입니다. 숫자를 입력하세요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider가 외부(다른 기기)에서 변경되었을 때 UI 동기화
    ref.listen(pitStopProvider, (previous, next) {
      if (_controller.text != next.toString()) {
        _controller.text = next.toString();
      }
    });

    final textTheme = Theme.of(context).textTheme;

    // Scaffold와 AppBar 제거, 새 UI 적용
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- 1. 화면 제목 ---
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            '설정',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        // --- 2. 시뮬레이션 파라미터 카드 ---
        Card(
          // (수정) CardTheme을 사용하므로 color, elevation, shape 제거
          // elevation: 0,
          // shape: RoundedRectangleBorder(
          //   borderRadius: BorderRadius.circular(12),
          //   side: BorderSide(color: Colors.grey.shade300),
          // ),
          // color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '시뮬레이션 파라미터',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // --- 3. 피트 스톱 시간 입력 ---
                const Text(
                  '기본 피트 레인 시간 손실 (초)',
                  style: TextStyle(color: Colors.black54), // 라벨 스타일
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _controller,
                  decoration: InputDecoration(
                    // (수정) 이미지의 회색 배경 스타일
                    filled: true,
                    fillColor: Colors.grey.shade100, // 회색 배경
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none, // 테두리 없음
                    ),
                    // (수정) 텍스트가 크게 보이도록 contentPadding 조정
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  // 입력 텍스트 스타일
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '피트 레인 진입 및 탈출을 포함한 피트 스톱 중 평균 손실 시간',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // --- 4. 저장 버튼 (시뮬레이터 화면과 동일한 스타일) ---
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade700,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _saveSettings,
          child: const Text(
            '설정 저장',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
