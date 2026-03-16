/// Latest EV from GET /api/latest-evs. Backend returns raw array of LatestEv model.
class LatestEvModel {
  const LatestEvModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.batteryRange,
    this.motorPower,
    this.price,
    this.redirectUrl,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final String? batteryRange;
  final String? motorPower;
  final double? price;
  final String? redirectUrl;

  factory LatestEvModel.fromJson(Map<String, dynamic> json) {
    return LatestEvModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      batteryRange: json['battery_range']?.toString(),
      motorPower: json['motor_power']?.toString(),
      price: json['price'] != null && json['price'] is num
          ? (json['price'] as num).toDouble()
          : null,
      redirectUrl: json['redirect_url']?.toString(),
    );
  }
}
