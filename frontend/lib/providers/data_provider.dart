import '../models/driver_info.dart';
import '../models/race_info.dart';
import '../providers/api_service_provider.dart';
import '../providers/simulator_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 연도별 레이스 목록을 가져오는 FutureProvider
final racesProvider = FutureProvider<List<RaceInfo>>((ref) async {
  // 1. ApiService를 가져옵니다.
  final apiService = ref.watch(apiServiceProvider);
  
  // 2. 'simulatorConfigProvider'에서 현재 선택된 '연도'를 감시(watch)
  final selectedYear = ref.watch(
    simulatorConfigProvider.select((config) => config.selectedYear)
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