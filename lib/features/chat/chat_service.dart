import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../config/env_config.dart';
import 'chat_models.dart';
import 'chat_notification_service.dart';

/// Chat service for handling messaging functionality
class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Mock data storage
  final List<Conversation> _conversations = [];
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, ChatParticipant> _participants = {};
  
  // Current conversation
  String? _currentConversationId;
  
  // Getters
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  String? get currentConversationId => _currentConversationId;
  
  List<ChatMessage> getMessages(String conversationId) {
    return List.unmodifiable(_messages[conversationId] ?? []);
  }
  
  ChatParticipant? getParticipant(String participantId) {
    return _participants[participantId];
  }

  /// Initialize mock data
  void _initializeMockData() {
    // Mock participants
    _participants['user_001'] = ChatParticipant(
      id: 'user_001',
      name: 'John Doe',
      avatar: 'https://via.placeholder.com/150/4F46E5/FFFFFF?text=JD',
      isOnline: true,
    );
    
    _participants['user_002'] = ChatParticipant(
      id: 'user_002',
      name: 'Jane Smith',
      avatar: 'https://via.placeholder.com/150/059669/FFFFFF?text=JS',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 15)),
    );
    
    _participants['user_003'] = ChatParticipant(
      id: 'user_003',
      name: 'Mike Wilson',
      avatar: 'https://via.placeholder.com/150/F59E0B/FFFFFF?text=MW',
      isOnline: true,
    );

    // Mock conversations
    final conversation1 = Conversation(
      id: 'conv_001',
      propertyId: 'prop_001',
      propertyTitle: 'Modern Apartment in Downtown',
      propertyImage: 'https://via.placeholder.com/300x200/4F46E5/FFFFFF?text=Apartment',
      buyerId: 'user_001',
      buyerName: 'John Doe',
      buyerAvatar: 'https://via.placeholder.com/150/4F46E5/FFFFFF?text=JD',
      sellerId: 'user_002',
      sellerName: 'Jane Smith',
      sellerAvatar: 'https://via.placeholder.com/150/059669/FFFFFF?text=JS',
      unreadCount: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    final conversation2 = Conversation(
      id: 'conv_002',
      propertyId: 'prop_002',
      propertyTitle: 'Luxury Villa with Garden',
      propertyImage: 'https://via.placeholder.com/300x200/059669/FFFFFF?text=Villa',
      buyerId: 'user_003',
      buyerName: 'Mike Wilson',
      buyerAvatar: 'https://via.placeholder.com/150/F59E0B/FFFFFF?text=MW',
      sellerId: 'user_001',
      sellerName: 'John Doe',
      sellerAvatar: 'https://via.placeholder.com/150/4F46E5/FFFFFF?text=JD',
      unreadCount: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    _conversations.addAll([conversation1, conversation2]);

    // Mock messages for conversation 1
    _messages['conv_001'] = [
      ChatMessage(
        id: 'msg_001',
        conversationId: 'conv_001',
        senderId: 'user_001',
        senderName: 'John Doe',
        senderAvatar: 'https://via.placeholder.com/150/4F46E5/FFFFFF?text=JD',
        content: 'Hi! I\'m interested in your apartment. Is it still available?',
        timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_002',
        conversationId: 'conv_001',
        senderId: 'user_002',
        senderName: 'Jane Smith',
        senderAvatar: 'https://via.placeholder.com/150/059669/FFFFFF?text=JS',
        content: 'Yes, it\'s still available! Would you like to schedule a viewing?',
        timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 1, minutes: 30)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_003',
        conversationId: 'conv_001',
        senderId: 'user_001',
        senderName: 'John Doe',
        senderAvatar: 'https://via.placeholder.com/150/4F46E5/FFFFFF?text=JD',
        content: 'That would be great! What times work for you?',
        timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_004',
        conversationId: 'conv_001',
        senderId: 'user_002',
        senderName: 'Jane Smith',
        senderAvatar: 'https://via.placeholder.com/150/059669/FFFFFF?text=JS',
        content: 'I\'m available tomorrow afternoon or this weekend. What works better for you?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        status: MessageStatus.delivered,
      ),
      ChatMessage(
        id: 'msg_005',
        conversationId: 'conv_001',
        senderId: 'user_002',
        senderName: 'Jane Smith',
        senderAvatar: 'https://via.placeholder.com/150/059669/FFFFFF?text=JS',
        content: 'Also, I can send you more photos if you\'d like!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: MessageStatus.delivered,
      ),
    ];

    // Mock messages for conversation 2
    _messages['conv_002'] = [
      ChatMessage(
        id: 'msg_006',
        conversationId: 'conv_002',
        senderId: 'user_003',
        senderName: 'Mike Wilson',
        senderAvatar: 'https://via.placeholder.com/150/F59E0B/FFFFFF?text=MW',
        content: 'Hello! I saw your villa listing. It looks amazing!',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_007',
        conversationId: 'conv_002',
        senderId: 'user_001',
        senderName: 'John Doe',
        senderAvatar: 'https://via.placeholder.com/150/4F46E5/FFFFFF?text=JD',
        content: 'Thank you! Yes, it\'s a beautiful property with a lovely garden.',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 45)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_008',
        conversationId: 'conv_002',
        senderId: 'user_003',
        senderName: 'Mike Wilson',
        senderAvatar: 'https://via.placeholder.com/150/F59E0B/FFFFFF?text=MW',
        content: 'Is the price negotiable?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
      ),
    ];

    // Update last messages in conversations
    _updateLastMessages();
  }

  /// Update last messages in conversations
  void _updateLastMessages() {
    for (final conversation in _conversations) {
      final messages = _messages[conversation.id];
      if (messages != null && messages.isNotEmpty) {
        final lastMessage = messages.last;
        final updatedConversation = conversation.copyWith(
          lastMessage: lastMessage,
          updatedAt: lastMessage.timestamp,
        );
        final index = _conversations.indexWhere((c) => c.id == conversation.id);
        if (index != -1) {
          _conversations[index] = updatedConversation;
        }
      }
    }
  }

  /// Fetch conversations for a user
  Future<List<Conversation>> fetchConversations({String? token}) async {
    // Check if mock data mode is enabled
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for conversations (useMockData: true)');
      }
      if (_conversations.isEmpty) {
        _initializeMockData();
      }
      return _conversations;
    }

    try {
      // Try to fetch from API
      if (kDebugMode) {
        debugPrint('🌐 Fetching conversations from API (useMockData: false)');
      }
      final response = await apiClient.get('/chat/conversations', token: token);
      
      if (response['data'] != null && response['data'] is List) {
        final List<dynamic> conversationsData = response['data'];
        _conversations.clear();
        _conversations.addAll(
          conversationsData.map((data) => Conversation.fromJson(data))
        );
        notifyListeners();
        return _conversations;
      } else {
        // Fall back to mock data
        if (kDebugMode) {
          debugPrint('⚠️ Unexpected conversations API response format, using mock data');
        }
        if (_conversations.isEmpty) {
          _initializeMockData();
        }
        return _conversations;
      }
    } catch (e) {
      // If API call fails, fall back to mock data
      if (kDebugMode) {
        debugPrint('⚠️ Conversations API call failed, using mock data: $e');
      }
      if (_conversations.isEmpty) {
        _initializeMockData();
      }
      return _conversations;
    }
  }

  /// Fetch messages for a conversation
  Future<List<ChatMessage>> fetchMessages(String conversationId, {String? token}) async {
    // Check if mock data mode is enabled
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for messages (useMockData: true)');
      }
      if (_messages.isEmpty) {
        _initializeMockData();
      }
      return _messages[conversationId] ?? [];
    }

    try {
      // Try to fetch from API
      if (kDebugMode) {
        debugPrint('🌐 Fetching messages from API (useMockData: false)');
      }
      final response = await apiClient.get('/chat/conversations/$conversationId/messages', token: token);
      
      if (response['data'] != null && response['data'] is List) {
        final List<dynamic> messagesData = response['data'];
        final messages = messagesData.map((data) => ChatMessage.fromJson(data)).toList();
        _messages[conversationId] = messages;
        notifyListeners();
        return messages;
      } else {
        // Fall back to mock data
        if (kDebugMode) {
          debugPrint('⚠️ Unexpected messages API response format, using mock data');
        }
        if (_messages.isEmpty) {
          _initializeMockData();
        }
        return _messages[conversationId] ?? [];
      }
    } catch (e) {
      // If API call fails, fall back to mock data
      if (kDebugMode) {
        debugPrint('⚠️ Messages API call failed, using mock data: $e');
      }
      if (_messages.isEmpty) {
        _initializeMockData();
      }
      return _messages[conversationId] ?? [];
    }
  }

  /// Send a message
  Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String content,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    MessageType type = MessageType.text,
    String? token,
  }) async {
    // Create message
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      type: type,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );

    // Add to local storage immediately
    _messages[conversationId] ??= [];
    _messages[conversationId]!.add(message);
    notifyListeners();

    // Check if mock data mode is enabled
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for sending message (useMockData: true)');
      }
      // Simulate sending delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update message status to sent
      final sentMessage = message.copyWith(status: MessageStatus.sent);
      final index = _messages[conversationId]!.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messages[conversationId]![index] = sentMessage;
      }
      
      // Update conversation
      _updateLastMessages();
      notifyListeners();
      
      return sentMessage;
    }

    try {
      // Try to send via API
      if (kDebugMode) {
        debugPrint('🌐 Sending message via API (useMockData: false)');
      }
      final response = await apiClient.post(
        '/chat/conversations/$conversationId/messages',
        token: token,
        body: {
          'content': content,
          'type': type.name,
          'sender_id': senderId,
        },
      );

      if (response['data'] != null) {
        final sentMessage = ChatMessage.fromJson(response['data']);
        final index = _messages[conversationId]!.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[conversationId]![index] = sentMessage;
        }
        
        // Update conversation
        _updateLastMessages();
        notifyListeners();
        
        return sentMessage;
      } else {
        // Mark as failed
        final failedMessage = message.copyWith(status: MessageStatus.failed);
        final index = _messages[conversationId]!.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[conversationId]![index] = failedMessage;
        }
        notifyListeners();
        return null;
      }
    } catch (e) {
      // Mark as failed
      if (kDebugMode) {
        debugPrint('⚠️ Send message API call failed: $e');
      }
      final failedMessage = message.copyWith(status: MessageStatus.failed);
      final index = _messages[conversationId]!.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messages[conversationId]![index] = failedMessage;
      }
      notifyListeners();
      return null;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, {String? token}) async {
    // Update local messages
    final messages = _messages[conversationId];
    if (messages != null) {
      for (int i = 0; i < messages.length; i++) {
        if (messages[i].status != MessageStatus.read) {
          _messages[conversationId]![i] = messages[i].copyWith(
            status: MessageStatus.read,
            readAt: DateTime.now(),
          );
        }
      }
    }

    // Update conversation unread count
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
        unreadCount: 0,
      );
    }

    notifyListeners();

    // Check if mock data mode is enabled
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for marking messages as read (useMockData: true)');
      }
      return;
    }

    try {
      // Try to update via API
      if (kDebugMode) {
        debugPrint('🌐 Marking messages as read via API (useMockData: false)');
      }
      await apiClient.post(
        '/chat/conversations/$conversationId/read',
        token: token,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Mark messages as read API call failed: $e');
      }
    }
  }

  /// Create a new conversation
  Future<Conversation?> createConversation({
    required String propertyId,
    required String buyerId,
    required String sellerId,
    String? token,
  }) async {
    // Check if mock data mode is enabled
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for creating conversation (useMockData: true)');
      }
      // Simulate creating conversation
      await Future.delayed(const Duration(milliseconds: 300));
      
      final conversation = Conversation(
        id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
        propertyId: propertyId,
        propertyTitle: 'Property Title', // This would come from property data
        buyerId: buyerId,
        buyerName: 'Buyer Name', // This would come from user data
        sellerId: sellerId,
        sellerName: 'Seller Name', // This would come from user data
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _conversations.insert(0, conversation);
      notifyListeners();
      
      return conversation;
    }

    try {
      // Try to create via API
      if (kDebugMode) {
        debugPrint('🌐 Creating conversation via API (useMockData: false)');
      }
      final response = await apiClient.post(
        '/chat/conversations',
        token: token,
        body: {
          'property_id': propertyId,
          'buyer_id': buyerId,
          'seller_id': sellerId,
        },
      );

      if (response['data'] != null) {
        final conversation = Conversation.fromJson(response['data']);
        _conversations.insert(0, conversation);
        notifyListeners();
        return conversation;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Create conversation API call failed: $e');
      }
      return null;
    }
  }

  /// Set current conversation
  void setCurrentConversation(String? conversationId) {
    _currentConversationId = conversationId;
    notifyListeners();
  }

  /// Get conversation by ID
  Conversation? getConversation(String conversationId) {
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  /// Get total unread count
  int getTotalUnreadCount() {
    return _conversations.fold(0, (sum, conversation) => sum + conversation.unreadCount);
  }

  /// Clear all data (useful for testing)
  void clearAllData() {
    _conversations.clear();
    _messages.clear();
    _participants.clear();
    _currentConversationId = null;
    notifyListeners();
  }

  /// Simulate receiving a new message (for testing notifications)
  Future<void> simulateIncomingMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    BuildContext? context,
  }) async {
    // Create the incoming message
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: MessageType.text,
      status: MessageStatus.delivered,
      timestamp: DateTime.now(),
    );

    // Add to messages
    _messages[conversationId] ??= [];
    _messages[conversationId]!.add(message);

    // Update conversation
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
        lastMessage: message,
        updatedAt: message.timestamp,
        unreadCount: _conversations[conversationIndex].unreadCount + 1,
      );
    }

    notifyListeners();

    // Show notification if context is provided
    if (context != null) {
      final notificationService = ChatNotificationService();
      await notificationService.showNewMessageNotification(
        context: context,
        message: message,
        senderName: senderName,
      );
    }

    if (kDebugMode) {
      debugPrint('📨 Simulated incoming message from $senderName: $content');
    }
  }

  /// Simulate receiving a new conversation (for testing notifications)
  Future<void> simulateNewConversation({
    required String propertyId,
    required String propertyTitle,
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String sellerName,
    BuildContext? context,
  }) async {
    // Create new conversation
    final conversation = Conversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      buyerId: buyerId,
      buyerName: buyerName,
      sellerId: sellerId,
      sellerName: sellerName,
      unreadCount: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add to conversations
    _conversations.insert(0, conversation);

    notifyListeners();

    // Show notification if context is provided
    if (context != null) {
      final notificationService = ChatNotificationService();
      await notificationService.showNewConversationNotification(
        context: context,
        conversation: conversation,
      );
    }

    if (kDebugMode) {
      debugPrint('💬 Simulated new conversation about $propertyTitle');
    }
  }
}
