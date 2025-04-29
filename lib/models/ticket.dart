class TicketModel {
  String Id;
  String briefDescription;
  String type;
  String status;
  DateTime createdAt;

  TicketModel({
    required this.Id,
    required this.briefDescription,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  String getId() {
    return Id;
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
      Id: json['Id'] as String,
      briefDescription: json['briefDescription'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
