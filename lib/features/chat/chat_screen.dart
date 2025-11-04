import 'package:flutter/material.dart';
import 'package:dary/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/login_required_screen.dart';
import 'chat_models.dart';
import 'chat_service.dart';
import 'chat_widgets.dart';
import '../../services/theme_service.dart';
import '../../utils/text_input_formatters.dart';

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

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _loadMessages();
    // Start listening for real-time messages
    _chatService.startListeningToMessages(widget.conversationId);
    // Mark this conversation as current to suppress unread increments
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
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  String _formatDayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Check authentication
    if (!authProvider.isAuthenticated) {
      return LoginRequiredScreen(
        featureName: l10n?.chat ?? 'Chat',
        description: 'Please login to access chat and communicate with sellers',
      );
    }

    final currentUser = authProvider.currentUser;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            l10n?.chat ?? 'Chat',
            style: ThemeService.getHeadingStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
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
          actions: [
            LanguageToggleButton(languageService: languageService),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_conversation == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            l10n?.chat ?? 'Chat',
            style: ThemeService.getHeadingStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
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
          actions: [
            LanguageToggleButton(languageService: languageService),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.conversationNotFound ?? 'Conversation not found',
                style: ThemeService.getBodyStyle(
                  context,
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Determine the other participant
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherParticipant.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_conversation!.propertyTitle != null)
              Text(
                _conversation!.propertyTitle!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
        actions: [
          if (_conversation!.propertyImage != null)
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(_conversation!.propertyImage!),
              backgroundColor: Colors.white,
            ),
          const SizedBox(width: 8),
          LanguageToggleButton(languageService: languageService),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
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
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.noMessagesYet ?? 'No messages yet',
                          style: ThemeService.getBodyStyle(
                            context,
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n?.startConversation ?? 'Start the conversation!',
                          style: ThemeService.getBodyStyle(
                            context,
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == currentUser?.id;
                    final isLastFromCurrentUser = isCurrentUser && index == messages.length - 1;
                    final showAvatar = index == 0 || messages[index - 1].senderId != message.senderId;

                    // Insert a date divider when the day changes
                    Widget bubble = MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      showAvatar: showAvatar,
                      showStatus: isLastFromCurrentUser,
                    );

                    if (index == 0 || !_isSameDay(messages[index - 1].timestamp, message.timestamp)) {
                      final dateLabel = _formatDayLabel(message.timestamp);
                      bubble = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                dateLabel,
                                style: ThemeService.getBodyStyle(
                                  context,
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
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
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.black),
                    inputFormatters: [BasicTextFormatter()],
                    decoration: InputDecoration(
                      hintText: l10n?.typeMessage ?? 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600]),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
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
