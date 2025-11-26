import '../models/driver_info.dart';
import '../models/race_info.dart';
import '../providers/api_service_provider.dart';
import '../providers/simulator_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// 연도별 레이스 목록을 가져오는 FutureProvider
final racesProvider = FutureProvider<List<RaceInfo>>((ref) async {
  // 1. ApiService를 가져옵니다.
  final apiService = ref.watch(apiServiceProvider);

  // 2. 'simulatorConfigProvider'에서 현재 선택된 '연도'를 감시(watch)
  final selectedYear = ref.watch(
    simulatorConfigProvider.select((config) => config.selectedYear),
  );

  // 3. '연도'가 변경되면 apiService.getRaces가 다시 호출됨
  return apiService.getRaces(selectedYear);
});

/// 특정 레이스의 드라이버 목록을 가져오는 FutureProvider
final driversProvider = FutureProvider<List<DriverInfo>>((ref) async {
  // 1. ApiService를 가져옴
  final apiService = ref.watch(apiServiceProvider);

  // 2. 'simulatorConfigProvider'에서 연도와 레이스 ID를 감시(watch)
  final config = ref.watch(simulatorConfigProvider);
  final selectedYear = config.selectedYear;
  final selectedRaceId = config.selectedRaceId;

  // 3. 만약 레이스가 아직 선택되지 않았다면(null), 빈 목록을 반환
  if (selectedRaceId == null) {
    return [];
  }

  // 4. '레이스 ID'가 변경되면 apiService.getDrivers가 다시 호출
  return apiService.getDrivers(selectedYear, selectedRaceId);
});

// --- 대시보드 전용 Provider ---

/// 대시보드에서 선택된 연도 상태 관리 (기본값: 2024)
final dashboardYearProvider = StateProvider<int>((ref) => 2024);

/// 대시보드 연도에 따른 레이스 목록 조회
final dashboardRacesProvider = FutureProvider<List<RaceInfo>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  // 대시보드 전용 연도 Provider를 구독
  final selectedYear = ref.watch(dashboardYearProvider);

  return apiService.getRaces(selectedYear);
});
