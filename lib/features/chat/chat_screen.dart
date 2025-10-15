import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/login_required_screen.dart';
import 'chat_models.dart';
import 'chat_service.dart';
import 'chat_widgets.dart';

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
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
          title: Text(l10n?.chat ?? 'Chat'),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
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
          title: Text(l10n?.chat ?? 'Chat'),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
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
                style: TextStyle(
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
          onPressed: () => Navigator.of(context).pop(),
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
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n?.startConversation ?? 'Start the conversation!',
                          style: TextStyle(
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
                    
                    return MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      showAvatar: index == 0 || 
                          messages[index - 1].senderId != message.senderId,
                    );
                  },
                );
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
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
