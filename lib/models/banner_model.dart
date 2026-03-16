/// Banner from API (home/banners). Backend: BannerResource.
class BannerModel {
  const BannerModel({
    required this.id,
    this.title,
    this.ctaText,
    this.ctaUrl,
    this.description,
    this.thumbnail,
  });

  final int id;
  final String? title;
  final String? ctaText;
  final String? ctaUrl;
  final String? description;
  final String? thumbnail;

  static int _int(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0);
  static String? _str(dynamic v) => v?.toString();

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: _int(json['id']),
      title: _str(json['title']),
      ctaText: _str(json['cta_text']),
      ctaUrl: _str(json['cta_url']),
      description: _str(json['description']),
      thumbnail: _str(json['thumbnail']),
    );
  }
}
