/// Product (EV) from API. Backend: ProductResource.
class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    this.thumbnail,
    this.price = 0,
    this.shortDescription,
    this.discountPrice,
    this.discountPercentage,
    this.rating,
    this.brand,
    this.model,
    this.year,
    this.visitCount,
    this.drivingRange,
    this.batteryCapacity,
    this.peakPower,
    this.accelerationTime,
    this.isFavorite = false,
    this.createdAt,
  });

  final int id;
  final String name;
  final String? thumbnail;
  final double price;
  final String? shortDescription;
  final double? discountPrice;
  final double? discountPercentage;
  final double? rating;
  final String? brand;
  final String? model;
  final int? year;
  /// Number of users who viewed this product (from API visit_count).
  final int? visitCount;
  /// Driving range e.g. "460 km".
  final String? drivingRange;
  /// Battery capacity e.g. "71.4 kWh".
  final String? batteryCapacity;
  /// Peak power e.g. "160 kW".
  final String? peakPower;
  /// 0-100 km/h acceleration e.g. "6.9s".
  final String? accelerationTime;
  /// Whether the current user has favorited this product.
  final bool isFavorite;
  /// The date the product was posted.
  final String? createdAt;

  ProductModel copyWith({
    int? id,
    String? name,
    String? thumbnail,
    double? price,
    String? shortDescription,
    double? discountPrice,
    double? discountPercentage,
    double? rating,
    String? brand,
    String? model,
    int? year,
    int? visitCount,
    String? drivingRange,
    String? batteryCapacity,
    String? peakPower,
    String? accelerationTime,
    bool? isFavorite,
    String? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      thumbnail: thumbnail ?? this.thumbnail,
      price: price ?? this.price,
      shortDescription: shortDescription ?? this.shortDescription,
      discountPrice: discountPrice ?? this.discountPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      visitCount: visitCount ?? this.visitCount,
      drivingRange: drivingRange ?? this.drivingRange,
      batteryCapacity: batteryCapacity ?? this.batteryCapacity,
      peakPower: peakPower ?? this.peakPower,
      accelerationTime: accelerationTime ?? this.accelerationTime,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static int _int(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0);
  static String? _str(dynamic v) => v?.toString();
  static double _double(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0);

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: _int(json['id']),
      name: _str(json['name']) ?? '',
      thumbnail: _str(json['thumbnail']),
      price: _double(json['price']),
      shortDescription: _str(json['short_description']),
      discountPrice: json['discount_price'] != null && json['discount_price'] is num
          ? (json['discount_price'] as num).toDouble()
          : null,
      discountPercentage: json['discount_percentage'] != null && json['discount_percentage'] is num
          ? (json['discount_percentage'] as num).toDouble()
          : null,
      rating: json['rating'] != null && json['rating'] is num ? (json['rating'] as num).toDouble() : null,
      brand: _str(json['brand']),
      model: _str(json['model']),
      year: json['year'] != null ? _int(json['year']) : null,
      visitCount: json['visit_count'] != null ? _int(json['visit_count']) : null,
      drivingRange: _str(json['driving_range']),
      batteryCapacity: _str(json['battery_capacity']),
      peakPower: _str(json['peak_power']),
      accelerationTime: _str(json['acceleration_time']),
      isFavorite: json['is_favorite'] == true,
      createdAt: _str(json['created_at']),
    );
  }
}
