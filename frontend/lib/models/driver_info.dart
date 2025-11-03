class DriverInfo {
  final String driverId;
  final String name;

  DriverInfo({
    required this.driverId,
    required this.name,
  });

  // JSON 파싱을 위한 fromJson 팩토리 생성자
  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      driverId: json['driverId'] ?? '',
      name: json['name'] ?? 'Unknown Driver',
    );
  }
}