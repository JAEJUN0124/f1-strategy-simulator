import 'package:shared_preferences/shared_preferences.dart';
import '../models/simulation_response.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // --- Pit Stop Time ---
  static const String _pitStopKey = 'pit_stop_seconds';

  /// 피트 스톱 시간 저장
  Future<void> savePitStopSeconds(double seconds) async {
    await _prefs.setDouble(_pitStopKey, seconds);
  }

  /// 피트 스톱 시간 로드 (기본값 23.0초)
  double loadPitStopSeconds() {
    return _prefs.getDouble(_pitStopKey) ?? 23.0;
  }

  // --- Recent Reports ---
  static const String _reportsKey = 'recent_reports';

  /// 최근 리포트 목록 저장
  Future<void> saveRecentReports(List<SimulationResponse> reports) async {
    // SimulationResponse 객체를 JSON 문자열로 변환하여 저장
    final List<String> jsonList = reports
        .map((report) => jsonEncode(report.toJson())) // toJson()이 필요
        .toList();
    await _prefs.setStringList(_reportsKey, jsonList);
  }

  /// 최근 리포트 목록 로드
  List<SimulationResponse> loadRecentReports() {
    final List<String> jsonList = _prefs.getStringList(_reportsKey) ?? [];
    return jsonList
        .map((jsonString) =>
            SimulationResponse.fromJson(jsonDecode(jsonString)))
        .toList();
  }
}

/// LocalStorageService를 제공하는 Provider
final localStorageServiceProvider =
    Provider<LocalStorageService>((ref) {
  // 앱 시작 시 SharedPreferences를 비동기적으로 로드해야 하므로,
  // main.dart에서 override하여 주입하는 것이 가장 좋음
  // 여기서는 임시로 UnimplementedError를 발생시킴
  throw UnimplementedError('LocalStorageService must be initialized in main.dart');
  }
);