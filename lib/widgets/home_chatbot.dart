import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chatbot_service.dart';
import '../services/language_service.dart';
import '../models/property.dart';
import '../screens/property_detail_screen.dart';
import '../utils/text_input_formatters.dart';
import 'dary_loading_indicator.dart';

/// Floating chatbot widget for homepage
class HomeChatbot extends StatefulWidget {
  const HomeChatbot({super.key});

  @override
  State<HomeChatbot> createState() => _HomeChatbotState();
}

class _HomeChatbotState extends State<HomeChatbot> with SingleTickerProviderStateMixin {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isOpen = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    // Get initial greeting based on language
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final isArabic = languageService.isArabic;
    _messages.add(ChatMessage(
      text: _chatbotService.getGreeting(isArabic: isArabic),
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _chatbotService.sendMessage(message);
      
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response.text,
            isUser: false,
            timestamp: DateTime.now(),
            properties: response.properties,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Sorry, I encountered an error. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Chat window
          if (_isOpen)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 350,
                height: 500,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF01352D), const Color(0xFF01352D).withValues(alpha: 0.85)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.smart_toy,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dary Assistant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Always here to help',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: _toggleChat,
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),
                    // Messages
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isLoading) {
                            return _buildLoadingIndicator();
                          }
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
                    ),
                    // Input
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              inputFormatters: [BasicTextFormatter()],
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF01352D),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF01352D).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _isLoading ? null : _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Floating button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF01352D), const Color(0xFF01352D).withValues(alpha: 0.85)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF01352D).withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _toggleChat,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(
                  Icons.chat_bubble,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF01352D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Color(0xFF01352D),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF01352D)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 20),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF01352D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF01352D),
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
          // Display property cards if found
          if (!message.isUser && message.properties != null && message.properties!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 200, // Fixed height for horizontal scroll
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.properties!.length,
                itemBuilder: (context, index) {
                  final property = message.properties![index];
                  return Container(
                    width: 280,
                    margin: EdgeInsets.only(
                      right: index < message.properties!.length - 1 ? 12 : 0,
                    ),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Navigate to property details using Navigator (same as property_card.dart)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyDetailScreen(property: property),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Property image
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: property.imageUrls.isNotEmpty
                                  ? Image.network(
                                      property.imageUrls.first,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 120,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image, size: 40),
                                        );
                                      },
                                    )
                                  : Container(
                                      height: 120,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 40),
                                    ),
                            ),
                            // Property details
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    property.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    property.displayPrice,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${property.city}${property.neighborhood.isNotEmpty ? ', ${property.neighborhood}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.smart_toy,
              color: Colors.green[700],
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: DaryLoadingIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF15803D), // green[700]
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Property>? properties; // Optional property results

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.properties,
  });
}

