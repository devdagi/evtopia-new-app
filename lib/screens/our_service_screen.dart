import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_model.dart';
import '../providers/home_provider.dart';
import '../utils/image_url.dart';
import '../widgets/optimized_network_image.dart';
import '../widgets/skeleton_loader.dart';
import 'service_request_sheet.dart';

/// Our Service tab: list of services from API.
/// Premium Tesla-inspired EV service UI — same API and logic.
class OurServiceScreen extends ConsumerStatefulWidget {
  const OurServiceScreen({super.key});

  @override
  ConsumerState<OurServiceScreen> createState() => _OurServiceScreenState();
}

class _OurServiceScreenState extends ConsumerState<OurServiceScreen>
    with SingleTickerProviderStateMixin {
  int _page = 1;
  static const int _perPage = 10;
  List<ServiceModel> _services = [];
  int _total = 0;
  bool _loading = false;
  bool _loaded = false;
  bool _animationStarted = false;
  AnimationController? _animController;

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    final res = await ref.read(homeServiceProvider).getServices(page: _page, perPage: _perPage);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loaded = true;
      if (res != null) {
        _total = res.total;
        if (_page == 1) {
          _services = res.services;
          if (_services.isNotEmpty && !_animationStarted) {
            _animationStarted = true;
            _animController?.forward();
          }
        } else {
          _services.addAll(res.services);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  void _openServiceRequestSheet(BuildContext context, ServiceModel service) {
    ServiceRequestSheet.show(
      context,
      serviceId: service.id,
      serviceName: service.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (!_loaded && !_loading) {
      return Container(
        decoration: _buildBackgroundDecoration(isDark),
        child: const SkeletonListPage(itemCount: 8, itemHeight: 140),
      );
    }
    return Container(
      decoration: _buildBackgroundDecoration(isDark),
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _page = 1;
            _services = [];
            _animationStarted = false;
            _animController?.reset();
          });
          await _load();
        },
        color: theme.colorScheme.primary,
        child: _services.isEmpty && !_loading
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.electric_car_rounded,
                          size: 56,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No services available',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                itemCount: _services.length +
                    (_loading ? 1 : 0) +
                    (_page * _perPage < _total ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _services.length) {
                    if (_loading) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: SkeletonBox(height: 140, borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    }
                    _page++;
                    _load();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: SkeletonBox(height: 140, borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  }
                  final s = _services[i];
                  return _ServiceCard(
                    service: s,
                    index: i,
                    animationController: _animController,
                    onRequestService: () => _openServiceRequestSheet(context, s),
                  );
                },
              ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration(bool isDark) {
    if (isDark) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0E12),
            Color(0xFF12141A),
            Color(0xFF0F1114),
          ],
        ),
      );
    }
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF5F6F8),
          Color(0xFFEBEEF2),
          Color(0xFFE8ECF0),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.index,
    required this.animationController,
    required this.onRequestService,
  });

  final ServiceModel service;
  final int index;
  final AnimationController? animationController;
  final VoidCallback onRequestService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final url = imageUrl(service.thumbnail);

    final cardContent = Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onRequestService,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1C21) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: isDark ? 24 : 20,
                    offset: const Offset(0, 8),
                    spreadRadius: isDark ? 0 : -2,
                  ),
                  if (!isDark)
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                      spreadRadius: -4,
                    ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thumbnail as card image
                  SizedBox(
                    height: 160,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (url.isEmpty)
                          Container(
                            color: isDark
                                ? const Color(0xFF25282E)
                                : const Color(0xFFE8ECF0),
                            child: Icon(
                              Icons.electric_car_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                          )
                        else
                          OptimizedNetworkImage(
                            url: url,
                            cacheWidth: 400,
                            cacheHeight: 240,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: isDark
                                  ? const Color(0xFF25282E)
                                  : const Color(0xFFE8ECF0),
                              child: Icon(
                                Icons.electric_car_rounded,
                                size: 48,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        // Gradient overlay for readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                        // Category badge
                        if (service.categories != null && service.categories!.isNotEmpty)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    service.categories!.first,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                        if (service.shortDescription != null &&
                            service.shortDescription!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            service.shortDescription!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Request Service pill button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: onRequestService,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            child: const Text('Request Service'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

    if (animationController == null) return cardContent;
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        const stagger = 0.06;
        final span = 1.0 + (20 * stagger);
        final opacity = ((animationController!.value * span) - (index * stagger)).clamp(0.0, 1.0);
        final slide = 24.0 * (1.0 - opacity);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, slide),
            child: child,
          ),
        );
      },
      child: cardContent,
    );
  }
}
