class ProfileModel {
  String name;
  String email;
  String phone;
  String attachment;

  ProfileModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.attachment,
  });

  String getName() {
    return name;
  }

  String getEmail() {
    return email;
  }

  String getPhone() {
    return phone;
  }

  String getAttachment() {
    return attachment;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      attachment: json['attachment'] ?? '',
    );
  }
}
