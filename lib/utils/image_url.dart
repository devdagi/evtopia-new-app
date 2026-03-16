import '../core/constants/api_constants.dart';

/// Build full URL for image if path is relative.
String imageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/$'), '');
  final p = path.startsWith('/') ? path : '/$path';
  return '$base$p';
}
