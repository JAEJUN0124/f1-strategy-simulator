import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/driver_info.dart';
import '../models/race_info.dart';
import '../models/simulation_request.dart';
import '../models/simulation_response.dart';

class ApiService {
  late final Dio _dio;

  // 오라클 서버의 공용 IP 적용
  static const String _baseUrl = 'http://129.80.168.203:8000';

  // Dio 클라이언트 초기화
  ApiService() {
    // 기존에는 여기서 로컬 주소(10.0.2.2 등)로 baseUrl을 다시 설정하고 있었음
    // 이제 바로 위의 _baseUrl(오라클 IP)을 사용하도록 수정

    _dio = Dio(
      BaseOptions(
        // 오라클 서버 주소 연결
        baseUrl: _baseUrl,

        // 타임아웃 설정 (넉넉하게 120초)
        connectTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),

        // 헤더 설정 (JSON 통신 명시)
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // (선택사항) 로깅 인터셉터
    _dio.interceptors.add(
      LogInterceptor(responseBody: true, requestBody: true),
    );
  }

  /// API: GET /api/races/{year}
  Future<List<RaceInfo>> getRaces(int year) async {
    try {
      final response = await _dio.get('/api/races/$year');

      // JSON List -> List<RaceInfo>
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => RaceInfo.fromJson(json)).toList();
    } on DioException catch (e) {
      // API 오류 처리 (예시)
      _handleDioError(e, 'Failed to load races');
      throw Exception('Failed to load races: ${e.response?.data ?? e.message}');
    }
  }

  /// API: GET /api/drivers/{year}/{race_id}
  Future<List<DriverInfo>> getDrivers(int year, String raceId) async {
    try {
      final response = await _dio.get('/api/drivers/$year/$raceId');

      // JSON List -> List<DriverInfo>
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => DriverInfo.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to load drivers');
      throw Exception(
        'Failed to load drivers: ${e.response?.data ?? e.message}',
      );
    }
  }

  /// API: POST /api/simulate
  Future<SimulationResponse?> runSimulation(SimulationRequest request) async {
    try {
      // Request Body 직렬화
      final response = await _dio.post('/api/simulate', data: request.toJson());

      // JSON Map -> SimulationResponse
      return SimulationResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e, 'Simulation failed');
      return null;
    }
  }

  /// 공통 Dio 오류 처리
  void _handleDioError(DioException e, String message) {
    // 실제 앱에서는 이 부분에서 사용자에게 Snackbar나 AlertDialog를 표시합니다.
    // API 오류 발생 시 사용자 알림
    if (e.response != null) {
      debugPrint('$message: ${e.response?.statusCode} - ${e.response?.data}');
    } else {
      debugPrint('$message: ${e.message}');
    }
  }
}
