import '../services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ApiService의 싱글톤 인스턴스를 제공하는 Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});