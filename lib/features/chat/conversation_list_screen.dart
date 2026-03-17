import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../providers/auth_provider.dart';
import 'chat_models.dart';
import 'chat_service.dart';
import 'chat_widgets.dart';
import 'chat_screen.dart';
import '../../services/theme_service.dart';
import '../../widgets/dary_loading_indicator.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadConversations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)?.errorLoadingConversations ?? 'Error loading conversations'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
          conversationId: conversation.id,
          propertyTitle: conversation.propertyTitle,
          propertyImage: conversation.propertyImage,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    ).then((_) {
      _loadConversations();
    });
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      await _chatService.deleteConversation(conversationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)?.conversationDeleted ?? 'Conversation deleted'),
              ],
            ),
            backgroundColor: const Color(0xFF01352D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadConversations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)?.errorDeletingConversation(e.toString()) ?? 'Error deleting conversation: $e'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _testNotification() {
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

    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    final currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF01352D),
                    Color(0xFF024035),
                    Color(0xFF015F4D),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n?.messages ?? 'Messages',
                                      style: ThemeService.getDynamicStyle(
                                        context,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Consumer<ChatService>(
                                      builder: (context, chatService, child) {
                                        final totalUnreadCount = chatService.getTotalUnreadCount();
                                        return Text(
                                          totalUnreadCount > 0
                                              ? '$totalUnreadCount unread ${totalUnreadCount == 1 ? 'message' : 'messages'}'
                                              : l10n?.allCaughtUp ?? 'All caught up!',
                                          style: ThemeService.getDynamicStyle(
                                            context,
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.8),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              LanguageToggleButton(languageService: languageService),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Consumer<ChatService>(
            builder: (context, chatService, child) {
              final conversations = chatService.conversations;

              if (_isLoading) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF01352D).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const DaryLoadingIndicator(
                            color: Color(0xFF01352D),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n?.loading ?? 'Loading conversations...',
                          style: ThemeService.getBodyStyle(
                            context,
                            color: Colors.grey[600],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (conversations.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyConversationList(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(top: 16, bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final conversation = conversations[index];
                      return FadeTransition(
                        opacity: _animationController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              index * 0.1,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          )),
                          child: Dismissible(
                            key: Key(conversation.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red.shade400, Colors.red.shade600],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(
                                    Icons.delete_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n?.delete ?? 'Delete',
                                    style: ThemeService.getDynamicStyle(
                                      context,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.delete_rounded,
                                            color: Colors.red,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          l10n?.deleteConversation ?? 'Delete Conversation',
                                          style: ThemeService.getDynamicStyle(
                                            context,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      l10n?.deleteConversationConfirmation ?? 'Are you sure you want to delete this conversation? This action cannot be undone.',
                                      style: ThemeService.getDynamicStyle(
                                        context,
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        height: 1.5,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text(
                                          l10n?.cancel ?? 'Cancel',
                                          style: ThemeService.getBodyStyle(
                                            context,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                        ),
                                        child: Text(
                                          l10n?.delete ?? 'Delete',
                                          style: ThemeService.getDynamicStyle(
                                            context,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
                          ),
                        ),
                      );
                    },
                    childCount: conversations.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
