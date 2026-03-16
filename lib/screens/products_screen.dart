import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/image_url.dart';
import '../widgets/optimized_network_image.dart';
import '../widgets/skeleton_loader.dart';
import 'product_detail_screen.dart';

const _primaryGreen = Color(0xFF2E7D32);

/// Products tab: grid of products with search and filter (sort, price range).
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<ProductModel> _products = [];
  int _total = 0;
  int _page = 1;
  bool _loading = false;
  bool _loadingMore = false;
  static const int _perPage = 12;

  String _search = '';
  double _minPrice = 0;
  double _maxPrice = 10000000;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (pos.maxScrollExtent <= 0) return;
      if (pos.pixels >= pos.maxScrollExtent - 400) _loadMore();
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool resetPage = true}) async {
    if (_loading) return;
    if (resetPage) _page = 1;
    setState(() => _loading = true);
    final res = await ref.read(homeServiceProvider).getProducts(
          page: _page,
          perPage: _perPage,
          search: _search,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res != null) {
        _total = res.total;
        if (resetPage) {
          _products = res.products;
        } else {
          _products = [..._products, ...res.products];
        }
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _products.length >= _total) return;
    setState(() => _loadingMore = true);
    _page++;
    final res = await ref.read(homeServiceProvider).getProducts(
          page: _page,
          perPage: _perPage,
          search: _search,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
        );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (res != null) {
        _products = [..._products, ...res.products];
      }
    });
  }

  void _applySearch() {
    _search = _searchController.text.trim();
    _load();
  }

  Future<void> _toggleFavorite(ProductModel product) async {
    if (!ref.read(authProvider).isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login to favorite EV\'s')),
      );
      return;
    }
    try {
      await ref.read(homeServiceProvider).toggleFavorite(product.id);
      if (!mounted) return;
      setState(() {
        final i = _products.indexWhere((p) => p.id == product.id);
        if (i >= 0) {
          _products[i] = product.copyWith(isFavorite: !product.isFavorite);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite')),
      );
    }
  }

  void _showRightFilter() {
    final minController = TextEditingController(text: _minPrice > 0 ? _minPrice.toStringAsFixed(0) : '');
    final maxController = TextEditingController(text: _maxPrice < 10000000 ? _maxPrice.toStringAsFixed(0) : '');
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      barrierLabel: 'Filter',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurveTween(curve: Curves.easeOut).animate(anim1)),
          child: child,
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: double.infinity,
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Filter EVs',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Price range (ETB)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: minController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Min Price',
                          hintText: '0',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixText: 'ETB ',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: maxController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Max Price',
                          hintText: 'No max',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixText: 'ETB ',
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _minPrice = 0;
                                  _maxPrice = 10000000;
                                });
                                minController.clear();
                                maxController.clear();
                                Navigator.pop(context);
                                _load();
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _minPrice = double.tryParse(minController.text.trim()) ?? 0;
                                  _maxPrice = double.tryParse(maxController.text.trim()) ?? 10000000;
                                });
                                Navigator.pop(context);
                                _load();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: _primaryGreen,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 6,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
                  ),
                ),
                child: Column(
                  children: [
                    // Top Row: Logo and Notifications (Matching HomeTabScreen)
                    Row(
                      children: [
                        SizedBox(
                          height: 36,
                          child: Image.asset(
                            'assets/images/evtopia.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Text(
                              'Evtopia',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Consumer(
                          builder: (context, ref, _) {
                            final unreadCount = ref.watch(notificationProvider).unreadCount;
                            return Badge(
                              isLabelVisible: unreadCount > 0,
                              label: Text('${unreadCount > 99 ? 99 : unreadCount}'),
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pushNamed('/notifications'),
                                icon: const Icon(Icons.notifications_outlined, size: 24),
                                tooltip: 'Notifications',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search & Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: "Search models...",
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w600,
                                ),
                                prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), size: 22),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _search = '');
                                          _load();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onSubmitted: (_) => _applySearch(),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showRightFilter,
                          child: Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.tune_rounded, color: theme.colorScheme.onSurfaceVariant, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        Expanded(
          child: _loading && _products.isEmpty
              ? const SkeletonProductGrid(crossAxisCount: 2, itemCount: 6)
              : _products.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _primaryGreen.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.electric_car_rounded,
                                size: 48,
                                color: _primaryGreen.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No EV's found",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters to find what you are looking for.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _load(),
                      color: _primaryGreen,
                      backgroundColor: Colors.white,
                      displacement: 40,
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 24,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: _products.length + ((_loadingMore || _products.length < _total) ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= _products.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          final product = _products[i];
                          return RepaintBoundary(
                            child: _ProductGridCard(
                              product: product,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (ctx) => ProductDetailScreen(productId: product.id),
                                ),
                              ),
                              onFavorite: () => _toggleFavorite(product),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    ),
  );
  }
}

/// Compact grid card (from old app ProductCard style).
class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({
    required this.product,
    required this.onTap,
    this.onFavorite,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl(product.thumbnail);
    final showDiscount = product.discountPrice != null && product.discountPrice! > 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Expanded(
              flex: 13,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  url.isEmpty
                      ? Container(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          child: Icon(Icons.electric_car_rounded, size: 40, color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                        )
                      : OptimizedNetworkImage(url: url, cacheWidth: 400, fit: BoxFit.cover),
                  
                  // Bottom Gradient Overlay for Text Clarity
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Glassmatic Discount Badge
                  if (product.discountPercentage != null && product.discountPercentage! > 0)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${product.discountPercentage!.toStringAsFixed(0)}% OFF',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Glassmatic Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: IconButton(
                          onPressed: () => onFavorite?.call(),
                          icon: Icon(
                            product.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: product.isFavorite ? Colors.redAccent : Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            fixedSize: const Size(36, 36),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.brand ?? ''} ${product.model ?? product.name}'.trim(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: -0.6,
                      height: 1.1,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Spec Indicators
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [
                            if (product.drivingRange != null) product.drivingRange,
                            if (product.year != null) '${product.year}',
                          ].join(' • '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Price Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        showDiscount
                            ? product.discountPrice!.toStringAsFixed(0)
                            : product.price.toStringAsFixed(0),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'ETB',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _primaryGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showDiscount)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'ETB ${product.price.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          decoration: TextDecoration.lineThrough,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
