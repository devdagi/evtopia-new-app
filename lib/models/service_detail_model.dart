import 'service_model.dart';

/// Service detail from GET /api/service-details?service_id=X. Backend: ServiceDetailsResource.
class ServiceDetailModel {
  const ServiceDetailModel({
    required this.id,
    required this.name,
    this.duration,
    this.shortDescription,
    this.description,
    this.price = 0,
    this.discountPrice,
    this.discountPercentage,
    this.thumbnails = const [],
    this.categories,
    this.relatedServices = const [],
  });

  final int id;
  final String name;
  final String? duration;
  final String? shortDescription;
  final String? description;
  final double price;
  final double? discountPrice;
  final double? discountPercentage;
  final List<String> thumbnails;
  final List<String>? categories;
  final List<ServiceModel> relatedServices;

  static int _int(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0);
  static String? _str(dynamic v) => v?.toString();
  static double _double(dynamic v) =>
      v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0);

  factory ServiceDetailModel.fromJson(Map<String, dynamic> json) {
    List<String> thumbUrls = [];
    final thumbs = json['thumbnails'];
    if (thumbs is List) {
      for (final t in thumbs) {
        if (t is Map && t['thumbnail'] != null) {
          thumbUrls.add(t['thumbnail'].toString());
        } else if (t is String) {
          thumbUrls.add(t);
        }
      }
    }
    final cats = json['categories'];
    List<String>? catList;
    if (cats is List) {
      catList = cats.map((e) => e.toString()).toList();
    }
    return ServiceDetailModel(
      id: _int(json['id']),
      name: _str(json['name']) ?? '',
      duration: _str(json['duration']),
      shortDescription: _str(json['short_description']),
      description: _str(json['description']),
      price: _double(json['price']),
      discountPrice: json['discount_price'] != null && json['discount_price'] is num
          ? (json['discount_price'] as num).toDouble()
          : null,
      discountPercentage: json['discount_percentage'] != null && json['discount_percentage'] is num
          ? (json['discount_percentage'] as num).toDouble()
          : null,
      thumbnails: thumbUrls,
      categories: catList,
      relatedServices: const [],
    );
  }
}
