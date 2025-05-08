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
      description: json['description'] ?? '',
      attachment: json['attachment'] ?? '',
      isActive: json['isActive'],
      isOnline: json['isOnline'],
    );
  }
}

class DeviceItemModel {
  String deviceItemId;
  String deviceItemName;
  String type;
  String plantName;
  bool isOnline;
  String serial;
  IoTResModel? ioTData;
  DateTime? warrantyExpiryDate;
  DateTime? lastUpdatedDate;
  int refreshCycleHours;

  DeviceItemModel({
    required this.deviceItemId,
    required this.deviceItemName,
    required this.type,
    required this.plantName,
    required this.serial,
    required this.isOnline,
    required this.warrantyExpiryDate,
    required this.lastUpdatedDate,
    required this.refreshCycleHours,
  });

  String getDeviceItemId() {
    return deviceItemId;
  }

  String getDeviceItemName() {
    return deviceItemName;
  }

  String getType() {
    return type;
  }

  String getPlantName() {
    return plantName;
  }

  String getSerial() {
    return serial;
  }

  bool getIsOnline() {
    return isOnline;
  }

  IoTResModel? getIoTData() {
    return ioTData;
  }

  DateTime? getWarrantyExpiryDate() {
    return warrantyExpiryDate;
  }

  DateTime? getLastUpdatedDate() {
    return lastUpdatedDate;
  }

  void setIoTData(IoTResModel data) {
    ioTData = data;
  }

  int getRefreshCycleHours() {
    return refreshCycleHours;
  }

  void setRefreshCycleHours(int hours) {
    refreshCycleHours = hours;
  }

  factory DeviceItemModel.fromJson(Map<String, dynamic> json) {
    return DeviceItemModel(
      deviceItemId: json['deviceItemId'],
      deviceItemName: json['deviceItemName'],
      type: json['type'],
      plantName: json['plantName'],
      serial: json['serial'],
      isOnline: json['isOnline'],
      refreshCycleHours: json['refreshCycleHours'] ?? 0,
      warrantyExpiryDate:
          json['warrantyExpiryDate'] != null
              ? DateTime.parse(json['warrantyExpiryDate'])
                  .toLocal() // ✅ Chuyển về giờ địa phương
              : null,
      lastUpdatedDate:
          json['lastUpdatedDate'] != null
              ? DateTime.parse(json['lastUpdatedDate'])
                  .toLocal() // ✅ Chuyển về giờ địa phương
              : null,
    );
  }
}

class IoTResModel {
  double soluteConcentration;
  double temperature;
  double ph;
  int waterLevel;

  IoTResModel({
    required this.soluteConcentration,
    required this.temperature,
    required this.ph,
    required this.waterLevel,
  });

  double getSoluteConcentration() {
    return soluteConcentration;
  }

  double getTemperature() {
    return temperature;
  }

  double getPh() {
    return ph;
  }

  int getWaterLevel() {
    return waterLevel;
  }

  factory IoTResModel.fromJson(Map<String, dynamic> json) {
    return IoTResModel(
      soluteConcentration: json['soluteConcentration']?.toDouble() ?? 0,
      temperature: json['temperature']?.toDouble() ?? 0,
      ph: json['ph']?.toDouble() ?? 0.0,
      waterLevel: (json['waterLevel'] ?? 0).round(),
    );
  }
}

class PlantModel {
  String id;
  String name;
  String status;

  PlantModel({required this.id, required this.name, required this.status});

  String getId() {
    return id;
  }

  String getName() {
    return name;
  }

  String getStatus() {
    return status;
  }

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['id'],
      name: json['name'],
      status: json['status'],
    );
  }
}
