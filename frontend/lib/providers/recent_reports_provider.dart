import 'package:frontend/models/simulation_response.dart';
import 'package:frontend/services/local_storage_service.dart';
import 'package:flutter_riverpod/legacy.dart';

/// 최근 시뮬레이션 리포트 목록을 관리하는 Notifier
class RecentReportsNotifier extends StateNotifier<List<SimulationResponse>> {
  final LocalStorageService _storageService;

  RecentReportsNotifier(this._storageService)
      // 앱 시작 시 로컬 저장소에서 리포트 로드
      : super(_storageService.loadRecentReports());

  /// 새 리포트 추가 및 저장 (최대 10개)
  Future<void> addReport(SimulationResponse report) async {
    // 기존 리스트의 맨 앞에 새 리포트 추가
    final updatedList = [report, ...state];
    
    // 임시로 최근 10개만 저장
    final finalList = updatedList.take(10).toList(); 

    state = finalList;
    await _storageService.saveRecentReports(finalList);
  }

  /// 리포트 삭제
  Future<void> removeReport(String reportId) async {
    final updatedList = state.where((r) => r.reportId != reportId).toList();
    state = updatedList;
    await _storageService.saveRecentReports(updatedList);
  }
}

/// 최근 리포트 목록 Provider
final recentReportsProvider =
    StateNotifierProvider<RecentReportsNotifier, List<SimulationResponse>>(
        (ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return RecentReportsNotifier(storage);
});