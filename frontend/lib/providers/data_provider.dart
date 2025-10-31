// frontend/lib/providers/data_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/race_info.dart';
import '../models/driver_info.dart';
import 'api_provider.dart'; // 1. apiServiceProvider 임포트

// (v2).txt 3.4 - racesProvider (FutureProvider)
// 연도별 레이스 목록을 비동기로 로딩합니다.
// .autoDispose를 사용하여 필요 없을 때 메모리에서 자동으로 제거합니다.
final racesProvider = FutureProvider.autoDispose.family<List<RaceInfo>, int>((ref, year) async {
  // 2. apiServiceProvider를 읽어와 getRaces 함수 호출
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getRaces(year);
});


// (v2).txt 3.4 - driversProvider (FutureProvider)
// 특정 레이스의 드라이버 목록을 비동기로 로딩합니다.
// family에 여러 파라미터를 전달하기 위해 Map 또는 별도 클래스를 사용할 수 있습니다.
// 여기서는 간단하게 Map을 사용합니다.
final driversProvider = FutureProvider.autoDispose.family<List<DriverInfo>, Map<String, dynamic>>(
  (ref, params) async {
    final int year = params['year'];
    final String raceId = params['raceId'];
    
    // 3. apiServiceProvider를 읽어와 getDrivers 함수 호출
    final apiService = ref.watch(apiServiceProvider);
    return apiService.getDrivers(year, raceId);
  },
);

// (v2).txt 3.4 - 시뮬레이터 설정 상태 관리 (StateNotifierProvider)
// 시뮬레이션 결과 상태 관리 (simulationResultProvider)
// 이 Provider들은 실제 화면(SimulatorScreen)을 구현할 때 이어서 만들겠습니다.