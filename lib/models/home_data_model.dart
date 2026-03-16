import 'banner_model.dart';
import 'product_model.dart';
import 'service_model.dart';
import 'post_model.dart';

/// Home API response: GET /api/home returns data with these keys.
class HomeDataModel {
  const HomeDataModel({
    this.banners = const [],
    this.popularProducts = const [],
    this.popularServices = const [],
    this.posts = const [],
  });

  final List<BannerModel> banners;
  final List<ProductModel> popularProducts;
  final List<ServiceModel> popularServices;
  final List<PostModel> posts;

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    return HomeDataModel(
      banners: _listFromJson(json['banners'], BannerModel.fromJson),
      popularProducts: _listFromJson(json['popular_products'], ProductModel.fromJson),
      popularServices: _listFromJson(json['popular_services'], ServiceModel.fromJson),
      posts: _listFromJson(json['posts'], PostModel.fromJson),
    );
  }

  static List<T> _listFromJson<T>(dynamic list, T Function(Map<String, dynamic>) fromJson) {
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }
}
