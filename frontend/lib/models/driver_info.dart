// 
class DriverInfo {
  final String driverId;
  final String name;

  DriverInfo({
    required this.driverId,
    required this.name,
  });

  //fromJson 팩토리 생성자
  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      driverId: json['driverId'],
      name: json['name'],
    );
  }
}