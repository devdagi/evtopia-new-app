/// Contact Us API response – from old_flutter ContactUsModel.
class ContactUsModel {
  const ContactUsModel({
    required this.message,
    required this.data,
  });

  final String message;
  final ContactUsData data;

  factory ContactUsModel.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return ContactUsModel(
      message: json['message'] as String? ?? '',
      data: dataJson is Map<String, dynamic>
          ? ContactUsData.fromMap(dataJson)
          : ContactUsData(phone: '', email: '', whatsapp: '', messenger: null, socialLinks: []),
    );
  }
}

class ContactUsData {
  const ContactUsData({
    required this.phone,
    required this.email,
    required this.whatsapp,
    this.messenger,
    this.socialLinks = const [],
  });

  final String phone;
  final String email;
  final String whatsapp;
  final String? messenger;
  final List<SocialLink> socialLinks;

  factory ContactUsData.fromMap(Map<String, dynamic> map) {
    final links = map['social_links'];
    return ContactUsData(
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      whatsapp: map['whatsapp'] as String? ?? '',
      messenger: map['messenger'] as String?,
      socialLinks: links is List
          ? (links).map((e) => SocialLink.fromMap(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

class SocialLink {
  const SocialLink({
    required this.id,
    required this.name,
    required this.logo,
    required this.link,
  });

  final int id;
  final String name;
  final String logo;
  final String link;

  factory SocialLink.fromMap(Map<String, dynamic> map) {
    return SocialLink(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? '',
      logo: map['logo'] as String? ?? '',
      link: map['link'] as String? ?? '',
    );
  }
}
