/// Related product (similar products) – from old app related_products.
class RelatedProductModel {
  const RelatedProductModel({
    required this.id,
    required this.name,
    this.thumbnail,
    this.price = 0,
    this.discountPrice,
    this.discountPercentage,
  });

  final int id;
  final String name;
  final String? thumbnail;
  final double price;
  final double? discountPrice;
  final double? discountPercentage;

  static int _int(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0);
  static String? _str(dynamic v) => v?.toString();
  static double _double(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0);

  factory RelatedProductModel.fromJson(Map<String, dynamic> json) {
    String? thumb;
    if (json['thumbnail'] != null) {
      thumb = json['thumbnail'].toString();
    } else if (json['thumbnails'] is List && (json['thumbnails'] as List).isNotEmpty) {
      final first = (json['thumbnails'] as List).first;
      if (first is Map && first['thumbnail'] != null) {
        thumb = first['thumbnail'].toString();
      }
    }
    return RelatedProductModel(
      id: _int(json['id']),
      name: _str(json['name']) ?? '',
      thumbnail: thumb,
      price: _double(json['price']),
      discountPrice: json['discount_price'] != null && json['discount_price'] is num
          ? (json['discount_price'] as num).toDouble()
          : null,
      discountPercentage: json['discount_percentage'] != null && json['discount_percentage'] is num
          ? (json['discount_percentage'] as num).toDouble()
          : null,
    );
  }
}

/// Product detail from GET /api/product-details?product_id=X. Backend: ProductDetailsResource.
class ProductDetailModel {
  const ProductDetailModel({
    required this.id,
    required this.name,
    this.shortDescription,
    this.description,
    this.price = 0,
    this.discountPrice,
    this.discountPercentage,
    this.rating,
    this.brand,
    this.model,
    this.year,
    this.drivingRange,
    this.batteryCapacity,
    this.peakPower,
    this.thumbnails = const [],
    this.shopName,
    this.shopLogo,
    this.shopId,
    this.sellerEmail,
    this.sellerPhone,
    this.relatedProducts = const [],
  });

  final int id;
  final String name;
  final String? shortDescription;
  final String? description;
  final double price;
  final double? discountPrice;
  final double? discountPercentage;
  final double? rating;
  final String? brand;
  final String? model;
  final int? year;
  final String? drivingRange;
  final String? batteryCapacity;
  final String? peakPower;
  final List<String> thumbnails;
  final String? shopName;
  final String? shopLogo;
  /// When null and [sellerEmail] or [sellerPhone] present, this is a user (private) listing.
  final int? shopId;
  final String? sellerEmail;
  final String? sellerPhone;
  final List<RelatedProductModel> relatedProducts;

  bool get isUserListing => shopId == null && (sellerEmail != null || sellerPhone != null);

  static int _int(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0);
  static String? _str(dynamic v) => v?.toString();
  static double _double(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0);

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
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
    final shop = json['shop'];
    String? shopName;
    String? shopLogo;
    int? shopId;
    if (shop is Map) {
      shopName = _str(shop['name']);
      shopLogo = _str(shop['logo']);
      shopId = shop['id'] != null ? _int(shop['id']) : null;
    }
    final user = json['user'];
    String? sellerEmail;
    String? sellerPhone;
    if (user is Map) {
      sellerEmail = _str(user['email']);
      sellerPhone = _str(user['phone']);
    }
    return ProductDetailModel(
      id: _int(json['id']),
      name: _str(json['name']) ?? '',
      shortDescription: _str(json['short_description']),
      description: _str(json['description']),
      price: _double(json['price']),
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
      drivingRange: _str(json['driving_range']),
      batteryCapacity: _str(json['battery_capacity']),
      peakPower: _str(json['peak_power']),
      thumbnails: thumbUrls,
      shopName: shopName,
      shopLogo: shopLogo,
      shopId: shopId,
      sellerEmail: sellerEmail,
      sellerPhone: sellerPhone,
      relatedProducts: const [],
    );
  }
}
