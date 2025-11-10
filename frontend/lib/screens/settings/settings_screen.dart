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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pit Stop Time saved: $newTime seconds')),
      );
      FocusScope.of(context).unfocus(); // 키보드 숨기기
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid value. Please enter a valid number.')),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 피트 스톱 시간 입력
          TextFormField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Pit Stop Loss (seconds)',
              helperText: 'e.g., 23.5',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}