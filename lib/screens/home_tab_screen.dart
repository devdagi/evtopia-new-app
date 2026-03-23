import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/banner_model.dart';
import '../models/home_data_model.dart';
import '../models/post_model.dart';
import '../models/product_model.dart';
import '../models/service_model.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/image_url.dart';
import '../widgets/optimized_network_image.dart';
import '../widgets/skeleton_loader.dart';
import 'product_detail_screen.dart';
import 'service_detail_screen.dart';

/// Home tab content: Banner, Latest Products, Our Service, Blog.
class HomeTabScreen extends ConsumerStatefulWidget {
  const HomeTabScreen({super.key});

  @override
  ConsumerState<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends ConsumerState<HomeTabScreen> {
  bool _notificationCountRefreshed = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user != null && !_notificationCountRefreshed) {
      _notificationCountRefreshed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationProvider.notifier).refreshUnreadCount(user.id);
      });
    }
    final homeAsync = ref.watch(homeDataProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(homeDataProvider);
        ref.invalidate(productsProvider);
        ref.invalidate(latestProductsProvider);
        if (user != null) {
          ref.read(notificationProvider.notifier).refreshUnreadCount(user.id);
        }
        await ref.read(homeDataProvider.future);
        await ref.read(productsProvider.future);
        await ref.read(latestProductsProvider.future);
      },
      child: homeAsync.when(
        data: (data) => _Content(data: data),
        loading: () => const SkeletonHomePage(),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.data});

  final HomeDataModel? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data == null) {
      return const Center(child: Text('No data'));
    }
    final d = data!;
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  border: Border(
                    bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
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
                              icon: const Icon(Icons.notifications_outlined),
                              tooltip: 'Notifications',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (d.banners.isNotEmpty) _BannerSection(banners: d.banners),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PopularProductsSection(products: d.popularProducts),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SectionHeader(
              title: 'Our Service',
              subtitle: 'Request garage services in minutes',
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (d.popularServices.isEmpty)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No services'))))
        else
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.only(top: 12, bottom: 16),
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: d.popularServices.length,
                    itemBuilder: (context, i) {
                      final s = d.popularServices[i];
                      return RepaintBoundary(
                        child: _ServiceCard(
                          service: s,
                          onTap: () => _openServiceDetail(context, s),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SectionHeader(
              title: 'Recently Posted',
              subtitle: 'Stay updated with new arrivals',
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => mainTabRequestNotifier.value = 1,
                tooltip: 'View all arrivals',
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: _ProductsSection(),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SectionHeader(
              title: 'Blog',
              subtitle: 'Latest insights & stories',
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => mainTabRequestNotifier.value = 2,
                tooltip: 'View all blogs',
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (d.posts.isEmpty)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No posts'))))
        else
          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: d.posts.length > 3 ? 3 : d.posts.length,
                itemBuilder: (context, i) {
                  final post = d.posts[i];
                  return RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        width: 240,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pushNamed('/blog-detail', arguments: post.id),
                          borderRadius: BorderRadius.circular(16),
                          child: _PostCard(post: post),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Latest Products from GET /api/latest-products.
class _PopularProductsSection extends StatelessWidget {
  const _PopularProductsSection({required this.products});

  final List<ProductModel> products;
  static const double _sectionHeight = 220;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          title: 'Popular Products',
          subtitle: 'Our community favorite picks',
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: _sectionHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => RepaintBoundary(
              child: _ProductCard(
                product: products[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (ctx) => ProductDetailScreen(productId: products[i].id),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _BannerSection extends StatefulWidget {
  const _BannerSection({required this.banners});

  final List<BannerModel> banners;

  @override
  State<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<_BannerSection> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 170,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.banners.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final b = widget.banners[i];
                final url = imageUrl(b.thumbnail);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: url.isEmpty
                              ? Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: Center(child: Text(b.title ?? 'Banner')),
                                )
                              : LayoutBuilder(
                                  builder: (_, c) => OptimizedNetworkImage(
                                    url: url,
                                    cacheWidth: c.maxWidth,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      child: Center(child: Text(b.title ?? 'Banner')),
                                    ),
                                  ),
                                ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.05),
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if ((b.title ?? '').isNotEmpty)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Text(
                              b.title!,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (widget.banners.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(widget.banners.length, (i) {
                          final active = i == _index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 6,
                            width: active ? 18 : 6,
                            decoration: BoxDecoration(
                              color: active ? Colors.white : Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, this.onTap});

  final ServiceModel service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl(service.thumbnail);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 200,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: url.isEmpty
                      ? const ColoredBox(color: Colors.grey, child: SizedBox.expand())
                      : OptimizedNetworkImage(
                          url: url,
                          cacheWidth: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.grey, child: SizedBox.expand()),
                        ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (service.categories != null && service.categories!.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: service.categories!
                              .take(3)
                              .map((c) => _GlassChip(text: c))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        service.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (service.shortDescription != null && service.shortDescription!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          service.shortDescription!,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.90)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _openServiceDetail(BuildContext context, ServiceModel service) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (ctx) => ServiceDetailScreen(serviceId: service.id),
    ),
  );
}

/// Our Latest Products from GET /api/products?page=1&per_page=10&sort_by=newest
class _ProductsSection extends ConsumerWidget {
  const _ProductsSection();

  static const double _sectionHeight = 220;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(latestProductsProvider);
    return async.when(
      data: (res) {
        if (res == null || res.products.isEmpty) {
          return _ProductsEmpty(theme: Theme.of(context));
        }
        final products = res.products.take(10).toList();
        return SizedBox(
          height: _sectionHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) => RepaintBoundary(
              child: _ProductCard(
                product: products[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (ctx) => ProductDetailScreen(productId: products[i].id),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: _sectionHeight,
        child: const SkeletonHorizontalCards(cardWidth: 180, cardHeight: 220, itemCount: 4),
      ),
      error: (e, st) => _ProductsError(
        theme: Theme.of(context),
        onRetry: () => ref.invalidate(latestProductsProvider),
      ),
    );
  }
}

class _ProductsEmpty extends StatelessWidget {
  const _ProductsEmpty({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.electric_car_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              "No EV's right now",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsError extends StatelessWidget {
  const _ProductsError({required this.theme, required this.onRetry});

  final ThemeData theme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: theme.colorScheme.error.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            Text(
              "Couldn't load EV's",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  static const double _cardWidth = 180;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl(product.thumbnail);
    final showDiscount = product.discountPrice != null && product.discountPrice! > 0;
    final primaryGreen = const Color(0xFF2E7D32);

    return SizedBox(
      width: _cardWidth,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 1.35,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (url.isEmpty)
                        ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          child: Icon(
                            Icons.electric_car_rounded,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        )
                      else
                        OptimizedNetworkImage(
                          url: url,
                          cacheWidth: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 40,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      if (product.visitCount != null && product.visitCount! > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.visitCount}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (showDiscount)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryGreen,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              product.discountPercentage != null
                                  ? '-${product.discountPercentage!.toStringAsFixed(0)}%'
                                  : 'Sale',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          showDiscount
                              ? 'ETB ${product.discountPrice!.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}'
                              : 'ETB ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: primaryGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (showDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            'ETB ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (product.createdAt != null && product.createdAt!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        product.createdAt!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl(post.banner);
    final category = post.categories.isNotEmpty ? post.categories.first : null;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 110,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: url.isEmpty
                        ? const ColoredBox(color: Colors.grey, child: SizedBox.expand())
                        : OptimizedNetworkImage(
                            url: url,
                            cacheWidth: 240,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.grey, child: SizedBox.expand()),
                          ),
                  ),
                  if (category != null && category.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Text(
                            category,
                            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (post.createdAt != null) ...[
                      Text(post.createdAt!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 6),
                    ],
                    Text(post.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (post.shortDescription != null && (post.shortDescription ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(post.shortDescription!, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
