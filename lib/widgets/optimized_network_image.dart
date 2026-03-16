import 'package:flutter/material.dart';

/// Network image that decodes at display size to reduce memory and jank.
/// Pass [cacheWidth] and [cacheHeight] (in logical pixels); they are scaled by
/// device pixel ratio for decoding. Omit for full resolution.
class OptimizedNetworkImage extends StatelessWidget {
  const OptimizedNetworkImage({
    super.key,
    required this.url,
    this.cacheWidth,
    this.cacheHeight,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String url;
  final double? cacheWidth;
  final double? cacheHeight;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return errorBuilder?.call(context, Object(), StackTrace.current) ??
          const ColoredBox(color: Colors.grey, child: SizedBox.expand());
    }
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final w = cacheWidth != null ? (cacheWidth! * dpr).round() : null;
    final h = cacheHeight != null ? (cacheHeight! * dpr).round() : null;
    return Image.network(
      url,
      fit: fit,
      cacheWidth: w,
      cacheHeight: h,
      errorBuilder: errorBuilder ??
          (context, error, stackTrace) => const ColoredBox(
                color: Colors.grey,
                child: SizedBox.expand(),
              ),
    );
  }
}
