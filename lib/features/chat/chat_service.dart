import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../services/api_client.dart';
import '../../config/env_config.dart';
import 'chat_models.dart';
import 'chat_notification_service.dart';

/// Chat service for handling messaging functionality
class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mock data storage
  final List<Conversation> _conversations = [];
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, ChatParticipant> _participants = {};
  
  // Current conversation
  String? _currentConversationId;
  String? _currentUserId;
  
  // Stream subscriptions for real-time updates
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<QuerySnapshot>? _buyerConversationsSubscription;
  StreamSubscription<QuerySnapshot>? _sellerConversationsSubscription;
  
  // Getters
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  String? get currentConversationId => _currentConversationId;
  // Set current user id so service can distinguish incoming vs outgoing
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  /// Start listening to all conversations for the current user (buyer or seller)
  void startListeningToUserConversations(String userId) {
    // Cancel existing
    _buyerConversationsSubscription?.cancel();
    _sellerConversationsSubscription?.cancel();

    // Helper to upsert conversations from snapshot
    void _upsertFromSnapshot(QuerySnapshot snapshot) {
      bool changed = false;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final updatedAt = DateTime.tryParse(data['updatedAt'] ?? data['updated_at'] ?? '') ?? DateTime.now();
        final createdAt = DateTime.tryParse(data['createdAt'] ?? data['created_at'] ?? '') ?? updatedAt;
        final lastSenderId = (data['lastMessageSenderId'] ?? '').toString();
        final conversation = Conversation(
          id: data['id'] ?? doc.id,
          propertyId: data['propertyId'] ?? '',
          propertyTitle: (data['propertyTitle'] ?? '').toString(),
          buyerId: data['buyerId'] ?? '',
          buyerName: (data['buyerName'] ?? '').toString(),
          sellerId: data['sellerId'] ?? '',
          sellerName: (data['sellerName'] ?? '').toString(),
          lastMessage: data['lastMessage'] != null
              ? ChatMessage(
                  id: 'last_${doc.id}',
                  conversationId: doc.id,
                  senderId: lastSenderId,
                  senderName: (data['lastMessageSenderName'] ?? '').toString(),
                  content: (data['lastMessage'] ?? '').toString(),
                  status: MessageStatus.delivered,
                  timestamp: updatedAt,
                )
              : null,
          createdAt: createdAt,
          updatedAt: updatedAt,
          // Compute per-user unread count
          unreadCount: () {
            final buyerUnread = (data['buyerUnreadCount'] ?? 0);
            final sellerUnread = (data['sellerUnreadCount'] ?? 0);
            final b = buyerUnread is int ? buyerUnread : (buyerUnread as num).toInt();
            final s = sellerUnread is int ? sellerUnread : (sellerUnread as num).toInt();
            if (_currentUserId != null) {
              if (_currentUserId == (data['buyerId'] ?? '')) return b;
              if (_currentUserId == (data['sellerId'] ?? '')) return s;
            }
            // Fallback to combined if current user unknown
            return b + s;
          }(),
        );
        final index = _conversations.indexWhere((c) => c.id == conversation.id);
        if (index == -1) {
          // If new and incoming, increment locally and in Firestore
          final isIncoming = _currentUserId != null && lastSenderId.isNotEmpty && lastSenderId != _currentUserId;
          final isViewing = _currentConversationId == conversation.id;
          final initial = (isIncoming && !isViewing)
              ? conversation.copyWith(unreadCount: conversation.unreadCount + 1)
              : conversation;
          _conversations.add(initial);
          if (isIncoming && !isViewing) {
            _firestore.collection('conversations').doc(conversation.id).update({
              'unreadCount': FieldValue.increment(1),
            }).catchError((_) {});
          }
          changed = true;
        } else {
          final prev = _conversations[index];
          var next = conversation;
          final isNewer = conversation.updatedAt.isAfter(prev.updatedAt);
          final isIncoming = _currentUserId != null && lastSenderId.isNotEmpty && lastSenderId != _currentUserId;
          final isViewing = _currentConversationId == conversation.id;
          if (isNewer && isIncoming && !isViewing) {
            next = conversation.copyWith(unreadCount: prev.unreadCount + 1);
            _firestore.collection('conversations').doc(conversation.id).update({
              'unreadCount': FieldValue.increment(1),
            }).catchError((_) {});
            // Show in-app banner
            final last = next.lastMessage ?? ChatMessage(
              id: 'last_${conversation.id}',
              conversationId: conversation.id,
              senderId: lastSenderId,
              senderName: conversation.sellerName,
              content: (data['lastMessage'] ?? '').toString(),
              timestamp: updatedAt,
            );
            ChatNotificationService().showNewMessageNotification(
              message: last,
              senderName: last.senderName.isNotEmpty ? last.senderName : 'New message',
            );
          }
          if (prev.updatedAt != next.updatedAt ||
              prev.unreadCount != next.unreadCount ||
              (prev.lastMessage?.content != next.lastMessage?.content)) {
            _conversations[index] = next;
            changed = true;
          }
        }
      }
      if (changed) {
        // Keep list sorted by updatedAt desc
        _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        notifyListeners();
      }
    }

    _buyerConversationsSubscription = _firestore
        .collection('conversations')
        .where('buyerId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(_upsertFromSnapshot, onError: (_) {});

    _sellerConversationsSubscription = _firestore
        .collection('conversations')
        .where('sellerId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(_upsertFromSnapshot, onError: (_) {});
  }

  void stopListeningToUserConversations() {
    _buyerConversationsSubscription?.cancel();
    _buyerConversationsSubscription = null;
    _sellerConversationsSubscription?.cancel();
    _sellerConversationsSubscription = null;
  }
  
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
      avatar: null, // Use null instead of placeholder URL
      isOnline: true,
    );
    
    _participants['user_002'] = ChatParticipant(
      id: 'user_002',
      name: 'Jane Smith',
      avatar: null, // Use null instead of placeholder URL
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 15)),
    );
    
    _participants['user_003'] = ChatParticipant(
      id: 'user_003',
      name: 'Mike Wilson',
      avatar: null, // Use null instead of placeholder URL
      isOnline: true,
    );

    // Mock conversations
    final conversation1 = Conversation(
      id: 'conv_001',
      propertyId: 'prop_001',
      propertyTitle: 'Modern Apartment in Downtown',
      propertyImage: null,
      buyerId: 'user_001',
      buyerName: 'John Doe',
      buyerAvatar: null,
      sellerId: 'user_002',
      sellerName: 'Jane Smith',
      sellerAvatar: null,
      unreadCount: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    final conversation2 = Conversation(
      id: 'conv_002',
      propertyId: 'prop_002',
      propertyTitle: 'Luxury Villa with Garden',
      propertyImage: null,
      buyerId: 'user_003',
      buyerName: 'Mike Wilson',
      buyerAvatar: null,
      sellerId: 'user_001',
      sellerName: 'John Doe',
      sellerAvatar: null,
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
        senderAvatar: null,
        content: 'Hi! I\'m interested in your apartment. Is it still available?',
        timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_002',
        conversationId: 'conv_001',
        senderId: 'user_002',
        senderName: 'Jane Smith',
        senderAvatar: null,
        content: 'Yes, it\'s still available! Would you like to schedule a viewing?',
        timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 1, minutes: 30)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_003',
        conversationId: 'conv_001',
        senderId: 'user_001',
        senderName: 'John Doe',
        senderAvatar: null,
        content: 'That would be great! What times work for you?',
        timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_004',
        conversationId: 'conv_001',
        senderId: 'user_002',
        senderName: 'Jane Smith',
        senderAvatar: null,
        content: 'I\'m available tomorrow afternoon or this weekend. What works better for you?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        status: MessageStatus.delivered,
      ),
      ChatMessage(
        id: 'msg_005',
        conversationId: 'conv_001',
        senderId: 'user_002',
        senderName: 'Jane Smith',
        senderAvatar: null,
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
        senderAvatar: null,
        content: 'Hello! I saw your villa listing. It looks amazing!',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_007',
        conversationId: 'conv_002',
        senderId: 'user_001',
        senderName: 'John Doe',
        senderAvatar: null,
        content: 'Thank you! Yes, it\'s a beautiful property with a lovely garden.',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 45)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_008',
        conversationId: 'conv_002',
        senderId: 'user_003',
        senderName: 'Mike Wilson',
        senderAvatar: null,
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
  Future<List<Conversation>> fetchConversations({String? token, String? userId}) async {
    // Check if mock data mode is enabled
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for conversations (useMockData: true)');
      }
      if (_conversations.isEmpty) {
        _initializeMockData();
      }
      // Filter by userId even in mock data mode
      if (userId != null) {
        return _conversations.where((conv) => 
          conv.buyerId == userId || conv.sellerId == userId
        ).toList();
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
        final allConversations = conversationsData.map((data) => Conversation.fromJson(data)).toList();
        
        // Filter by userId if provided
        if (userId != null) {
          _conversations.addAll(allConversations.where((conv) => 
            conv.buyerId == userId || conv.sellerId == userId
          ));
        } else {
          _conversations.addAll(allConversations);
        }
        
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
        // Filter by userId even in fallback
        if (userId != null) {
          return _conversations.where((conv) => 
            conv.buyerId == userId || conv.sellerId == userId
          ).toList();
        }
        return _conversations;
      }
    } catch (e) {
      // If API call fails, fall back to Firebase
      if (kDebugMode) {
        debugPrint('! Conversations API call failed, using Firebase: $e');
      }
      if (kDebugMode) {
        debugPrint('🔄 Falling back to Firebase conversation storage');
      }
      
      return await _fetchConversationsFromFirebase(userId);
    }
  }

  /// Fetch conversations from Firebase Firestore
  Future<List<Conversation>> _fetchConversationsFromFirebase([String? userId]) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Fetching conversations from Firebase${userId != null ? " for user: $userId" : ""}');
      }
      
      Query query = _firestore
          .collection('conversations')
          .orderBy('updatedAt', descending: true);
      
      // Filter by userId if provided - user can be either buyer or seller
      if (userId != null) {
        query = _firestore
            .collection('conversations')
            .where('buyerId', isEqualTo: userId)
            .orderBy('updatedAt', descending: true);
      }
      
      QuerySnapshot querySnapshot = await query.get();
      
      final conversations = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Conversation(
          id: data['id'] ?? doc.id,
          propertyId: data['propertyId'] ?? '',
          propertyTitle: data['propertyTitle'] ?? 'Property',
          buyerId: data['buyerId'] ?? '',
          buyerName: data['buyerName'] ?? 'Buyer',
          sellerId: data['sellerId'] ?? '',
          sellerName: data['sellerName'] ?? 'Seller',
          createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
          unreadCount: data['unreadCount'] ?? 0,
        );
      }).toList();
      
      // If userId was provided, also get conversations where user is the seller
      if (userId != null) {
        final sellerQuerySnapshot = await _firestore
            .collection('conversations')
            .where('sellerId', isEqualTo: userId)
            .orderBy('updatedAt', descending: true)
            .get();
            
        final sellerConversations = sellerQuerySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Conversation(
            id: data['id'] ?? doc.id,
            propertyId: data['propertyId'] ?? '',
            propertyTitle: data['propertyTitle'] ?? 'Property',
            buyerId: data['buyerId'] ?? '',
            buyerName: data['buyerName'] ?? 'Buyer',
            sellerId: data['sellerId'] ?? '',
            sellerName: data['sellerName'] ?? 'Seller',
            createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
            unreadCount: data['unreadCount'] ?? 0,
          );
        }).toList();
        
        // Combine and remove duplicates
        final allConversations = <String, Conversation>{};
        for (var conv in conversations) {
          allConversations[conv.id] = conv;
        }
        for (var conv in sellerConversations) {
          allConversations[conv.id] = conv;
        }
        
        // Sort by updatedAt descending
        final finalConversations = allConversations.values.toList();
        finalConversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        
        // Store in local cache
        _conversations.clear();
        _conversations.addAll(finalConversations);
        notifyListeners();

        if (kDebugMode) {
          debugPrint('✅ Loaded ${finalConversations.length} conversations from Firebase for user: $userId');
        }

        return finalConversations;
      }
      
      // No userId filter - return all (this shouldn't happen in normal usage)
      // Store in local cache
      _conversations.clear();
      _conversations.addAll(conversations);
      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Loaded ${conversations.length} conversations from Firebase');
      }

      return conversations;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching conversations from Firebase: $e');
      }
      
      // Return existing local conversations as fallback
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
      // If API call fails, fall back to Firebase Firestore
      if (kDebugMode) {
        debugPrint('! Messages API call failed, using Firebase: $e');
      }
      if (kDebugMode) {
        debugPrint('🔄 Falling back to Firebase message storage');
      }
      
      return await _fetchMessagesFromFirebase(conversationId);
    }
  }

  /// Fetch messages from Firebase Firestore
  Future<List<ChatMessage>> _fetchMessagesFromFirebase(String conversationId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Fetching messages from Firebase for conversation: $conversationId');
      }
      
      final querySnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      final messages = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatMessage(
          id: data['id'] ?? doc.id,
          conversationId: data['conversationId'] ?? conversationId,
          senderId: data['senderId'] ?? '',
          senderName: data['senderName'] ?? 'Unknown',
          senderAvatar: data['senderAvatar'],
          content: data['content'] ?? '',
          type: MessageType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => MessageType.text,
          ),
          status: MessageStatus.values.firstWhere(
            (e) => e.name == data['status'],
            orElse: () => MessageStatus.sent,
          ),
          timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
          readAt: data['readAt'] != null ? DateTime.tryParse(data['readAt']) : null,
        );
      }).toList();

      // Store in local cache
      _messages[conversationId] = messages;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Loaded ${messages.length} messages from Firebase');
      }

      return messages;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching messages from Firebase: $e');
      }
      
      // Return existing local messages as fallback
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
        // If API response is invalid, fall back to local sending
        if (kDebugMode) {
          debugPrint('⚠️ Invalid API response, falling back to local message sending');
        }
        return await _sendMessageLocally(message);
      }
    } catch (e) {
      // Fall back to local sending when API fails
      if (kDebugMode) {
        debugPrint('! Send message API call failed: $e');
      }
      if (kDebugMode) {
        debugPrint('🔄 Falling back to local message sending');
      }
      return await _sendMessageLocally(message);
    }
  }

  /// Send message locally when API fails
  Future<ChatMessage> _sendMessageLocally(ChatMessage message) async {
    if (kDebugMode) {
      debugPrint('🏠 Sending message locally');
    }
    
    try {
      // Ensure parent conversation document exists so queries on the
      // conversations collection return this thread. Without a parent
      // doc, Firestore shows a phantom path and queries won't include it.
      final convRef = _firestore.collection('conversations').doc(message.conversationId);
      final convSnap = await convRef.get();

      // Try to get participant and property info from local cache
      final cachedConversation = getConversation(message.conversationId);

      if (!convSnap.exists) {
        final nowIso = DateTime.now().toIso8601String();
        await convRef.set({
          'id': message.conversationId,
          'createdAt': nowIso,
          'updatedAt': nowIso,
          'unreadCount': 0,
          if (cachedConversation != null) ...{
            'propertyId': cachedConversation.propertyId,
            'propertyTitle': cachedConversation.propertyTitle,
            'buyerId': cachedConversation.buyerId,
            'buyerName': cachedConversation.buyerName,
            'sellerId': cachedConversation.sellerId,
            'sellerName': cachedConversation.sellerName,
          },
        });
        if (kDebugMode) {
          debugPrint('📝 Created missing conversation doc with metadata: ${message.conversationId}');
        }
      } else if (cachedConversation != null) {
        // Backfill missing participant fields if they don't exist (older docs)
        final data = convSnap.data() as Map<String, dynamic>? ?? {};
        final updates = <String, dynamic>{};
        if (!(data.containsKey('buyerId')) && cachedConversation.buyerId.isNotEmpty) {
          updates['buyerId'] = cachedConversation.buyerId;
          updates['buyerName'] = cachedConversation.buyerName;
        }
        if (!(data.containsKey('sellerId')) && cachedConversation.sellerId.isNotEmpty) {
          updates['sellerId'] = cachedConversation.sellerId;
          updates['sellerName'] = cachedConversation.sellerName;
        }
        if (!(data.containsKey('propertyId')) && cachedConversation.propertyId.isNotEmpty) {
          updates['propertyId'] = cachedConversation.propertyId;
        }
        if (!(data.containsKey('propertyTitle')) && (cachedConversation.propertyTitle?.isNotEmpty ?? false)) {
          updates['propertyTitle'] = cachedConversation.propertyTitle;
        }
        if (updates.isNotEmpty) {
          await convRef.update(updates);
        }
      }

      // Store message in Firebase Firestore
      await _firestore
          .collection('conversations')
          .doc(message.conversationId)
          .collection('messages')
          .doc(message.id)
          .set({
        'id': message.id,
        'conversationId': message.conversationId,
        'senderId': message.senderId,
        'senderName': message.senderName,
        'senderAvatar': message.senderAvatar,
        'content': message.content,
        'type': message.type.name,
        'status': message.status.name,
        'timestamp': message.timestamp.toIso8601String(),
        'readAt': message.readAt?.toIso8601String(),
      });

      // Update conversation metadata so list queries pick this up and show recents
      // Determine receiver to increment their unread counter only
      String receiverField = 'buyerUnreadCount';
      try {
        final conv = getConversation(message.conversationId);
        if (conv != null) {
          receiverField = (message.senderId == conv.buyerId) ? 'sellerUnreadCount' : 'buyerUnreadCount';
        }
      } catch (_) {}

      await convRef.update({
        'updatedAt': DateTime.now().toIso8601String(),
        'lastMessage': message.content,
        'lastMessageSenderId': message.senderId,
        receiverField: FieldValue.increment(1),
      });

      if (kDebugMode) {
        debugPrint('🔥 Message stored in Firebase: ${message.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error storing message in Firebase: $e');
      }
    }
    
    // Simulate sending delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Update message status to sent
    final sentMessage = message.copyWith(status: MessageStatus.sent);
    final index = _messages[message.conversationId]!.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      _messages[message.conversationId]![index] = sentMessage;
    }
    
    // Update conversation
    _updateLastMessages();
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('✅ Message sent locally: ${message.id}');
    }
    
    return sentMessage;
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
        debugPrint('! Mark messages as read API call failed: $e');
      }
      if (kDebugMode) {
        debugPrint('🔄 Continuing with local read status update');
      }
      // Local updates were already applied above, so we just continue
    }

    // Also update Firestore conversation doc counter directly (per user)
    try {
      final conv = getConversation(conversationId);
      if (conv != null && _currentUserId != null) {
        final field = (_currentUserId == conv.buyerId) ? 'buyerUnreadCount' : 'sellerUnreadCount';
        await _firestore.collection('conversations').doc(conversationId).update({
          field: 0,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  /// Create a new conversation
  Future<Conversation?> createConversation({
    required String propertyId,
    required String buyerId,
    required String sellerId,
    String? propertyTitle,
    String? sellerName,
    String? buyerName,
    String? token,
  }) async {
    // FIRST: Check if conversation already exists in Firebase
    if (kDebugMode) {
      debugPrint('🔍 Checking for existing conversation: propertyId=$propertyId, buyerId=$buyerId, sellerId=$sellerId');
    }
    
    try {
      final existingConversation = await _findExistingConversation(propertyId, buyerId, sellerId);
      if (existingConversation != null) {
        if (kDebugMode) {
          debugPrint('✅ Found existing conversation: ${existingConversation.id}');
        }
        return existingConversation;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking for existing conversation: $e');
      }
    }
    
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
        propertyTitle: propertyTitle ?? 'Property Title',
        buyerId: buyerId,
        buyerName: buyerName ?? 'Buyer Name',
        sellerId: sellerId,
        sellerName: sellerName ?? 'Seller Name',
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
      
      // If API response is invalid, fall back to local creation
      if (kDebugMode) {
        debugPrint('⚠️ Invalid API response, falling back to local conversation creation');
      }
      return await _createNewLocalConversation(propertyId, buyerId, sellerId, propertyTitle, sellerName, buyerName);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('! Create conversation API call failed: $e');
      }
      
      // Fall back to local conversation creation when API fails
      if (kDebugMode) {
        debugPrint('🔄 Falling back to local conversation creation');
      }
      return await _createNewLocalConversation(propertyId, buyerId, sellerId, propertyTitle, sellerName, buyerName);
    }
  }
  
  /// Find existing conversation in Firebase
  Future<Conversation?> _findExistingConversation(String propertyId, String buyerId, String sellerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('conversations')
          .where('propertyId', isEqualTo: propertyId)
          .get();
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final convBuyerId = data['buyerId'] ?? '';
        final convSellerId = data['sellerId'] ?? '';
        
        // Check if the buyer and seller match (in any order)
        if ((convBuyerId == buyerId && convSellerId == sellerId) ||
            (convBuyerId == sellerId && convSellerId == buyerId)) {
          final conversation = Conversation(
            id: doc.id,
            propertyId: data['propertyId'] ?? '',
            propertyTitle: data['propertyTitle'],
            buyerId: data['buyerId'] ?? '',
            buyerName: data['buyerName'],
            sellerId: data['sellerId'] ?? '',
            sellerName: data['sellerName'],
            propertyImage: data['propertyImage'],
            createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
          );
          
          // Add to local cache if not already present
          if (!_conversations.any((c) => c.id == conversation.id)) {
            _conversations.add(conversation);
            notifyListeners();
          }
          
          return conversation;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error finding existing conversation in Firebase: $e');
      }
      return null;
    }
  }

  /// Create a NEW conversation locally when API fails (no existing check)
  Future<Conversation> _createNewLocalConversation(
    String propertyId,
    String buyerId,
    String sellerId,
    String? propertyTitle,
    String? sellerName,
    String? buyerName,
  ) async {
    if (kDebugMode) {
      debugPrint('🏠 Creating NEW conversation locally');
    }
    
    // Use provided property and user information, or fall back to generic names
    final finalPropertyTitle = propertyTitle ?? 'Property #${propertyId.substring(0, 8)}...';
    final finalBuyerName = buyerName ?? 'User #${buyerId.substring(0, 8)}...';
    final finalSellerName = sellerName ?? 'User #${sellerId.substring(0, 8)}...';
    
    // Create new conversation
    final conversation = Conversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: propertyId,
      propertyTitle: finalPropertyTitle,
      buyerId: buyerId,
      buyerName: finalBuyerName,
      sellerId: sellerId,
      sellerName: finalSellerName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Store conversation in Firebase
    try {
      await _firestore.collection('conversations').doc(conversation.id).set({
        'id': conversation.id,
        'propertyId': conversation.propertyId,
        'propertyTitle': conversation.propertyTitle,
        'buyerId': conversation.buyerId,
        'buyerName': conversation.buyerName,
        'sellerId': conversation.sellerId,
        'sellerName': conversation.sellerName,
        'createdAt': conversation.createdAt.toIso8601String(),
        'updatedAt': conversation.updatedAt.toIso8601String(),
        'unreadCount': conversation.unreadCount,
      });
      
      if (kDebugMode) {
        debugPrint('🔥 Conversation stored in Firebase: ${conversation.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error storing conversation in Firebase: $e');
      }
    }
    
    _conversations.insert(0, conversation);
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('✅ Created local conversation: ${conversation.id}');
    }
    
    return conversation;
  }

  /// Set current conversation
  void setCurrentConversation(String? conversationId) {
    _currentConversationId = conversationId;
    notifyListeners();
  }

  /// Start listening for real-time messages
  void startListeningToMessages(String conversationId) {
    // Cancel existing subscription
    _messagesSubscription?.cancel();
    
    if (kDebugMode) {
      debugPrint('🔥 Starting real-time message listening for: $conversationId');
    }
    
    _messagesSubscription = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      final previous = List<ChatMessage>.from(_messages[conversationId] ?? const []);
      final messages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatMessage(
          id: data['id'] ?? doc.id,
          conversationId: data['conversationId'] ?? conversationId,
          senderId: data['senderId'] ?? '',
          senderName: data['senderName'] ?? 'Unknown',
          senderAvatar: data['senderAvatar'],
          content: data['content'] ?? '',
          type: MessageType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => MessageType.text,
          ),
          status: MessageStatus.values.firstWhere(
            (e) => e.name == data['status'],
            orElse: () => MessageStatus.sent,
          ),
          timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
          readAt: data['readAt'] != null ? DateTime.tryParse(data['readAt']) : null,
        );
      }).toList();

      // Update local cache
      _messages[conversationId] = messages;

      // If there are new incoming messages and the user is not viewing this conversation,
      // increment unread counters locally and in Firestore.
      final int delta = messages.length - previous.length;
      if (delta > 0 && messages.isNotEmpty) {
        final last = messages.last;
        final isIncoming = _currentUserId != null && last.senderId != _currentUserId;
        final isViewing = _currentConversationId == conversationId;
        if (isIncoming && !isViewing) {
          final idx = _conversations.indexWhere((c) => c.id == conversationId);
          if (idx != -1) {
            final updated = _conversations[idx].copyWith(
              unreadCount: _conversations[idx].unreadCount + delta,
              lastMessage: last,
              updatedAt: last.timestamp,
            );
            _conversations[idx] = updated;
          }
          // Persist unread increment on the conversation doc
          _firestore.collection('conversations').doc(conversationId).update({
            'unreadCount': FieldValue.increment(delta),
            'updatedAt': last.timestamp.toIso8601String(),
            'lastMessage': last.content,
          }).catchError((_) {});
        }
      }
      notifyListeners();

      if (kDebugMode) {
        debugPrint('📨 Real-time update: ${messages.length} messages for $conversationId');
      }
    }, onError: (error) {
      if (kDebugMode) {
        debugPrint('❌ Error in real-time message listening: $error');
      }
    });
  }

  /// Stop listening for real-time messages
  void stopListeningToMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    if (kDebugMode) {
      debugPrint('🛑 Stopped real-time message listening');
    }
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

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    if (kDebugMode) {
      debugPrint('🗑️ Deleting conversation: $conversationId');
    }
    
    try {
      // Delete from Firebase
      await _firestore.collection('conversations').doc(conversationId).delete();
      
      if (kDebugMode) {
        debugPrint('✅ Conversation deleted from Firebase: $conversationId');
      }
      
      // Remove from local cache
      _conversations.removeWhere((c) => c.id == conversationId);
      
      // Clear messages from local cache
      _messages.remove(conversationId);
      
      // Stop listening to messages if active
      if (_messagesSubscription != null) {
        await _messagesSubscription?.cancel();
        _messagesSubscription = null;
      }
      
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✅ Conversation removed from local cache: $conversationId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting conversation: $e');
      }
      rethrow;
    }
  }
}
