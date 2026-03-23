import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';

import '../models/post_model.dart';
import '../providers/home_provider.dart';
import '../utils/image_url.dart';
import '../widgets/optimized_network_image.dart';
import '../widgets/skeleton_loader.dart';

/// Lists all blogs (paginated) with a premium, engaging UI.
class BlogsScreen extends ConsumerStatefulWidget {
  const BlogsScreen({super.key});

  @override
  ConsumerState<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends ConsumerState<BlogsScreen> {
  final ScrollController _scrollController = ScrollController();
  static const _primaryGreen = Color(0xFF2E7D32);

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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 160.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: _primaryGreen,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => ref.read(blogsListProvider.notifier).refresh(),
              ),
              const Gap(8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
              centerTitle: true,
              title: Text(
                'News & Blog',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0, 2), blurRadius: 4),
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), _primaryGreen],
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(Icons.auto_stories_rounded, size: 120, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          // Content
          async.when(
            data: (posts) {
              if (posts.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(theme: theme),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                sliver: AnimationLimiter(
                  child: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == posts.length) {
                          return _LoadMoreFooter(notifier: ref.read(blogsListProvider.notifier));
                        }
                        final post = posts[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: _BlogCard(
                                  post: post,
                                  isFeatured: index == 0,
                                  onTap: () => Navigator.of(context).pushNamed('/blog-detail', arguments: post.id),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: posts.length + 1,
                    ),
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: SkeletonProductList(itemCount: 6),
            ),
            error: (err, _) => SliverFillRemaining(
              child: _ErrorState(
                theme: theme,
                onRetry: () => ref.read(blogsListProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.post, required this.onTap, this.isFeatured = false});

  final PostModel post;
  final VoidCallback onTap;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl(post.banner);
    final category = post.categories.isNotEmpty ? post.categories.first : 'Sustainability';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: isFeatured ? 1.6 : 1.9,
                    child: url.isEmpty
                        ? Container(
                            color: const Color(0xFFF0F0F0),
                            child: const Icon(Icons.article_rounded, size: 48, color: Colors.black12),
                          )
                        : OptimizedNetworkImage(
                            url: url,
                            cacheWidth: 1000,
                            cacheHeight: 600,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.3,
                        fontSize: isFeatured ? 22 : 18,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(12),
                    if (post.shortDescription != null)
                      Text(
                        post.shortDescription!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          height: 1.5,
                          fontSize: isFeatured ? 15 : 14,
                        ),
                        maxLines: isFeatured ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Gap(20),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF2E7D32)),
                        ),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editorial',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              if (post.createdAt != null)
                                Text(
                                  post.createdAt!,
                                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.black38),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.black26),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_rounded, size: 64, color: Colors.black12),
          const Gap(16),
          Text(
            'New stories coming soon',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.black38),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.theme, required this.onRetry});
  final ThemeData theme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
          const Gap(16),
          const Text('Couldn\'t load stories', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(24),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.notifier});
  final BlogsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (!notifier.hasMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
      ),
    );
  }
}
