// frontend/lib/services/api_service.dart

import 'package:dio/dio.dart';
import '../models/race_info.dart';
import '../models/driver_info.dart';
import '../models/simulation_models.dart';

// (v2).txt 3.3 - Dio 클라이언트 초기화
class ApiService {
  // Dio 인스턴스 생성
  final Dio _dio = Dio(
    BaseOptions(
      // (v2).txt 3.3 - Base URL 설정
      // 백엔드 서버 주소 (현재 로컬에서 실행 중)
      baseUrl: 'http://127.0.0.1:8000', 
    ),
  );

  // (v2).txt 3.3 - getRaces 함수
  Future<List<RaceInfo>> getRaces(int year) async {
    try {
      final response = await _dio.get('/api/races/$year');
      
      // List<dynamic> -> List<RaceInfo>
      return (response.data as List)
          .map((json) => RaceInfo.fromJson(json))
          .toList();
          
    } on DioException catch (e) {
      // (v2).txt 3.3 - 오류 처리 로직
      print("Error getting races: $e");
      // 사용자에게 보여줄 오류 메시지 반환 또는 예외 발생
      throw Exception('Failed to load races: $e');
    }
  }

  // (v2).txt 3.3 - getDrivers 함수
  Future<List<DriverInfo>> getDrivers(int year, String raceId) async {
    try {
      final response = await _dio.get('/api/drivers/$year/$raceId');
      
      return (response.data as List)
          .map((json) => DriverInfo.fromJson(json))
          .toList();

    } on DioException catch (e) {
      print("Error getting drivers: $e");
      throw Exception('Failed to load drivers: $e');
    }
  }

  // (v2).txt 3.3 - runSimulation 함수
  Future<SimulationResponse> runSimulation(SimulationRequest request) async {
    try {
      // (v2).txt 3.3 - Request Body 직렬화 (request.toJson() 사용)
      final response = await _dio.post(
        '/api/simulate',
        data: request.toJson(),
      );
      
      // (v2).txt 3.3 - SimulationResponse 반환
      return SimulationResponse.fromJson(response.data);

    } on DioException catch (e) {
      print("Error running simulation: $e");
      // (v2).txt 1.3 - 오류 응답 본문 처리
      if (e.response?.data != null && e.response?.data['detail'] != null) {
         throw Exception('Simulation failed: ${e.response!.data['detail']}');
      }
      throw Exception('Failed to run simulation: $e');
    }
  }
}