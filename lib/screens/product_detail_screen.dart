import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/api_constants.dart';
import '../models/contact_us_model.dart';
import '../models/product_detail_model.dart';
import '../providers/home_provider.dart';
import '../utils/image_url.dart';
import '../widgets/optimized_network_image.dart';
import '../widgets/skeleton_loader.dart';

/// Product detail screen (from old app: floating app bar, image gallery, description card, specs, share, contact).
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  static const _primaryGreen = Color(0xFF2E7D32);
  bool _isTransitioning = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _isTransitioning = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isTransitioning) {
      return const Scaffold(body: SkeletonProductDetail());
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final async = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: async.when(
        data: (ProductDetailModel? product) {
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }
          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 56),
                    _ProductImageSection(
                      thumbnails: product.thumbnails,
                      productName: product.name,
                    ),
                    const SizedBox(height: 16),
                    _ProductDescriptionCard(
                      product: product,
                      onShare: () => _showShareBottomSheet(context, product),
                      onGetInTouch: product.isUserListing
                          ? () => _showSellerContactSheet(context, product)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _SpecsCard(product: product),
                    if (product.description != null && product.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ProductDetailsCard(description: product.description!),
                    ],
                    if (product.relatedProducts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SimilarProductsSection(
                        relatedProducts: product.relatedProducts,
                        onProductTap: (id) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (ctx) => ProductDetailScreen(productId: id),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              // Floating app bar (from old app)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.surface,
                          colorScheme.surface.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Material(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: const CircleBorder(),
                          elevation: 2,
                          shadowColor: Colors.black26,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _primaryGreen),
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const SkeletonProductDetail(),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load product',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: async.whenOrNull(
        data: (product) => product != null
            ? _ContactBottomBar(product: product, contactAsync: ref.watch(contactUsProvider))
            : null,
      ),
    );
  }

  void _showShareBottomSheet(BuildContext context, ProductDetailModel product) {
    final shareLink = '${ApiConstants.baseUrl}/product/${product.id}';
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Share Listing',
              style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareLink,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: _primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: shareLink));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Link copied to clipboard')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: _primaryGreen.withValues(alpha: 0.1),
                      foregroundColor: _primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'SHARE VIA',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareOption(
                  label: 'SMS',
                  icon: Icons.sms_rounded,
                  onTap: () {
                    final uri = Uri.parse(
                      'sms:?body=${Uri.encodeComponent('${product.name}\n$shareLink')}',
                    );
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
                _ShareOption(
                  label: 'Email',
                  icon: Icons.alternate_email_rounded,
                  onTap: () {
                    final uri = Uri.parse(
                      'mailto:?subject=${Uri.encodeComponent(product.name)}&body=${Uri.encodeComponent(shareLink)}',
                    );
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
                _ShareOption(
                  label: 'WhatsApp',
                  icon: FontAwesomeIcons.whatsapp,
                  onTap: () {
                    final uri = Uri.parse(
                      'https://wa.me/?text=${Uri.encodeComponent('${product.name}\n$shareLink')}',
                    );
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSellerContactSheet(BuildContext context, ProductDetailModel product) {
    final hasEmail = product.sellerEmail != null && product.sellerEmail!.isNotEmpty;
    final hasPhone = product.sellerPhone != null && product.sellerPhone!.isNotEmpty;
    if (!hasEmail && !hasPhone) return;
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Contact Seller',
              style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Direct inquiry for ${product.name}',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            if (hasPhone)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_iphone_rounded, color: _primaryGreen),
                  ),
                  title: const Text('Call Seller', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(product.sellerPhone!),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    final uri = Uri.parse('tel:${product.sellerPhone}');
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
            if (hasEmail)
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mail_outline_rounded, color: _primaryGreen),
                  ),
                  title: const Text('Email Seller', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(product.sellerEmail!),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    final uri = Uri.parse('mailto:${product.sellerEmail}');
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: _primaryGreen),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Platform icon for social links (Follow us on). Uses Font Awesome brand icon by platform name.
class _SocialPlatformIcon extends StatelessWidget {
  const _SocialPlatformIcon({required this.link, required this.color, this.size = 28});

  final SocialLink link;
  final Color color;
  final double size;

  static IconData? _iconForPlatform(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('facebook')) return FontAwesomeIcons.facebook;
    if (lower.contains('instagram')) return FontAwesomeIcons.instagram;
    if (lower.contains('linkedin')) return FontAwesomeIcons.linkedin;
    if (lower.contains('youtube')) return FontAwesomeIcons.youtube;
    if (lower.contains('twitter') || lower.contains('x ')) return FontAwesomeIcons.xTwitter;
    if (lower.contains('tiktok')) return FontAwesomeIcons.tiktok;
    if (lower.contains('telegram')) return FontAwesomeIcons.telegram;
    if (lower.contains('whatsapp')) return FontAwesomeIcons.whatsapp;
    if (lower.contains('pinterest')) return FontAwesomeIcons.pinterest;
    if (lower.contains('reddit')) return FontAwesomeIcons.reddit;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconForPlatform(link.name);
    return icon != null
        ? FaIcon(icon, color: color, size: size)
        : Icon(Icons.link_rounded, color: color, size: size);
  }
}

class _ProductImageSection extends StatefulWidget {
  const _ProductImageSection({required this.thumbnails, required this.productName});

  final List<String> thumbnails;
  final String productName;

  @override
  State<_ProductImageSection> createState() => _ProductImageSectionState();
}

class _ProductImageSectionState extends State<_ProductImageSection> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final thumbnails = widget.thumbnails;
    if (thumbnails.isEmpty) {
      return AspectRatio(
        aspectRatio: 1.2,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
        ),
      );
    }
    return Container(
      height: 340,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: thumbnails.length,
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () => _showFullScreenImage(context, i),
                child: Hero(
                  tag: 'product_image_${widget.productName}_$i',
                  child: _buildImage(thumbnails[i], colorScheme),
                ),
              );
            },
          ),
          // Gradient overlay for better text visibility if we add any
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (thumbnails.length > 1) ...[
            Positioned(
              top: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${thumbnails.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    thumbnails.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentIndex == i
                            ? const Color(0xFF4CAF50)
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _currentIndex == i
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                                : Colors.transparent,
                            blurRadius: _currentIndex == i ? 8 : 0,
                            spreadRadius: _currentIndex == i ? 1 : 0,
                          ),
                        ],
                      ),
                      height: 6,
                      width: _currentIndex == i ? 28 : 6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImage(String path, ColorScheme colorScheme) {
    final url = imageUrl(path);
    if (url.isEmpty) {
      return ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
      );
    }
    return OptimizedNetworkImage(
      url: url,
      cacheWidth: 800,
      cacheHeight: 600,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _FullScreenImageViewer(
        thumbnails: widget.thumbnails,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({
    required this.thumbnails,
    required this.initialIndex,
  });

  final List<String> thumbnails;
  final int initialIndex;

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thumbnails = widget.thumbnails;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: PageView.builder(
              controller: _pageController,
              itemCount: thumbnails.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, i) {
                final url = imageUrl(thumbnails[i]);
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: url.isEmpty
                      ? const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.white54))
                      : Image.network(url, fit: BoxFit.contain),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                    if (thumbnails.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${thumbnails.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDescriptionCard extends StatefulWidget {
  const _ProductDescriptionCard({
    required this.product,
    required this.onShare,
    this.onGetInTouch,
  });

  final ProductDetailModel product;
  final VoidCallback onShare;
  final VoidCallback? onGetInTouch;

  @override
  State<_ProductDescriptionCard> createState() => _ProductDescriptionCardState();
}

class _ProductDescriptionCardState extends State<_ProductDescriptionCard> {
  bool _expanded = false;
  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.product;
    final shortDesc = p.shortDescription ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper section with badges and title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (p.brand != null && p.brand!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryGreen.withValues(alpha: 0.15),
                              _primaryGreen.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _primaryGreen.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          p.brand!.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _primaryGreen,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (p.discountPercentage != null && p.discountPercentage! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${p.discountPercentage!.toStringAsFixed(0)}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  p.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                if (p.model != null && p.model!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    p.model!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'ETB',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _primaryGreen,
                            fontWeight: FontWeight.w700,
                            height: 2.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          p.discountPrice != null && p.discountPrice! > 0
                              ? p.discountPrice!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')
                              : p.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: _primaryGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                if (p.discountPrice != null && p.discountPrice! > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 15),
                      Text(
                        'Original: ETB ${p.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),

          // Description and Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                AnimatedCrossFade(
                  firstChild: Text(
                    shortDesc.isEmpty ? 'No description available for this electric vehicle.' : shortDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondChild: Text(
                    shortDesc.isEmpty ? 'No description available for this electric vehicle.' : shortDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
                if (shortDesc.length > 100)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _expanded ? 'Show Less' : 'Read More',
                        style: TextStyle(
                          color: _primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: widget.onShare,
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: const Text('SHARE'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryGreen,
                          side: BorderSide(color: _primaryGreen.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1, fontSize: 12),
                        ),
                      ),
                    ),
                    if (widget.onGetInTouch != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryGreen.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: FilledButton.icon(
                            onPressed: widget.onGetInTouch,
                            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                            label: const Text('CONTACT SELLER'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 12),
                            ),
                          ),
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
    );
  }
}

class _SpecsCard extends StatelessWidget {
  const _SpecsCard({required this.product});

  final ProductDetailModel product;

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_rounded, color: _primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Specifications',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              if (product.drivingRange != null && product.drivingRange!.isNotEmpty)
                _SpecChip(
                  icon: Icons.electric_car_rounded,
                  label: 'Range',
                  value: '${product.drivingRange} km',
                ),
              if (product.batteryCapacity != null && product.batteryCapacity!.isNotEmpty)
                _SpecChip(
                  icon: Icons.battery_saver_rounded,
                  label: 'Battery',
                  value: '${product.batteryCapacity} kWh',
                ),
              if (product.peakPower != null && product.peakPower!.isNotEmpty)
                _SpecChip(
                  icon: Icons.bolt_rounded,
                  label: 'Power',
                  value: '${product.peakPower} kW',
                ),
              if (product.year != null)
                _SpecChip(
                  icon: Icons.event_available_rounded,
                  label: 'Year',
                  value: product.year.toString(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryGreen.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Product Details (description) card – from old app ProductDetailsAndReview.
class _ProductDetailsCard extends StatelessWidget {
  const _ProductDetailsCard({required this.description});

  final String description;

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),
          HtmlWidget(
            description,
            textStyle: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Similar products horizontal list – from old app SimilarProductsWidget.
class _SimilarProductsSection extends StatelessWidget {
  const _SimilarProductsSection({
    required this.relatedProducts,
    required this.onProductTap,
  });

  final List<RelatedProductModel> relatedProducts;
  final void Function(int productId) onProductTap;

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Similar Products',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {}, // Could navigate to a search result page
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: _primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: relatedProducts.length,
            itemBuilder: (context, index) {
              final p = relatedProducts[index];
              return _SimilarProductCard(
                product: p,
                onTap: () => onProductTap(p.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SimilarProductCard extends StatelessWidget {
  const _SimilarProductCard({required this.product, required this.onTap});

  final RelatedProductModel product;
  final VoidCallback onTap;

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbUrl = product.thumbnail != null && product.thumbnail!.isNotEmpty
        ? imageUrl(product.thumbnail)
        : '';
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16, bottom: 20, top: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.1,
              child: thumbUrl.isNotEmpty
                  ? OptimizedNetworkImage(
                      url: thumbUrl,
                      cacheWidth: 300,
                      cacheHeight: 330,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, size: 40, color: theme.colorScheme.outline),
                    )
                  : ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.image_not_supported, size: 40, color: theme.colorScheme.outline),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'ETB',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.discountPrice != null && product.discountPrice! > 0
                            ? product.discountPrice!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')
                            : product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _primaryGreen,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  if (product.discountPrice != null && product.discountPrice! > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'ETB ${product.price.toStringAsFixed(0)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactBottomBar extends StatelessWidget {
  const _ContactBottomBar({
    required this.product,
    required this.contactAsync,
  });

  final ProductDetailModel product;
  final AsyncValue<ContactUsModel?> contactAsync;

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: contactAsync.when(
        data: (contact) {
          // Like Laravel: always prefer seller/publisher contact when available;
          // fall back to global Contact Us only when product has no seller info.
          final hasSellerContact = (product.sellerPhone != null && product.sellerPhone!.isNotEmpty) ||
              (product.sellerEmail != null && product.sellerEmail!.isNotEmpty);
          final phone = hasSellerContact ? (product.sellerPhone ?? '') : (contact?.data.phone ?? '');
          final email = hasSellerContact ? (product.sellerEmail ?? '') : (contact?.data.email ?? '');
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showContactSheet(context, phone: phone, email: email, contact: contact, isSeller: hasSellerContact),
                  icon: const Icon(Icons.contact_phone_rounded, size: 22),
                  label: Text(hasSellerContact ? 'Contact Seller' : 'Contact Us'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryGreen,
                    side: const BorderSide(color: _primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: SizedBox(width: 48, height: 48, child: CircularProgressIndicator())),
        error: (_, __) => Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final hasSeller = (product.sellerPhone != null && product.sellerPhone!.isNotEmpty) ||
                      (product.sellerEmail != null && product.sellerEmail!.isNotEmpty);
                  _showContactSheet(
                    context,
                    phone: product.sellerPhone ?? '',
                    email: product.sellerEmail ?? '',
                    contact: null,
                    isSeller: hasSeller,
                  );
                },
                icon: const Icon(Icons.contact_phone_rounded, size: 22),
                label: Text((product.sellerPhone != null && product.sellerPhone!.isNotEmpty) ||
                        (product.sellerEmail != null && product.sellerEmail!.isNotEmpty)
                    ? 'Contact Seller'
                    : 'Contact Us'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryGreen,
                  side: const BorderSide(color: _primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactSheet(
    BuildContext context, {
    required String phone,
    required String email,
    required ContactUsModel? contact,
    bool isSeller = false,
  }) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Get in Touch',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSeller ? 'Contact the seller for this product.' : 'Our team is here to help you with your inquiry.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (phone.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_rounded, color: _primaryGreen),
                    ),
                    title: const Text('Phone', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(phone),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () async {
                      final uri = Uri(scheme: 'tel', path: phone);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                ),
              if (email.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.email_rounded, color: _primaryGreen),
                    ),
                    title: const Text('Email', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(email),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () async {
                      final uri = Uri(
                        scheme: 'mailto',
                        path: email,
                        query: 'subject=Enquiry: ${Uri.encodeComponent(product.name)}',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
              if (contact?.data.socialLinks.isNotEmpty == true) ...[
                Text(
                  'SOCIAL CHANNELS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: contact!.data.socialLinks.map((link) {
                    return InkWell(
                      onTap: () async {
                        final uri = Uri.parse(link.link);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SocialPlatformIcon(link: link, color: _primaryGreen, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              link.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface,
                  foregroundColor: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1),
                ),
                child: const Text('DISMISS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
