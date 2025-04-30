class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String type;
  final String? senderName;
  final String? receiverName;
  final String? referenceId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.type,
    this.senderName,
    this.receiverName,
    this.referenceId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      isRead: json['isRead'],
      type: json['type'],
      senderName: json['senderName'],
      receiverName: json['receiverName'],
      referenceId: json['referenceId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class NotificationResponse {
  final List<NotificationModel> data;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final bool lastPage;

  NotificationResponse({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.lastPage,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      data:
          (json['data'] as List)
              .map((item) => NotificationModel.fromJson(item))
              .toList(),
      currentPage: json['currentPage'],
      totalPages: json['totalPages'],
      totalItems: json['totalItems'],
      pageSize: json['pageSize'],
      lastPage: json['lastPage'],
    );
  }
}

class NotificationApiResponse {
  final int statusCodes;
  final NotificationResponse response;

  NotificationApiResponse({required this.statusCodes, required this.response});

  factory NotificationApiResponse.fromJson(Map<String, dynamic> json) {
    return NotificationApiResponse(
      statusCodes: json['statusCodes'],
      response: NotificationResponse.fromJson(json['response']),
    );
  }
}
