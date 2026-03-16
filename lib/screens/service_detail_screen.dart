import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../models/service_detail_model.dart';
import '../models/service_model.dart';
import '../providers/home_provider.dart';
import '../utils/image_url.dart';
import '../widgets/optimized_network_image.dart';
import '../widgets/skeleton_loader.dart';
import 'service_request_sheet.dart';

/// Service detail screen – GET /api/service-details?service_id=X.
class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final int serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final async = ref.watch(serviceDetailProvider(serviceId));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: async.when(
        data: (ServiceDetailModel? service) {
          if (service == null) {
            return const Center(child: Text('Service not found'));
          }
          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 56),
                    _ServiceImageSection(
                      thumbnails: service.thumbnails,
                      serviceName: service.name,
                    ),
                    const SizedBox(height: 16),
                    _ServiceInfoCard(service: service),
                    if (service.description != null && service.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ServiceDescriptionCard(description: service.description!),
                    ],
                    if (service.relatedServices.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _RelatedServicesSection(
                        relatedServices: service.relatedServices,
                        onServiceTap: (id) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (ctx) => ServiceDetailScreen(serviceId: id),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
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
                      children: [
                        Material(
                          color: colorScheme.surfaceContainerHighest,
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: 'Back',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const SkeletonServiceDetail(),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load service', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
      bottomNavigationBar: async.whenOrNull(
        data: (service) => service != null ? _RequestServiceBar(service: service) : null,
      ),
    );
  }
}

class _ServiceImageSection extends StatefulWidget {
  const _ServiceImageSection({required this.thumbnails, required this.serviceName});

  final List<String> thumbnails;
  final String serviceName;

  @override
  State<_ServiceImageSection> createState() => _ServiceImageSectionState();
}

class _ServiceImageSectionState extends State<_ServiceImageSection> {
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
        child: ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
        ),
      );
    }
    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: thumbnails.length,
            itemBuilder: (context, i) => _buildImage(thumbnails[i], colorScheme),
          ),
          if (thumbnails.length > 1) ...[
            Positioned(
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    thumbnails.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _currentIndex == i
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: 6,
                      width: _currentIndex == i ? 24 : 6,
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
}

class _ServiceInfoCard extends StatelessWidget {
  const _ServiceInfoCard({required this.service});

  final ServiceDetailModel service;

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (service.categories != null && service.categories!.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: service.categories!
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          if (service.categories != null && service.categories!.isNotEmpty) const SizedBox(height: 12),
          Text(
            service.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          if (service.shortDescription != null && service.shortDescription!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              service.shortDescription!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceDescriptionCard extends StatelessWidget {
  const _ServiceDescriptionCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          HtmlWidget(
            description,
            textStyle: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _RelatedServicesSection extends StatelessWidget {
  const _RelatedServicesSection({
    required this.relatedServices,
    required this.onServiceTap,
  });

  final List<ServiceModel> relatedServices;
  final void Function(int serviceId) onServiceTap;

  static const _primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            'Related Services',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 280,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20),
            scrollDirection: Axis.horizontal,
            itemCount: relatedServices.length,
            itemBuilder: (context, index) {
              final s = relatedServices[index];
              return _RelatedServiceCard(
                service: s,
                onTap: () => onServiceTap(s.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RelatedServiceCard extends StatelessWidget {
  const _RelatedServiceCard({required this.service, required this.onTap});

  final ServiceModel service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbUrl = imageUrl(service.thumbnail);
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: SizedBox(
        width: 200,
        child: Material(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (thumbUrl.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: OptimizedNetworkImage(
                      url: thumbUrl,
                      cacheWidth: 200,
                      cacheHeight: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  )
                else
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
  }
}

class _RequestServiceBar extends StatelessWidget {
  const _RequestServiceBar({required this.service});

  final ServiceDetailModel service;

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
      child: FilledButton(
        onPressed: () => ServiceRequestSheet.show(
          context,
          serviceId: service.id,
          serviceName: service.name,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Request Service'),
      ),
    );
  }
}
