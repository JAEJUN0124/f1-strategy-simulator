import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart'; // 1. ApiService 임포트

// 이 Provider를 통해 앱의 어디서든 ApiService 인스턴스에 접근할 수 있습니다.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});