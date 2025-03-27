class DeviceModel {
  String id;
  String name;
  String description;
  String attachment;
  bool isActive;
  bool isOnline;

  DeviceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.attachment,
    required this.isActive,
    required this.isOnline,
  });

  String getId() {
    return id;
  }

  String getName() {
    return name;
  }

  String getDescription() {
    return description;
  }

  String getAttachment() {
    return attachment;
  }

  bool getIsActive() {
    return isActive;
  }

  bool getIsOnline() {
    return isOnline;
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      attachment: json['attachment'] ?? '',
      isActive: json['isActive'],
      isOnline: json['isOnline'],
    );
  }
}
