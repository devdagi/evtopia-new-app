import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_model.dart';
import '../providers/home_provider.dart';
import '../utils/image_url.dart';
import '../widgets/optimized_network_image.dart';
import '../widgets/skeleton_loader.dart';

/// Lists all blogs (paginated). Medium-style design. Tap opens blog detail.
class BlogsScreen extends ConsumerStatefulWidget {
  const BlogsScreen({super.key});

  @override
  ConsumerState<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends ConsumerState<BlogsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final notifier = ref.read(blogsListProvider.notifier);
    if (!notifier.hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      notifier.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(blogsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Blog',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(blogsListProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: async.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No stories yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(blogsListProvider.notifier).refresh(),
            color: const Color(0xFF2E7D32),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: posts.length + 1,
              itemBuilder: (context, i) {
                if (i == posts.length) {
                  return _LoadMoreFooter(notifier: ref.read(blogsListProvider.notifier));
                }
                final post = posts[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: _MediumStyleCard(
                    post: post,
                    onTap: () => Navigator.of(context).pushNamed('/blog-detail', arguments: post.id),
                  ),
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
                Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to load stories', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.read(blogsListProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Medium-style article card: image on top, then title, description, author line.
class _MediumStyleCard extends StatelessWidget {
  const _MediumStyleCard({required this.post, required this.onTap});

  final PostModel post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl(post.banner);
    final category = post.categories.isNotEmpty ? post.categories.first : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Featured image
            AspectRatio(
              aspectRatio: 2.0,
              child: url.isEmpty
                  ? ColoredBox(
                      color: const Color(0xFFF0F0F0),
                      child: Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: Colors.black26,
                      ),
                    )
                  : OptimizedNetworkImage(
                      url: url,
                      cacheWidth: 800,
                      cacheHeight: 400,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: const Color(0xFFF0F0F0),
                        child: Icon(Icons.article_outlined, size: 48, color: Colors.black26),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category != null && category.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        category.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  Text(
                    post.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (post.shortDescription != null && (post.shortDescription ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      post.shortDescription!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Author line (Medium-style: avatar, name, date)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                        child: Text(
                          'E',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Evtopia',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (post.createdAt != null && post.createdAt!.isNotEmpty) ...[
                        Text(
                          ' · ',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.black45),
                        ),
                        Text(
                          post.createdAt!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ],
                  ),
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

class _LoadMoreFooter extends ConsumerWidget {
  const _LoadMoreFooter({required this.notifier});

  final BlogsNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!notifier.hasMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
        ),
      ),
    );
  }
}
