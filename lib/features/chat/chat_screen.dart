import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../providers/auth_provider.dart';
import '../../services/property_service.dart' as property_service;
import '../../screens/property_detail_screen.dart';
import 'chat_models.dart';
import 'chat_service.dart';
import '../../services/theme_service.dart';
import '../../utils/text_input_formatters.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_upload_service.dart';
import 'package:flutter/services.dart'; // For Clipboard
import '../../widgets/dary_loading_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String? propertyTitle;
  final String? propertyImage;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.propertyTitle,
    this.propertyImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  Conversation? _conversation;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _propertyImage;
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _loadMessages();
    
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final show = _scrollController.offset < _scrollController.position.maxScrollExtent - 300;
        if (show != _showScrollButton) {
          setState(() => _showScrollButton = show);
        }
      }
    });

    _chatService.startListeningToMessages(widget.conversationId);
    _chatService.setCurrentConversation(widget.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Stop listening for real-time messages
    _chatService.stopListeningToMessages();
    _chatService.setCurrentConversation(null);
    super.dispose();
  }

  Future<void> _loadConversation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _conversation = _chatService.getConversation(widget.conversationId);
      if (_conversation != null) {
        // Mark messages as read after the build phase
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _chatService.markMessagesAsRead(widget.conversationId);
        });
        
        // If property image is missing, try to fetch it from the property
        if (_conversation!.propertyImage == null && _conversation!.propertyId.isNotEmpty) {
          _fetchPropertyImage(_conversation!.propertyId);
        } else {
          _propertyImage = _conversation!.propertyImage;
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _fetchPropertyImage(String propertyId) async {
    try {
      final propertyService = property_service.PropertyService();
      final property = await propertyService.getPropertyById(propertyId);
      if (mounted && property != null && property.imageUrls.isNotEmpty) {
        setState(() {
          _propertyImage = property.imageUrls.first;
        });
      }
    } catch (e) {
      // Silently fail - property image is not critical
    }
  }

  Future<void> _navigateToProperty(String propertyId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: DaryLoadingIndicator(color: Colors.white),
        ),
      );

      final propertyService = property_service.PropertyService();
      final property = await propertyService.getPropertyById(propertyId);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted && property != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PropertyDetailScreen(property: property),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.propertyNotFound ?? 'Property not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.errorLoadingProperty(e.toString()) ?? 'Error loading property: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.fetchMessages(widget.conversationId);
      setState(() {
        _messages = messages;
      });
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.errorLoadingMessages ?? 'Error loading messages'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final message = await _chatService.sendMessage(
        conversationId: widget.conversationId,
        content: content,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderAvatar: currentUser.profileImageUrl,
      );

      if (message != null) {
        _messageController.clear();
        setState(() {
          _messages = _chatService.getMessages(widget.conversationId);
        });

        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.errorSendingMessage ?? 'Error sending message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDayLabel(DateTime dt, AppLocalizations? l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return l10n?.today ?? 'Today';
    if (date == today.subtract(const Duration(days: 1))) return l10n?.yesterday ?? 'Yesterday';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        await _uploadAndSendImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadAndSendImage(XFile image) async {
    setState(() => _isSending = true);
    
    try {
      final imageUrl = await ImageUploadService.uploadChatImage(image, widget.conversationId);
      
      if (imageUrl != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        
        if (currentUser != null) {
          await _chatService.sendMessage(
            conversationId: widget.conversationId,
            content: imageUrl,
            senderId: currentUser.id,
            senderName: currentUser.name,
            senderAvatar: currentUser.profileImageUrl,
            type: MessageType.image,
          );
          
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy Text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            // Add more options here if needed
          ],
        ),
      ),
    );
  }

  Widget _buildModernMessageBubble(ChatMessage message, bool isCurrentUser, bool showAvatar, bool showStatus) {
    print('Building bubble for: ${message.content}, Type: ${message.type}');
    return Padding(
      // Use EdgeInsetsDirectional to handle RTL correctly
      padding: EdgeInsetsDirectional.only(
        top: showAvatar ? 12 : 2,
        bottom: 2,
        start: isCurrentUser ? 64 : 0,
        end: isCurrentUser ? 0 : 64,
      ),
      child: Row(
        // Use standard MainAxisAlignment.end for 'me' which works correctly with Directionality
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other user (Start side)
          if (!isCurrentUser) ...[
            if (showAvatar)
              Container(
                margin: const EdgeInsetsDirectional.only(end: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: message.senderAvatar != null 
                      ? NetworkImage(message.senderAvatar!) 
                      : null,
                  child: message.senderAvatar == null
                      ? Text(
                          message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        )
                      : null,
                ),
              )
            else
              const SizedBox(width: 40), // 32 (2*radius) + 8 (margin)
          ],
          
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              onTap: message.type == MessageType.image ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageScreen(imageUrl: message.content, messageId: message.id),
                  ),
                );
              } : null,
              child: Container(
                padding: message.type == MessageType.image 
                    ? const EdgeInsets.all(4) 
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  // Use a lighter green for sent messages to be more like WhatsApp/others
                  color: isCurrentUser 
                      ? const Color(0xFFE0F2F1) // Very light teal/green
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                    bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (message.type == MessageType.image)
                      Hero(
                        tag: message.id, // Use unique tag for Hero animation
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            message.content,
                            width: 200,
                            height: 200, // Fixed height for now, or use fit
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: DaryLoadingIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      )
                    else
                      Text(
                        message.content,
                        style: ThemeService.getDynamicStyle(
                          context,
                          fontSize: 15,
                          // Dark text for better readability on light background
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    
                    if (message.type != MessageType.image) const SizedBox(height: 4),
                    
                    Padding(
                      padding: message.type == MessageType.image 
                          ? const EdgeInsets.only(top: 4, right: 4) 
                          : EdgeInsets.zero,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: ThemeService.getDynamicStyle(
                              context,
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (isCurrentUser && showStatus) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.status == MessageStatus.read 
                                  ? Icons.done_all_rounded
                                  : message.status == MessageStatus.delivered 
                                      ? Icons.done_all_rounded
                                      : Icons.done_rounded,
                              size: 14,
                              color: message.status == MessageStatus.read 
                                  ? Colors.blue
                                  : Colors.grey[500],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    final currentUser = authProvider.currentUser;

    if (_isLoading || _conversation == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
        ),
        body: Center(
          child: _isLoading 
            ? const DaryLoadingIndicator(color: Color(0xFF01352D))
            : Text(l10n?.conversationNotFound ?? 'Conversation not found'),
        ),
      );
    }

    final otherParticipant = currentUser?.id == _conversation!.buyerId
        ? ChatParticipant(
            id: _conversation!.sellerId,
            name: _conversation!.sellerName,
            avatar: _conversation!.sellerAvatar,
          )
        : ChatParticipant(
            id: _conversation!.buyerId,
            name: _conversation!.buyerName,
            avatar: _conversation!.buyerAvatar,
          );

    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // WhatsApp-like background color
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF01352D)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: otherParticipant.avatar != null 
                  ? NetworkImage(otherParticipant.avatar!) 
                  : null,
              child: otherParticipant.avatar == null 
                  ? Text(
                      otherParticipant.name.isNotEmpty ? otherParticipant.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Color(0xFF01352D), fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherParticipant.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l10n?.online ?? 'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LanguageToggleButton(languageService: languageService),
            ),
        ],
      ),
      floatingActionButton: _showScrollButton 
          ? FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF01352D),
              onPressed: _scrollToBottom,
              child: const Icon(Icons.arrow_downward),
            )
          : null,
      body: Column(
        children: [
          // Streamlined Property Header
          if (_conversation!.propertyTitle.isNotEmpty)
            InkWell(
              onTap: () => _navigateToProperty(_conversation!.propertyId),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: (_propertyImage ?? _conversation!.propertyImage ?? widget.propertyImage) != null
                          ? Image.network(
                              _propertyImage ?? _conversation!.propertyImage ?? widget.propertyImage!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[200],
                              child: const Icon(Icons.home_rounded, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.property ?? 'Property',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _conversation!.propertyTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),

          // Messages list
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, child) {
                final messages = chatService.getMessages(widget.conversationId);
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                            child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.noMessagesYet ?? 'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == currentUser?.id;
                    final isLastFromCurrentUser = isCurrentUser && index == messages.length - 1;
                    final showAvatar = index == 0 || messages[index - 1].senderId != message.senderId;

                    // Message Bubble
                    Widget bubble = _buildModernMessageBubble(message, isCurrentUser, showAvatar, isLastFromCurrentUser);

                    // Date Header
                    if (index == 0 || !_isSameDay(messages[index - 1].timestamp, message.timestamp)) {
                      final dateLabel = _formatDayLabel(message.timestamp, l10n);
                      bubble = Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              dateLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          bubble,
                        ],
                      );
                    }

                    return bubble;
                  },
                );
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF01352D)),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 15),
                        inputFormatters: [BasicTextFormatter()],
                        decoration: InputDecoration(
                          hintText: l10n?.typeMessage ?? 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF01352D),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: DaryLoadingIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                                size: 20,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageScreen extends StatelessWidget {
  final String imageUrl;
  final String? messageId;

  const FullScreenImageScreen({
    super.key, 
    required this.imageUrl,
    this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: messageId ?? imageUrl,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: DaryLoadingIndicator(color: Colors.white));
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 48));
              },
            ),
          ),
        ),
      ),
    );
  }
}
