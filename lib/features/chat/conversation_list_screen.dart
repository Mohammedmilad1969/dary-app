import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dary/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/login_required_screen.dart';
import 'chat_models.dart';
import 'chat_service.dart';
import 'chat_widgets.dart';
import 'chat_screen.dart';
import '../../services/theme_service.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final ChatService _chatService = ChatService();
  List<Conversation> _conversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final conversations = await _chatService.fetchConversations(
        userId: currentUser?.id,
      );
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.errorLoadingConversations ?? 'Error loading conversations'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToChat(Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversation.id,
          propertyTitle: conversation.propertyTitle,
          propertyImage: conversation.propertyImage,
        ),
      ),
    ).then((_) {
      // Refresh conversations when returning from chat
      _loadConversations();
    });
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      await _chatService.deleteConversation(conversationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _loadConversations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testNotification() {
    // Simulate an incoming message for testing
    if (_conversations.isNotEmpty) {
      final conversation = _conversations.first;
      _chatService.simulateIncomingMessage(
        conversationId: conversation.id,
        senderId: 'test_sender',
        senderName: 'Test User',
        content: 'This is a test message to demonstrate notifications!',
        context: context,
      );
    } else {
      // Simulate a new conversation if none exist
      _chatService.simulateNewConversation(
        propertyId: 'test_property',
        propertyTitle: 'Test Property',
        buyerId: 'test_buyer',
        buyerName: 'Test Buyer',
        sellerId: 'test_seller',
        sellerName: 'Test Seller',
        context: context,
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
        featureName: l10n?.messages ?? 'Messages',
        description: 'Please login to access your messages and chat with sellers',
      );
    }

    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.messages ?? 'Messages',
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
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          LanguageToggleButton(languageService: languageService),
        ],
      ),
      body: Consumer<ChatService>(
        builder: (context, chatService, child) {
          final conversations = chatService.conversations;
          final totalUnreadCount = chatService.getTotalUnreadCount();

          // Update app bar title with unread count
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final appBar = context.findAncestorWidgetOfExactType<AppBar>();
              if (appBar != null) {
                // This would require a more complex state management approach
                // For now, we'll keep it simple
              }
            }
          });

          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (conversations.isEmpty) {
            return const EmptyConversationList();
          }

          return RefreshIndicator(
            onRefresh: _loadConversations,
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return Dismissible(
                  key: Key(conversation.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete Conversation'),
                          content: const Text('Are you sure you want to delete this conversation?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    _deleteConversation(conversation.id);
                  },
                  child: ConversationListItem(
                    conversation: conversation,
                    currentUserId: currentUser?.id,
                    onTap: () => _navigateToChat(conversation),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to properties to start a new conversation
          Navigator.of(context).pushNamed('/');
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      persistentFooterButtons: [
        // Test notification button (only in debug mode)
        if (kDebugMode)
          ElevatedButton.icon(
            onPressed: () => _testNotification(),
            icon: const Icon(Icons.notifications),
            label: const Text('Test Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}
