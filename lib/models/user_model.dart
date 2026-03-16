/// Vehicle model associated with the user.
class VehicleModel {
  const VehicleModel({
    this.make,
    this.model,
    this.year,
    this.serviceDate,
  });

  final String? make;
  final String? model;
  final String? year;
  final String? serviceDate;

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      make: json['make'] as String?,
      model: json['model'] as String?,
      year: json['year'] as String?,
      serviceDate: json['service_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (make != null) 'make': make,
        if (model != null) 'model': model,
        if (year != null) 'year': year,
        if (serviceDate != null) 'service_date': serviceDate,
      };
}

/// User model from API (register/login response).
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePhoto,
    this.gender,
    this.dateOfBirth,
    this.country,
    this.phoneCode,
    this.vehicle,
    this.emailVerified = true,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePhoto;
  final String? gender;
  final String? dateOfBirth;
  final String? country;
  final String? phoneCode;
  final VehicleModel? vehicle;
  final bool emailVerified;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final ev = json['email_verified'];
    final bool emailVerified = ev == null
        ? true
        : ev is bool
            ? ev
            : (ev is int && ev == 1) || (ev is String && (ev == '1' || ev.toLowerCase() == 'true'));
    final id = json['id'];
    final name = json['name'];
    final email = json['email'];
    return UserModel(
      id: (id is int) ? id : int.tryParse(id?.toString() ?? '0') ?? 0,
      name: (name is String) ? name : (name?.toString() ?? ''),
      email: (email is String) ? email : (email?.toString() ?? ''),
      phone: json['phone'] as String?,
      profilePhoto: json['profile_photo'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      country: json['country'] as String?,
      phoneCode: json['phone_code'] as String?,
      vehicle: json['vehicle'] != null
          ? VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      emailVerified: emailVerified,
    );
  }

  UserModel copyWith({bool? emailVerified}) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      profilePhoto: profilePhoto,
      gender: gender,
      dateOfBirth: dateOfBirth,
      country: country,
      phoneCode: phoneCode,
      vehicle: vehicle,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        if (profilePhoto != null) 'profile_photo': profilePhoto,
        if (gender != null) 'gender': gender,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (country != null) 'country': country,
        if (phoneCode != null) 'phone_code': phoneCode,
        if (vehicle != null) 'vehicle': vehicle!.toJson(),
        'email_verified': emailVerified,
      };
}
