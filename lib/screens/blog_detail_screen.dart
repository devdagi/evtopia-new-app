import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/post_model.dart';
import '../providers/home_provider.dart';
import '../utils/image_url.dart';
import '../widgets/optimized_network_image.dart';
import '../widgets/skeleton_loader.dart';

/// Shows a single blog post (from GET /api/blog-details). Tap related post opens this screen with that id.
class BlogDetailScreen extends ConsumerWidget {
  const BlogDetailScreen({super.key, required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(blogDetailProvider(postId));
    final theme = Theme.of(context);

    return Scaffold(
      body: async.when(
        data: (detail) {
          if (detail == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  const Text('Blog not found'),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ],
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _BannerImage(url: imageUrl(detail.post.banner)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (detail.post.categories.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: detail.post.categories
                              .map((c) => Chip(
                                    label: Text(c, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ))
                              .toList(),
                        ),
                      if (detail.post.categories.isNotEmpty) const SizedBox(height: 12),
                      if (detail.post.createdAt != null)
                        Text(
                          detail.post.createdAt!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        detail.post.title,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      if (detail.post.description != null && detail.post.description!.isNotEmpty)
                        HtmlWidget(
                          detail.post.description!,
                          textStyle: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                          onTapUrl: (url) async {
                            final uri = Uri.tryParse(url);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                              return true;
                            }
                            return false;
                          },
                        ),
                      if (detail.post.pdfs != null && detail.post.pdfs!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Downloads', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        ...detail.post.pdfs!.map((pdf) => ListTile(
                              leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                              title: Text(pdf.name ?? 'PDF'),
                              subtitle: pdf.size != null ? Text(pdf.size!) : null,
                              onTap: pdf.url != null && pdf.url!.isNotEmpty
                                  ? () => _openUrl(context, pdf.url!)
                                  : null,
                            )),
                      ],
                      if (detail.post.videoLinks != null && detail.post.videoLinks!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Videos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        ...detail.post.videoLinks!.map((url) => ListTile(
                              leading: const Icon(Icons.video_library_rounded),
                              title: Text(url, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                              onTap: () => _openUrl(context, url),
                            )),
                      ],
                      if (detail.post.images != null && detail.post.images!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Images', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: detail.post.images!.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final imgUrl = detail.post.images![i];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 160,
                                  child: OptimizedNetworkImage(
                                    url: imageUrl(imgUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.grey, child: SizedBox.expand()),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (detail.relatedPosts.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text('Related posts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        ...detail.relatedPosts.map((post) => _RelatedPostCard(
                              post: post,
                              onTap: () => Navigator.of(context).pushNamed('/blog-detail', arguments: post.id),
                            )),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const SkeletonProductDetail(),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                const Text('Failed to load blog'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(blogDetailProvider(postId)),
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

  static Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open: $url'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.article_rounded, size: 64)),
      );
    }
    return OptimizedNetworkImage(
      url: url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.article_rounded, size: 64)),
      ),
    );
  }
}

class _RelatedPostCard extends StatelessWidget {
  const _RelatedPostCard({required this.post, required this.onTap});

  final PostModel post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl(post.banner);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: url.isEmpty
                        ? ColoredBox(
                            color: theme.colorScheme.surface,
                            child: Icon(Icons.article_outlined, color: theme.colorScheme.onSurfaceVariant),
                          )
                        : OptimizedNetworkImage(
                            url: url,
                            cacheWidth: 160,
                            cacheHeight: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: theme.colorScheme.surface,
                              child: Icon(Icons.article_outlined, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (post.createdAt != null)
                        Text(
                          post.createdAt!,
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
