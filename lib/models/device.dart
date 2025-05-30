class DeviceModel {
  String id;
  String name;
  String serial;
  String description;
  String attachment;
  bool isActive;
  bool isOnline;

  DeviceModel({
    required this.id,
    required this.name,
    required this.serial,
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

  String getSerial() {
    return serial;
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
      serial: json['serial'] ?? '',
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
  String plantId;
  String plantName;
  bool isOnline;
  String serial;
  List<phaseResModel>? phases;
  IoTResModel? ioTData;
  DateTime? warrantyExpiryDate;
  DateTime? lastUpdatedDate;
  int refreshCycleHours;

  DeviceItemModel({
    required this.deviceItemId,
    required this.deviceItemName,
    required this.type,
    required this.plantId,
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

  String getPlantId() {
    return plantId;
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

  void setPlantId(String plantId) {
    this.plantId = plantId;
  }

  int getRefreshCycleHours() {
    return refreshCycleHours;
  }

  void setRefreshCycleHours(int hours) {
    refreshCycleHours = hours;
  }

  void setPhases(List<phaseResModel> phases) {
    this.phases = phases;
  }

  List<phaseResModel>? getPhases() {
    return phases;
  }

  factory DeviceItemModel.fromJson(Map<String, dynamic> json) {
    return DeviceItemModel(
      deviceItemId: json['deviceItemId'],
      deviceItemName: json['deviceItemName'],
      type: json['type'],
      plantId: json['plantId'],
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

class phaseResModel {
  String id;
  String? phaseName;
  bool isDefault;
  bool isSelected;

  phaseResModel({
    required this.id,
    this.phaseName,
    required this.isDefault,
    required this.isSelected,
  });

  String getId() {
    return id;
  }

  String? getPhaseName() {
    return phaseName;
  }

  bool getIsDefault() {
    return isDefault;
  }

  bool getIsSelected() {
    return isSelected;
  }

  void setIsSelected(bool isSelected) {
    this.isSelected = isSelected;
  }

  factory phaseResModel.fromJson(Map<String, dynamic> json) {
    return phaseResModel(
      id: json['id'],
      phaseName: json['phaseName'],
      isDefault: json['isDefault'] ?? false,
      isSelected: json['isSelected'] ?? false,
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

class HistoryLogModel {
  String deviceItemId;
  String deviceItemName;
  List<IoTHistoryResModel>? ioTData;

  HistoryLogModel({
    required this.deviceItemId,
    required this.deviceItemName,
    required this.ioTData,
  });

  factory HistoryLogModel.fromJson(Map<String, dynamic> json) {
    return HistoryLogModel(
      deviceItemId: json['deviceItemId'],
      deviceItemName: json['deviceItemName'],
      ioTData:
          json['ioTData'] != null
              ? (json['ioTData'] as List)
                  .map((item) => IoTHistoryResModel.fromJson(item))
                  .toList()
              : null,
    );
  }
}

class IoTHistoryResModel {
  String nutrionId;
  double soluteConcentration;
  double temperature;
  double ph;
  int waterLevel;
  DateTime createdAt;

  IoTHistoryResModel({
    required this.nutrionId,
    required this.soluteConcentration,
    required this.temperature,
    required this.ph,
    required this.waterLevel,
    required this.createdAt,
  });

  String getNutrionId() {
    return nutrionId;
  }

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

  DateTime getCreatedAt() {
    return createdAt;
  }

  factory IoTHistoryResModel.fromJson(Map<String, dynamic> json) {
    return IoTHistoryResModel(
      nutrionId: json['nutrionId'],
      soluteConcentration: json['soluteConcentration']?.toDouble() ?? 0,
      temperature: json['temperature']?.toDouble() ?? 0,
      ph: json['ph']?.toDouble() ?? 0.0,
      waterLevel: (json['waterLevel'] ?? 0).round(),
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
    );
  }
}
