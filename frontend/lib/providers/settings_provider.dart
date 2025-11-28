import 'package:frontend/services/local_storage_service.dart';
import 'package:flutter_riverpod/legacy.dart';

/// 피트 스톱 시간 상태를 관리
class PitStopNotifier extends StateNotifier<double> {
  final LocalStorageService _storageService;

  PitStopNotifier(this._storageService)
      : super(_storageService.loadPitStopSeconds());

  /// 피트 스톱 시간 업데이트 및 저장
  Future<void> setPitStopSeconds(double seconds) async {
    state = seconds;
    await _storageService.savePitStopSeconds(seconds);
  }
}

/// 피트 스톱 시간 Provider
final pitStopProvider = StateNotifierProvider<PitStopNotifier, double>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return PitStopNotifier(storage);
});