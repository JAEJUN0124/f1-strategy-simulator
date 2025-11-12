import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/driver_info.dart';
import '../models/race_info.dart';
import '../models/simulation_request.dart';
import '../models/simulation_response.dart';

class ApiService {
  late final Dio _dio;

  // Dio 클라이언트 초기화
  ApiService() {
    // 1. 플랫폼(웹/모바일)에 따라 다른 URL을 사용
    const String androidBaseUrl = 'http://10.0.2.2:8000';
    const String webBaseUrl = 'http://127.0.0.1:8000';

    // 2. kIsWeb은 Flutter가 제공하는 '지금 웹 환경에서 실행 중인가?'를 확인하는 변수
    // (kIsWeb은 'package:flutter/foundation.dart'에 포함되어 있음)
    final String baseUrl = kIsWeb ? webBaseUrl : androidBaseUrl;

    _dio = Dio(
      BaseOptions(
        // FastAPI 기본 URL
        baseUrl: baseUrl, // 3. 결정된 baseUrl을 적용
        
        // --- 수정된 부분 ---
        // 5초 -> 120초 (2분)로 대폭 늘림
        connectTimeout: const Duration(seconds: 120), 
        // 받는 시간도 120초로 늘림
        receiveTimeout: const Duration(seconds: 120), 
        // ------------------
      ),
    );
    
    // (선택사항) 로깅 인터셉터
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
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
      throw Exception('Failed to load drivers: ${e.response?.data ?? e.message}');
    }
  }

  /// API: POST /api/simulate
  Future<SimulationResponse?> runSimulation(SimulationRequest request) async {
    try {
      // Request Body 직렬화
      final response = await _dio.post(
        '/api/simulate',
        data: request.toJson(),
      );
      
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