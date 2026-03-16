import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../utils/image_url.dart';
import '../widgets/optimized_network_image.dart';
import '../widgets/skeleton_loader.dart';
import 'product_detail_screen.dart';

/// Screen showing the user's liked (favorited) EVs. Uses [favoriteProductsProvider].
class LikedEvsScreen extends ConsumerWidget {
  const LikedEvsScreen({super.key});

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoriteProductsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Liked EV's"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(favoriteProductsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: async.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No liked EV's yet",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart on any EV to add it here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(favoriteProductsProvider);
              await ref.read(favoriteProductsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final product = products[i];
                return _LikedEvTile(
                  product: product,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductDetailScreen(productId: product.id),
                    ),
                  ),
                  onRemove: () => _removeFavorite(context, ref, product),
                );
              },
            ),
          );
        },
        loading: () => const SkeletonProductList(itemCount: 6),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load liked EVs',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(favoriteProductsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _removeFavorite(BuildContext context, WidgetRef ref, ProductModel product) async {
    if (!ref.read(authProvider).isAuthenticated) return;
    try {
      await ref.read(homeServiceProvider).toggleFavorite(product.id);
      if (context.mounted) {
        ref.invalidate(favoriteProductsProvider);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove from liked')),
        );
      }
    }
  }
}

class _LikedEvTile extends StatelessWidget {
  const _LikedEvTile({
    required this.product,
    required this.onTap,
    required this.onRemove,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl(product.thumbnail);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: url.isEmpty
                      ? ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.electric_car_rounded,
                            size: 40,
                            color: _primaryGreen.withValues(alpha: 0.5),
                          ),
                        )
                      : OptimizedNetworkImage(
                          url: url,
                          cacheWidth: 176,
                          cacheHeight: 176,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ETB ${(product.discountPrice ?? product.price).toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _primaryGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                onPressed: onRemove,
                tooltip: 'Remove from liked',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
