import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import '../models/contact_us_model.dart';
import '../models/home_data_model.dart';
import '../models/latest_ev_model.dart';
import '../models/post_model.dart';
import '../models/product_detail_model.dart';
import '../models/service_detail_model.dart';
import '../models/product_model.dart';
import '../services/home_service.dart';

final homeServiceProvider = Provider<HomeService>((ref) {
  return HomeService(ref.watch(apiClientProvider));
});

final homeDataProvider = FutureProvider<HomeDataModel?>((ref) async {
  return ref.watch(homeServiceProvider).getHome();
});

final latestEvsProvider = FutureProvider<List<LatestEvModel>>((ref) async {
  return ref.watch(homeServiceProvider).getLatestEvs();
});

/// GET /api/latest-products – for home "Latest Products" section (same as web).
final latestProductsSectionProvider = FutureProvider<ProductsResponse?>((ref) async {
  return ref.watch(homeServiceProvider).getLatestProducts(limit: 8);
});

/// GET /api/products?page=1&per_page=12&search=&min_price=0&max_price=10000000
final productsProvider = FutureProvider<ProductsResponse?>((ref) async {
  return ref.watch(homeServiceProvider).getProducts(
        page: 1,
        perPage: 12,
        search: '',
        minPrice: 0,
        maxPrice: 10000000,
      );
});

/// Latest 10 products for home page "Our Latest EV's" section (GET /api/products with sort_by=newest).
final latestProductsProvider = FutureProvider<ProductsResponse?>((ref) async {
  return ref.watch(homeServiceProvider).getProducts(
        page: 1,
        perPage: 10,
        search: '',
        minPrice: 0,
        maxPrice: 10000000,
        sortBy: 'newest',
      );
});

/// Request a tab switch from child screens. Set to desired index (0-3); MainShellScreen listens and resets to null.
final mainTabRequestNotifier = ValueNotifier<int?>(null);

/// User's favorite (liked) products. Returns empty list if not authenticated.
final favoriteProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.user == null || !auth.isAuthenticated) return [];
  return ref.watch(homeServiceProvider).getFavoriteProducts();
});

/// GET /api/product-details?product_id=X
final productDetailProvider = FutureProvider.family<ProductDetailModel?, int>((ref, productId) async {
  return ref.watch(homeServiceProvider).getProductDetails(productId);
});

/// GET /api/service-details?service_id=X
final serviceDetailProvider = FutureProvider.family<ServiceDetailModel?, int>((ref, serviceId) async {
  return ref.watch(homeServiceProvider).getServiceDetails(serviceId);
});

/// GET /api/shops
final shopsProvider = FutureProvider<ShopsResponse?>((ref) async {
  return ref.watch(homeServiceProvider).getShops(page: 1, perPage: 10);
});

/// GET /api/contact-us – from old app (product detail Contact Us bottom sheet).
final contactUsProvider = FutureProvider<ContactUsModel?>((ref) async {
  return ref.watch(homeServiceProvider).getContactUs();
});

/// GET /api/blog-details?post_id=X
final blogDetailProvider = FutureProvider.family<BlogDetailModel?, int>((ref, postId) async {
  return ref.watch(homeServiceProvider).getBlogDetails(postId);
});

/// Paginated blogs list for Blogs screen. Loads page 1 then loadMore() for next pages.
class BlogsNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  BlogsNotifier(this._service) : super(const AsyncValue.data([])) {
    loadMore();
  }

  final HomeService _service;
  int _page = 0;
  int _total = 0;
  bool _hasMore = true;
  static const int _perPage = 10;

  int get total => _total;
  bool get hasMore => _hasMore;

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.value ?? [];
    final isInitial = current.isEmpty;
    if (isInitial) state = const AsyncValue.loading();
    try {
      final res = await _service.getBlogs(page: _page + 1, perPage: _perPage);
      if (res == null) {
        state = AsyncValue.data(current);
        _hasMore = false;
        return;
      }
      _total = res.total;
      _page = _page + 1;
      _hasMore = current.length + res.posts.length < res.total;
      state = AsyncValue.data([...current, ...res.posts]);
    } catch (e, st) {
      state = AsyncValue.data(current);
    }
  }

  Future<void> refresh() async {
    _page = 0;
    _hasMore = true;
    state = const AsyncValue.data([]);
    await loadMore();
  }
}

final blogsListProvider = StateNotifierProvider<BlogsNotifier, AsyncValue<List<PostModel>>>((ref) {
  return BlogsNotifier(ref.watch(homeServiceProvider));
});
