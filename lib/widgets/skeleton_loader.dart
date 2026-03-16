import 'package:flutter/material.dart';

/// Base shimmer animation for skeleton loaders.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade600 : Colors.grey.shade100;
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, highlight, base],
              stops: const [0.0, 0.35, 0.65, 1.0],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slide);
  final double slide;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slide * 0.5), 0, 0);
  }
}

/// Single skeleton box with optional size and radius.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
    return Shimmer(child: box);
  }
}

/// Skeleton for home tab: header, banner, sections.
class SkeletonHomePage extends StatelessWidget {
  const SkeletonHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                const SkeletonBox(width: 120, height: 44, borderRadius: BorderRadius.all(Radius.circular(8))),
                const Spacer(),
                SkeletonBox(width: 44, height: 44, borderRadius: BorderRadius.circular(22)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonBox(height: 210, borderRadius: BorderRadius.circular(24)),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 180, height: 20),
                const SizedBox(height: 8),
                const SkeletonBox(width: 140, height: 14),
                const SizedBox(height: 14),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, __) => const SkeletonBox(
                      width: 260,
                      height: 220,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 160, height: 20),
                const SizedBox(height: 8),
                const SkeletonBox(width: 200, height: 14),
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, __) => const SkeletonBox(
                      width: 180,
                      height: 260,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

/// Skeleton for a horizontal list of cards (e.g. latest products).
class SkeletonHorizontalCards extends StatelessWidget {
  const SkeletonHorizontalCards({
    super.key,
    this.itemCount = 4,
    this.cardWidth = 168,
    this.cardHeight = 220,
  });

  final int itemCount;
  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => SkeletonBox(
          width: cardWidth,
          height: cardHeight,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Skeleton for product grid (products tab).
class SkeletonProductGrid extends StatelessWidget {
  const SkeletonProductGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 6,
  });

  final int crossAxisCount;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 3,
            child: SkeletonBox(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                const SkeletonBox(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for product list (list view).
class SkeletonProductList extends StatelessWidget {
  const SkeletonProductList({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(
            width: 100,
            height: 100,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                const SkeletonBox(width: 60, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for product detail page.
class SkeletonProductDetail extends StatelessWidget {
  const SkeletonProductDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 56),
          // Image gallery skeleton
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonBox(
              height: 340,
              borderRadius: BorderRadius.all(Radius.circular(32)),
            ),
          ),
          const SizedBox(height: 24),
          // Info card skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 80, height: 24, borderRadius: BorderRadius.all(Radius.circular(10))),
                  SizedBox(height: 16),
                  SkeletonBox(width: 240, height: 28),
                  SizedBox(height: 8),
                  SkeletonBox(width: 140, height: 20),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      SkeletonBox(width: 120, height: 36),
                      Spacer(),
                      SkeletonBox(width: 80, height: 16),
                    ],
                  ),
                  SizedBox(height: 24),
                  SkeletonBox(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: 200, height: 14),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 48, borderRadius: BorderRadius.all(Radius.circular(14)))),
                      SizedBox(width: 12),
                      Expanded(flex: 2, child: SkeletonBox(height: 48, borderRadius: BorderRadius.all(Radius.circular(14)))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Specs skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      SkeletonBox(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
                      SizedBox(width: 12),
                      SkeletonBox(width: 140, height: 20),
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
                    children: List.generate(4, (index) => const SkeletonBox(borderRadius: BorderRadius.all(Radius.circular(16)))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

/// Skeleton for service detail page.
class SkeletonServiceDetail extends StatelessWidget {
  const SkeletonServiceDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 56),
          const SkeletonBox(
            height: 320,
            borderRadius: BorderRadius.zero,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 200, height: 24),
                const SizedBox(height: 16),
                const SkeletonBox(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                const SkeletonBox(width: 280, height: 14),
                const SizedBox(height: 24),
                const SkeletonBox(width: 100, height: 18),
                const SizedBox(height: 12),
                const SkeletonBox(width: double.infinity, height: 120, borderRadius: BorderRadius.all(Radius.circular(20))),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

/// Skeleton for a list of notification/service items.
class SkeletonListPage extends StatelessWidget {
  const SkeletonListPage({
    super.key,
    this.itemCount = 8,
    this.itemHeight = 80,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => SkeletonBox(
        height: itemHeight,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

/// Skeleton for notifications screen (list items with icon + text).
class SkeletonNotifications extends StatelessWidget {
  const SkeletonNotifications({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: double.infinity, height: 16),
                  const SizedBox(height: 6),
                  const SkeletonBox(width: 180, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for liked EVs / product grid (same as product grid).
class SkeletonLikedEvs extends StatelessWidget {
  const SkeletonLikedEvs({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonProductGrid(crossAxisCount: 2, itemCount: 6);
  }
}
/// Skeleton for main profile tab.
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SkeletonBox(height: 180, borderRadius: BorderRadius.all(Radius.circular(28))),
          ),
          const SizedBox(height: 12),
          _buildSkeletonSection(context),
          _buildSkeletonSection(context),
          _buildSkeletonSection(context),
        ],
      ),
    );
  }

  Widget _buildSkeletonSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 100, height: 14),
          const SizedBox(height: 12),
          SkeletonBox(height: 72, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: 10),
          SkeletonBox(height: 72, borderRadius: BorderRadius.circular(20)),
        ],
      ),
    );
  }
}

/// Skeleton for edit profile screen.
class SkeletonEditProfile extends StatelessWidget {
  const SkeletonEditProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SkeletonBox(width: 120, height: 120, borderRadius: BorderRadius.circular(60)),
          const SizedBox(height: 32),
          _buildFieldSkeleton(),
          const SizedBox(height: 24),
          _buildFieldSkeleton(),
          const SizedBox(height: 24),
          _buildFieldSkeleton(),
          const SizedBox(height: 24),
          _buildFieldSkeleton(),
          const SizedBox(height: 40),
          SkeletonBox(height: 56, borderRadius: BorderRadius.circular(16)),
        ],
      ),
    );
  }

  Widget _buildFieldSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 80, height: 12),
        const SizedBox(height: 8),
        SkeletonBox(height: 56, borderRadius: BorderRadius.circular(16)),
      ],
    );
  }
}

/// Skeleton for sell car (PostCarScreen).
class SkeletonPostCar extends StatelessWidget {
  const SkeletonPostCar({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 160, borderRadius: BorderRadius.all(Radius.circular(28))),
          const SizedBox(height: 32),
          const SkeletonBox(width: 120, height: 14),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => SkeletonBox(width: 100, height: 100, borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),
          const SkeletonBox(width: 140, height: 14),
          const SizedBox(height: 16),
          SkeletonBox(height: 110, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: 12),
          SkeletonBox(height: 110, borderRadius: BorderRadius.circular(20)),
        ],
      ),
    );
  }
}
