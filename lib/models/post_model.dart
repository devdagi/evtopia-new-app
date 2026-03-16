/// Blog post from API. Backend: PostResource.
/// Detail response includes optional pdfs, video_links, images.
class PostModel {
  const PostModel({
    required this.id,
    required this.title,
    this.slug,
    this.shortDescription,
    this.description,
    this.banner,
    this.createdAt,
    this.categories = const [],
    this.pdfs,
    this.videoLinks,
    this.images,
  });

  final int id;
  final String title;
  final String? slug;
  final String? shortDescription;
  final String? description;
  final String? banner;
  final String? createdAt;
  final List<String> categories;
  /// From blog-details: list of { name, size, url }.
  final List<PostPdf>? pdfs;
  final List<String>? videoLinks;
  final List<String>? images;

  static int _int(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0);
  static String? _str(dynamic v) => v?.toString();

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final cats = <String>[];
    final rawCats = json['categories'];
    if (rawCats is List) {
      for (final c in rawCats) {
        if (c is Map && c['name'] != null) {
          cats.add(c['name'].toString());
        } else if (c is String) {
          cats.add(c);
        }
      }
    }
    List<PostPdf>? pdfs;
    if (json['pdfs'] is List) {
      pdfs = (json['pdfs'] as List)
          .whereType<Map<String, dynamic>>()
          .map(PostPdf.fromJson)
          .toList();
    }
    List<String>? videoLinks;
    if (json['video_links'] is List) {
      videoLinks = (json['video_links'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    List<String>? images;
    if (json['images'] is List) {
      images = (json['images'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return PostModel(
      id: _int(json['id']),
      title: _str(json['title']) ?? '',
      slug: _str(json['slug']),
      shortDescription: _str(json['short_description']),
      description: _str(json['description']),
      banner: _str(json['banner']),
      createdAt: _str(json['created_at']),
      categories: cats,
      pdfs: pdfs,
      videoLinks: videoLinks,
      images: images,
    );
  }
}

class PostPdf {
  const PostPdf({this.name, this.size, this.url});
  final String? name;
  final String? size;
  final String? url;
  static PostPdf fromJson(Map<String, dynamic> json) {
    dynamic raw = json['url'] ?? json['path'];
    String? urlStr = raw?.toString();
    return PostPdf(
      name: json['name']?.toString(),
      size: json['size']?.toString(),
      url: urlStr,
    );
  }
}
