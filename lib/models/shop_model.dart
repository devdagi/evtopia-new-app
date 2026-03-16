/// Shop from API. Backend: ShopResource (GET /api/shops).
class ShopModel {
  const ShopModel({
    required this.id,
    required this.name,
    this.logo,
    this.banner,
    this.totalProducts = 0,
    this.totalCategories = 0,
    this.rating = 0,
    this.shopStatus,
    this.totalReviews,
  });

  final int id;
  final String name;
  final String? logo;
  final String? banner;
  final int totalProducts;
  final int totalCategories;
  final double rating;
  final String? shopStatus;
  final String? totalReviews;

  static int _int(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0);
  static String? _str(dynamic v) => v?.toString();
  static double _double(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0);

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: _int(json['id']),
      name: _str(json['name']) ?? '',
      logo: _str(json['logo']),
      banner: _str(json['banner']),
      totalProducts: _int(json['total_products']),
      totalCategories: _int(json['total_categories']),
      rating: _double(json['rating']),
      shopStatus: _str(json['shop_status']),
      totalReviews: _str(json['total_reviews']),
    );
  }
}
