class UserProfile {
  String? phone;
  List<Map<String, String>> socialProfiles;

  UserProfile({this.phone, this.socialProfiles = const []});

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'social': socialProfiles,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      phone: map['phone'],
      socialProfiles: List<Map<String, String>>.from(map['social'] ?? []),
    );
  }
}