/// Service from API. Backend: ServiceResource.
class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.name,
    this.thumbnail,
    this.duration,
    this.price = 0,
    this.shortDescription,
    this.discountPrice,
    this.categories,
  });

  final int id;
  final String name;
  final String? thumbnail;
  final String? duration;
  final double price;
  final String? shortDescription;
  final double? discountPrice;
  final List<String>? categories;

  static String? _string(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final cats = json['categories'];
    List<String>? list;
    if (cats is List) {
      list = cats.map((e) => e.toString()).toList();
    }
    return ServiceModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      name: _string(json['name']) ?? '',
      thumbnail: _string(json['thumbnail']),
      duration: _string(json['duration']),
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      shortDescription: _string(json['short_description']),
      discountPrice: json['discount_price'] != null && json['discount_price'] is num
          ? (json['discount_price'] as num).toDouble()
          : null,
      categories: list,
    );
  }
}
