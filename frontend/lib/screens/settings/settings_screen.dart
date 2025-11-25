import 'package:frontend/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      ref.read(pitStopProvider.notifier).setPitStopSeconds(newTime);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장되었습니다: 피트 로스 ${newTime}초')));
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('올바른 숫자를 입력해주세요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pitStopProvider, (previous, next) {
      if (_controller.text != next.toString()) {
        _controller.text = next.toString();
      }
    });

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            '환경 설정',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.timer,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '피트 스톱 파라미터',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  '기본 피트 레인 시간 손실', // (수정) 영어 괄호 삭제
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  decoration: const InputDecoration(
                    suffixText: '초', // (수정) 영어 삭제
                    suffixStyle: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '※ 피트 레인 진입부터 탈출까지 소요되는 평균 손실 시간입니다. 서킷마다 다르므로 적절한 값을 입력하세요.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        ElevatedButton.icon(
          onPressed: _saveSettings,
          icon: const Icon(Icons.save_rounded),
          label: const Text('설정 저장'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            elevation: 2,
          ),
        ),
      ],
    );
  }
}
