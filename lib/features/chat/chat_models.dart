
/// Message status enum
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Message type enum
enum MessageType {
  text,
  image,
  file,
  system,
}

/// Chat message model
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.readAt,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? json['conversationId'] ?? '',
      senderId: json['sender_id'] ?? json['senderId'] ?? '',
      senderName: json['sender_name'] ?? json['senderName'] ?? '',
      senderAvatar: json['sender_avatar'] ?? json['senderAvatar'],
      content: json['content'] ?? '',
      type: _parseMessageType(json['type']),
      status: _parseMessageStatus(json['status']),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }

  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;
    final typeString = type.toString().toLowerCase();
    switch (typeString) {
      case 'text': return MessageType.text;
      case 'image': return MessageType.image;
      case 'file': return MessageType.file;
      case 'system': return MessageType.system;
      default: return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(dynamic status) {
    if (status == null) return MessageStatus.sent;
    final statusString = status.toString().toLowerCase();
    switch (statusString) {
      case 'sending': return MessageStatus.sending;
      case 'sent': return MessageStatus.sent;
      case 'delivered': return MessageStatus.delivered;
      case 'read': return MessageStatus.read;
      case 'failed': return MessageStatus.failed;
      default: return MessageStatus.sent;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, sender: $senderName, content: $content, status: $status)';
  }
}

/// Conversation model
class Conversation {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String? propertyImage;
  final String buyerId;
  final String buyerName;
  final String? buyerAvatar;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatar;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const Conversation({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    this.propertyImage,
    required this.buyerId,
    required this.buyerName,
    this.buyerAvatar,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatar,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      propertyId: json['property_id'] ?? json['propertyId'] ?? '',
      propertyTitle: json['property_title'] ?? json['propertyTitle'] ?? '',
      propertyImage: json['property_image'] ?? json['propertyImage'],
      buyerId: json['buyer_id'] ?? json['buyerId'] ?? '',
      buyerName: json['buyer_name'] ?? json['buyerName'] ?? '',
      buyerAvatar: json['buyer_avatar'] ?? json['buyerAvatar'],
      sellerId: json['seller_id'] ?? json['sellerId'] ?? '',
      sellerName: json['seller_name'] ?? json['sellerName'] ?? '',
      sellerAvatar: json['seller_avatar'] ?? json['sellerAvatar'],
      lastMessage: json['last_message'] != null 
          ? ChatMessage.fromJson(json['last_message']) 
          : null,
      unreadCount: json['unread_count'] ?? json['unreadCount'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'property_title': propertyTitle,
      'property_image': propertyImage,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'buyer_avatar': buyerAvatar,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'seller_avatar': sellerAvatar,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  Conversation copyWith({
    String? id,
    String? propertyId,
    String? propertyTitle,
    String? propertyImage,
    String? buyerId,
    String? buyerName,
    String? buyerAvatar,
    String? sellerId,
    String? sellerName,
    String? sellerAvatar,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Conversation(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyImage: propertyImage ?? this.propertyImage,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerAvatar: buyerAvatar ?? this.buyerAvatar,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Conversation(id: $id, property: $propertyTitle, buyer: $buyerName, seller: $sellerName)';
  }
}

/// Chat participant model
class ChatParticipant {
  final String id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeen;

  const ChatParticipant({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      isOnline: json['is_online'] ?? json['isOnline'] ?? false,
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatParticipant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatParticipant(id: $id, name: $name, isOnline: $isOnline)';
  }
}
