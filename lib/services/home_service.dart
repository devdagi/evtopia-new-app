import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/home_data_model.dart';
import '../models/latest_ev_model.dart';
import '../models/post_model.dart';
import '../models/product_model.dart';
import '../models/contact_us_model.dart';
import '../models/product_detail_model.dart'; // ProductDetailModel, RelatedProductModel
import '../models/service_detail_model.dart';
import '../models/service_model.dart';
import '../models/shop_model.dart';

/// Fetches home, services, and blogs from evtopia-ecom API.
class HomeService {
  HomeService(this._api);

  final ApiClient _api;

  /// GET /api/home - returns banners, popular_products, popular_services, posts. Backend wraps in { message, data }.
  Future<HomeDataModel?> getHome() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(ApiConstants.homePath);
      if (response.statusCode != 200 || response.data == null) return null;
      final data = response.data!['data'];
      if (data is! Map<String, dynamic>) return null;
      return HomeDataModel.fromJson(data);
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/services - optional page, per_page. Backend: { data: { total, services } }.
  Future<ServicesResponse?> getServices({int page = 1, int perPage = 10}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        ApiConstants.servicesPath,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final data = response.data!['data'];
      if (data is! Map<String, dynamic>) return null;
      final list = data['services'];
      final total = data['total'] as int? ?? 0;
      final services = list is List
          ? list.whereType<Map<String, dynamic>>().map(ServiceModel.fromJson).toList()
          : <ServiceModel>[];
      return ServicesResponse(total: total, services: services);
    } on DioException catch (_) {
      return null;
    }
  }

  /// GET /api/latest-evs - returns raw JSON array (no data wrapper).
  Future<List<LatestEvModel>> getLatestEvs() async {
    try {
      final response = await _api.dio.get<dynamic>(ApiConstants.latestEvsPath);
      if (response.statusCode != 200 || response.data == null) return [];
      final list = response.data;
      if (list is! List) return [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(LatestEvModel.fromJson)
          .toList();
    } on DioException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// GET /api/latest-products - returns { message, data: { products: [...] } }. Latest products for home section.
  /// Returns null if server returns non-JSON (e.g. HTML when route is not deployed).
  Future<ProductsResponse?> getLatestProducts({int limit = 8}) async {
    try {
      final response = await _api.dio.get<dynamic>(
        ApiConstants.latestProductsPath,
        queryParameters: {'limit': limit},
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final body = response.data;
      if (body is! Map<String, dynamic>) return null;
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;
      final raw = data['products'];
      if (raw is! List) return ProductsResponse(total: 0, products: []);
      final products = <ProductModel>[];
      for (final e in raw) {
        final map = _toMapStringDynamic(e);
        if (map != null) {
          try {
            products.add(ProductModel.fromJson(map));
          } catch (_) {
            // skip invalid item
          }
        }
      }
      return ProductsResponse(total: products.length, products: products);
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _toMapStringDynamic(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((k, v) => MapEntry(k?.toString() ?? '', v)),
      );
    }
    return null;
  }

  /// GET /api/mobile_blogs - optional page, per_page. Backend: { data: { total, posts } }.
  Future<PostsResponse?> getBlogs({int page = 1, int perPage = 10}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        ApiConstants.blogsPath,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final data = response.data!['data'];
      if (data is! Map<String, dynamic>) return null;
      final list = data['posts'];
      final total = data['total'] as int? ?? 0;
      final posts = list is List
          ? list.whereType<Map<String, dynamic>>().map(PostModel.fromJson).toList()
          : <PostModel>[];
      return PostsResponse(total: total, posts: posts);
    } on DioException catch (_) {
      return null;
    }
  }

  /// GET /api/blog-details?post_id=X. Backend: { data: { post, related_posts } }.
  Future<BlogDetailModel?> getBlogDetails(int postId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        ApiConstants.blogDetailsPath,
        queryParameters: {'post_id': postId},
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final data = response.data!['data'];
      if (data is! Map<String, dynamic>) return null;
      final postJson = data['post'];
      final relatedList = data['related_posts'];
      if (postJson is! Map<String, dynamic>) return null;
      final post = PostModel.fromJson(postJson);
      final related = relatedList is List
          ? relatedList.whereType<Map<String, dynamic>>().map(PostModel.fromJson).toList()
          : <PostModel>[];
      return BlogDetailModel(post: post, relatedPosts: related);
    } on DioException catch (_) {
      return null;
    }
  }

  /// GET /api/products?page=1&per_page=12&search=&min_price=0&max_price=10000000. Backend: { data: { total, products } }.
  /// sort_by: newest, low_to_high, heigh_to_low, top_selling, popular_product
  Future<ProductsResponse?> getProducts({
    int page = 1,
    int perPage = 12,
    String search = '',
    double minPrice = 0,
    double maxPrice = 10000000,
    String? sortBy,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'search': search,
        'min_price': minPrice,
        'max_price': maxPrice,
      };
      if (sortBy != null && sortBy.isNotEmpty) params['sort_by'] = sortBy;
      final response = await _api.dio.get<Map<String, dynamic>>(
        ApiConstants.productsPath,
        queryParameters: params,
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final data = response.data!['data'];
      if (data is! Map<String, dynamic>) return null;
      final list = data['products'];
      final total = data['total'] as int? ?? 0;
      final products = list is List
          ? list.whereType<Map<String, dynamic>>().map(ProductModel.fromJson).toList()
          : <ProductModel>[];
      return ProductsResponse(total: total, products: products);
    } on DioException catch (_) {
      return null;
    }
  }

  /// GET /api/product-details?product_id=X. Backend: { data: { product, related_products } } – full UI/API from old app.
  Future<ProductDetailModel?> getProductDetails(int productId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        ApiConstants.productDetailsPath,
        queryParameters: {'product_id': productId},
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final data = response.data!['data'];
      if (data is! Map<String, dynamic>) return null;
      final product = data['product'];
      if (product is! Map<String, dynamic>) return null;
      final main = ProductDetailModel.fromJson(product);
      final relatedList = data['related_products'];
      List<RelatedProductModel> related = [];
      if (relatedList is List) {
        for (final e in relatedList) {
          if (e is Map<String, dynamic>) {
            related.add(RelatedProductModel.fromJson(e));
          }
        }
      }
      return ProductDetailModel(
        id: main.id,
        name: main.name,
        shortDescription: main.shortDescription,
        description: main.description,
        price: main.price,
        discountPrice: main.discountPrice,
        discountPercentage: main.discountPercentage,
        rating: main.rating,
        brand: main.brand,
        model: main.model,
        year: main.year,
        drivingRange: main.drivingRange,
        batteryCapacity: main.batteryCapacity,
        peakPower: main.peakPower,
        thumbnails: main.thumbnails,
        shopName: main.shopName,
        shopLogo: main.shopLogo,
        shopId: main.shopId,
        sellerEmail: main.sellerEmail,
        sellerPhone: main.sellerPhone,
        relatedProducts: related,
      );
    } on DioException catch (_) {
      return null;
    }
  }

  /// POST /api/favorite-add-or-remove - toggle favorite for product. Auth required.
  /// Throws DioException on 401 or network error.
  Future<void> toggleFavorite(int productId) async {
    await _api.dio.post(
      ApiConstants.favoriteAddOrRemovePath,
      data: {'product_id': productId},
    );
  }

  /// GET /api/favorite-products - list of user's favorite products. Auth required.
  Future<List<ProductModel>> getFavoriteProducts() async {
    final response = await _api.dio.get<Map<String, dynamic>>(ApiConstants.favoriteProductsPath);
    if (response.statusCode != 200 || response.data == null) return [];
    final data = response.data!['data'];
    if (data is! Map<String, dynamic>) return [];
    final list = data['products'];
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  /// GET /api/contact-us – contact info (phone, email, social_links). From old app.
  Future<ContactUsModel?> getContactUs() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(ApiConstants.contactUsPath);
      if (response.statusCode != 200 || response.data == null) return null;
      final data = response.data!;
      final inner = data['data'];
      if (inner is Map<String, dynamic>) {
        return ContactUsModel(
          message: data['message'] as String? ?? '',
          data: ContactUsData.fromMap(inner),
        );
      }
      return ContactUsModel.fromJson(data);
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/service-details?service_id=X. Backend: { data: { product, related_products, popular_products } }.
  Future<ServiceDetailModel?> getServiceDetails(int serviceId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        ApiConstants.serviceDetailsPath,
        queryParameters: {'service_id': serviceId},
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final data = response.data!['data'];
      if (data is! Map<String, dynamic>) return null;
      final product = data['product'];
      if (product is! Map<String, dynamic>) return null;
      final main = ServiceDetailModel.fromJson(product);
      final relatedList = data['related_products'];
      List<ServiceModel> related = [];
      if (relatedList is List) {
        for (final e in relatedList) {
          if (e is Map<String, dynamic>) {
            related.add(ServiceModel.fromJson(e));
          }
        }
      }
      return ServiceDetailModel(
        id: main.id,
        name: main.name,
        duration: main.duration,
        shortDescription: main.shortDescription,
        description: main.description,
        price: main.price,
        discountPrice: main.discountPrice,
        discountPercentage: main.discountPercentage,
        thumbnails: main.thumbnails,
        categories: main.categories,
        relatedServices: related,
      );
    } on DioException catch (_) {
      return null;
    }
  }

  /// GET /api/shops - optional page, per_page. Backend: { data: { total, shops } }.
  Future<ShopsResponse?> getShops({int page = 1, int perPage = 10}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        ApiConstants.shopsPath,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final data = response.data!['data'];
      if (data is! Map<String, dynamic>) return null;
      final list = data['shops'];
      final total = data['total'] as int? ?? 0;
      final shops = list is List
          ? list.whereType<Map<String, dynamic>>().map(ShopModel.fromJson).toList()
          : <ShopModel>[];
      return ShopsResponse(total: total, shops: shops);
    } on DioException catch (_) {
      return null;
    }
  }
}

class ServicesResponse {
  const ServicesResponse({required this.total, required this.services});
  final int total;
  final List<ServiceModel> services;
}

class PostsResponse {
  const PostsResponse({required this.total, required this.posts});
  final int total;
  final List<PostModel> posts;
}

class BlogDetailModel {
  const BlogDetailModel({required this.post, this.relatedPosts = const []});
  final PostModel post;
  final List<PostModel> relatedPosts;
}

class ProductsResponse {
  const ProductsResponse({required this.total, required this.products});
  final int total;
  final List<ProductModel> products;
}

class ShopsResponse {
  const ShopsResponse({required this.total, required this.shops});
  final int total;
  final List<ShopModel> shops;
}
