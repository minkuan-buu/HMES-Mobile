class TicketModel {
  String id;
  String briefDescription;
  String type;
  String status;
  DateTime createdAt;

  TicketModel({
    required this.id,
    required this.briefDescription,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  String getId() {
    return id;
  }

  String getBriefDescription() {
    return briefDescription;
  }

  String getType() {
    return type;
  }

  String getStatus() {
    return status;
  }

  DateTime getCreatedAt() {
    return createdAt;
  }

  void setStatus(String status) {
    this.status = status;
  }

  void setCreatedAt(DateTime createdAt) {
    this.createdAt = createdAt;
  }

  void setBriefDescription(String briefDescription) {
    this.briefDescription = briefDescription;
  }

  void setType(String type) {
    this.type = type;
  }

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      briefDescription: json['briefDescription'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class TicketDetailModel {
  String id;
  String userFullName;
  String description;
  String? deviceItemSerial;
  String type;
  String? deviceItemId;
  List<String?> attachments;
  String status;
  String createdBy;
  bool isProcessed;
  DateTime createdAt;
  List<TicketReponseModel?> ticketResponses;

  TicketDetailModel({
    required this.id,
    required this.userFullName,
    required this.description,
    required this.type,
    required this.deviceItemId,
    required this.deviceItemSerial,
    required this.attachments,
    required this.status,
    required this.createdBy,
    required this.isProcessed,
    required this.createdAt,
    required this.ticketResponses,
  });

  String getId() {
    return id;
  }

  String getUserFullName() {
    return userFullName;
  }

  String getDescription() {
    return description;
  }

  String? getDeviceItemSerial() {
    return deviceItemSerial;
  }

  String getType() {
    return type;
  }

  String? getDeviceItemId() {
    return deviceItemId;
  }

  List<String?> getAttachments() {
    return attachments;
  }

  String getStatus() {
    return status;
  }

  String getCreatedBy() {
    return createdBy;
  }

  bool getIsProcessed() {
    return isProcessed;
  }

  DateTime getCreatedAt() {
    return createdAt;
  }

  List<TicketReponseModel?> getTicketResponses() {
    return ticketResponses;
  }

  void setStatus(String status) {
    this.status = status;
  }

  void setCreatedAt(DateTime createdAt) {
    this.createdAt = createdAt;
  }

  void setDescription(String description) {
    this.description = description;
  }

  void setType(String type) {
    this.type = type;
  }

  void setDeviceItemId(String? deviceItemId) {
    this.deviceItemId = deviceItemId;
  }

  void setAttachments(List<String?> attachments) {
    this.attachments = attachments;
  }

  void setCreatedBy(String createdBy) {
    this.createdBy = createdBy;
  }

  void setIsProcessed(bool isProcessed) {
    this.isProcessed = isProcessed;
  }

  void setTicketResponses(List<TicketReponseModel?> ticketResponses) {
    this.ticketResponses = ticketResponses;
  }

  factory TicketDetailModel.fromJson(Map<String, dynamic> json) {
    return TicketDetailModel(
      id: json['id'] as String,
      userFullName: json['userFullName'] as String,
      description: json['description'] as String,
      deviceItemSerial: json['deviceItemSerial'] as String?, // có thể null
      type: json['type'] as String,
      deviceItemId: json['deviceItemId'] as String?, // có thể null
      // Xử lý an toàn nếu attachments là null hoặc không phải danh sách
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as String?)
              .toList() ??
          [],

      status: json['status'] as String,
      createdBy: json['createdBy'] as String,
      isProcessed: json['isProcessed'] as bool,

      // Xử lý nếu createdAt là null hoặc sai định dạng
      createdAt: DateTime.parse(json['createdAt']).toLocal(),

      // Nếu ticketResponses null thì trả list rỗng
      ticketResponses:
          (json['ticketResponses'] as List<dynamic>?)
              ?.map(
                (e) =>
                    e == null
                        ? null
                        : TicketReponseModel.fromJson(
                          e as Map<String, dynamic>,
                        ),
              )
              .toList() ??
          [],
    );
  }
}

class TicketReponseModel {
  String id;
  String message;
  String userId;
  String userFullName;
  DateTime createdAt;
  List<String?> attachments;

  TicketReponseModel({
    required this.id,
    required this.message,
    required this.userId,
    required this.userFullName,
    required this.createdAt,
    required this.attachments,
  });

  factory TicketReponseModel.fromJson(Map<String, dynamic> json) {
    return TicketReponseModel(
      id: json['id'] as String,
      message: json['message'] as String,
      userId: json['userId'] as String,
      userFullName: json['userFullName'] as String,
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as String?)
              .toList() ??
          [],
    );
  }
}

class DeviceItemTicket {
  String id;
  String name;
  bool isAcive;
  bool isOnline;
  String status;

  DeviceItemTicket({
    required this.id,
    required this.name,
    required this.isAcive,
    required this.isOnline,
    required this.status,
  });

  factory DeviceItemTicket.fromJson(Map<String, dynamic> json) {
    return DeviceItemTicket(
      id: json['id'] as String,
      name: json['name'] as String,
      isAcive: json['isActive'] as bool,
      isOnline: json['isOnline'] as bool,
      status: json['status'] as String,
    );
  }
}
