// (v2).txt 3.2, 1.3 (DriverInfo 모델)
class DriverInfo {
  final String driverId;
  final String name;

  DriverInfo({
    required this.driverId,
    required this.name,
  });

  // (v2).txt 3.2 - fromJson 팩토리 생성자
  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      driverId: json['driverId'],
      name: json['name'],
    );
  }
}