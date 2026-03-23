import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gap/gap.dart';

import '../models/post_model.dart';
import '../providers/home_provider.dart';
import '../utils/image_url.dart';
import '../widgets/optimized_network_image.dart';
import '../widgets/skeleton_loader.dart';

/// Shows a single blog post with a premium, focused reading experience.
class BlogDetailScreen extends ConsumerWidget {
  const BlogDetailScreen({super.key, required this.postId});

  final int postId;
  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(blogDetailProvider(postId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: async.when(
        data: (detail) {
          if (detail == null) return _ErrorState(theme: theme);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                stretch: true,
                backgroundColor: _primaryGreen,
                elevation: 0,
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _BannerImage(url: imageUrl(detail.post.banner)),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black38, Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category and Date
                        Row(
                          children: [
                            if (detail.post.categories.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  detail.post.categories.first.toUpperCase(),
                                  style: const TextStyle(
                                    color: _primaryGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            if (detail.post.categories.isNotEmpty) const Gap(12),
                            if (detail.post.createdAt != null)
                              Text(
                                detail.post.createdAt!,
                                style: theme.textTheme.labelMedium?.copyWith(color: Colors.black38),
                              ),
                          ],
                        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

                        const Gap(20),
                        
                        // Title
                        Text(
                          detail.post.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                        const Gap(24),

                        // Author Section
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: Color(0xFFE8F5E9),
                              child: Icon(Icons.person_outline_rounded, color: _primaryGreen),
                            ),
                            const Gap(12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'EVTOPIA Knowledge Hub',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                                Text('5 min read', style: theme.textTheme.labelSmall?.copyWith(color: Colors.black38)),
                              ],
                            ),
                            const Spacer(),
                          ],
                        ).animate().fadeIn(delay: 300.ms),

                        const Gap(32),
                        const Divider(height: 1, color: Colors.black12),
                        const Gap(32),

                        // Content
                        if (detail.post.description != null && detail.post.description!.isNotEmpty)
                          HtmlWidget(
                            detail.post.description!,
                            textStyle: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.7,
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            onTapUrl: (url) async {
                              final uri = Uri.tryParse(url);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                return true;
                              }
                              return false;
                            },
                          ).animate().fadeIn(delay: 400.ms),

                        // Attachments (PDFs/Videos)
                        if ((detail.post.pdfs?.isNotEmpty ?? false) || (detail.post.videoLinks?.isNotEmpty ?? false))
                          _AttachmentsSection(post: detail.post).animate().fadeIn(delay: 500.ms),

                        // Image Gallery
                        if (detail.post.images != null && detail.post.images!.isNotEmpty)
                          _ImageGallery(images: detail.post.images!).animate().fadeIn(delay: 600.ms),

                        // Related Posts
                        if (detail.relatedPosts.isNotEmpty)
                          _RelatedSection(posts: detail.relatedPosts).animate().fadeIn(delay: 700.ms),

                        const Gap(40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const SkeletonProductDetail(),
        error: (err, _) => _ErrorState(theme: theme, onRetry: () => ref.invalidate(blogDetailProvider(postId))),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const ColoredBox(color: Color(0xFFF5F5F5), child: Center(child: Icon(Icons.article_rounded, size: 64, color: Colors.black12)));
    return OptimizedNetworkImage(url: url, fit: BoxFit.cover);
  }
}

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({required this.post});
  final PostModel post;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(40),
        const Text('Explore More', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const Gap(16),
        if (post.pdfs != null)
          ...post.pdfs!.map((pdf) => _AttachmentTile(
            icon: Icons.picture_as_pdf_rounded,
            title: pdf.name ?? 'Document',
            subtitle: pdf.size ?? 'View PDF',
            color: Colors.redAccent,
            onTap: pdf.url != null ? () => _openUrl(pdf.url!) : null,
          )),
        if (post.videoLinks != null)
          ...post.videoLinks!.map((url) => _AttachmentTile(
            icon: Icons.play_circle_fill_rounded,
            title: 'Watch Video',
            subtitle: url,
            color: BlogDetailScreen._primaryGreen,
            onTap: () => _openUrl(url),
          )),
      ],
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.icon, required this.title, required this.subtitle, required this.color, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        ),
      ),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.images});
  final List<String> images;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(40),
        const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const Gap(16),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 240,
                child: OptimizedNetworkImage(url: imageUrl(images[i]), fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RelatedSection extends StatelessWidget {
  const _RelatedSection({required this.posts});
  final List<PostModel> posts;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(40),
        const Text('Related Stories', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const Gap(16),
        ...posts.take(3).map((p) => _RelatedTile(post: p)),
      ],
    );
  }
}

class _RelatedTile extends StatelessWidget {
  const _RelatedTile({required this.post});
  final PostModel post;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushReplacementNamed('/blog-detail', arguments: post.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: OptimizedNetworkImage(url: imageUrl(post.banner), fit: BoxFit.cover),
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.3),
                  ),
                  if (post.createdAt != null)
                    Text(post.createdAt!, style: const TextStyle(color: Colors.black38, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.theme, this.onRetry});
  final ThemeData theme;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.orange),
          const Gap(16),
          const Text('Blog not found or failed to load', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(24),
          if (onRetry != null) FilledButton(onPressed: onRetry, style: FilledButton.styleFrom(backgroundColor: BlogDetailScreen._primaryGreen), child: const Text('Retry')),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
        ],
      ),
    );
  }
}
