
enum NotificationType {
  propertyExpiry,
  newListing,
  chatMessage,
  system,
  slotExpiry,
  verification
}

class DaryNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final String? propertyId;
  final String? chatId;
  bool isRead;

  DaryNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.propertyId,
    this.chatId,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'propertyId': propertyId,
      'chatId': chatId,
      'isRead': isRead,
    };
  }

  factory DaryNotification.fromJson(Map<String, dynamic> json) {
    return DaryNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      type: NotificationType.values[json['type']],
      propertyId: json['propertyId'],
      chatId: json['chatId'],
      isRead: json['isRead'] ?? false,
    );
  }

  DaryNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    String? propertyId,
    String? chatId,
    bool? isRead,
  }) {
    return DaryNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      propertyId: propertyId ?? this.propertyId,
      chatId: chatId ?? this.chatId,
      isRead: isRead ?? this.isRead,
    );
  }
}
