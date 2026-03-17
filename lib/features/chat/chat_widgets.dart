import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'chat_models.dart';
import '../../services/theme_service.dart';
import '../../widgets/dary_loading_indicator.dart';

/// Message bubble widget for displaying chat messages
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool showAvatar;
  final bool showStatus; // only show status for the latest outgoing message

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.showAvatar = true,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: message.senderAvatar != null && message.senderAvatar!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        message.senderAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            message.senderName.isNotEmpty 
                                ? message.senderName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            width: 32,
                            height: 32,
                            child: Center(
                              child: DaryLoadingIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      message.senderName.isNotEmpty 
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? const LinearGradient(
                        colors: [Color(0xFF5B6BEE), Color(0xFF4853D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isCurrentUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser && showAvatar)
                    Text(
                      message.senderName,
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (!isCurrentUser && showAvatar)
                    const SizedBox(height: 4),
                  
                  Text(
                    message.content,
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 16,
                      color: isCurrentUser
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(context, message.timestamp),
                        style: ThemeService.getDynamicStyle(
                          context,
                          fontSize: 12,
                          color: isCurrentUser
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                      ),
                      if (isCurrentUser && showStatus) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isCurrentUser && showAvatar) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: message.senderAvatar != null && message.senderAvatar!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        message.senderAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            message.senderName.isNotEmpty 
                                ? message.senderName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            width: 32,
                            height: 32,
                            child: Center(
                              child: DaryLoadingIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      message.senderName.isNotEmpty 
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: DaryLoadingIndicator(
            strokeWidth: 1.5,
            color: Colors.white70,
            size: 12,
          ),
        );
      case MessageStatus.sent:
        return const Icon(
          Icons.check,
          size: 12,
          color: Colors.white70,
        );
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.white70,
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.blue,
        );
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 12,
          color: Colors.red,
        );
    }
  }

  String _formatTime(BuildContext context, DateTime timestamp) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Conversation list item widget
class ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final String? currentUserId;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Determine the other participant
    final otherParticipant = currentUserId == conversation.buyerId
        ? ChatParticipant(
            id: conversation.sellerId,
            name: conversation.sellerName,
            avatar: conversation.sellerAvatar,
          )
        : ChatParticipant(
            id: conversation.buyerId,
            name: conversation.buyerName,
            avatar: conversation.buyerAvatar,
          );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: conversation.unreadCount > 0 
            ? LinearGradient(
                colors: [
                  const Color(0xFF01352D).withValues(alpha: 0.03),
                  const Color(0xFF015F4D).withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: conversation.unreadCount > 0 ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: conversation.unreadCount > 0
            ? Border.all(
                color: const Color(0xFF01352D).withValues(alpha: 0.1),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: conversation.unreadCount > 0
                ? const Color(0xFF01352D).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: conversation.unreadCount > 0 ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Property info row (if available)
                if (conversation.propertyTitle.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey[50]!,
                          Colors.grey[100]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Property image
                        Hero(
                          tag: 'property_${conversation.propertyId}',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: conversation.propertyImage != null
                                  ? Image.network(
                                      conversation.propertyImage!,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.grey[300]!, Colors.grey[400]!],
                                          ),
                                        ),
                                        child: Icon(Icons.home_rounded, color: Colors.grey[600], size: 26),
                                      ),
                                    )
                                  : Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.grey[300]!, Colors.grey[400]!],
                                        ),
                                      ),
                                      child: Icon(Icons.home_rounded, color: Colors.grey[600], size: 26),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF01352D).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.home_rounded,
                                          size: 12,
                                          color: Color(0xFF01352D),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n?.property ?? 'Property',
                                          style: ThemeService.getDynamicStyle(
                                            context,
                                            fontSize: 10,
                                            color: const Color(0xFF01352D),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                conversation.propertyTitle,
                                style: ThemeService.getDynamicStyle(
                                  context,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.3,
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
                
                // Chat info row
                Row(
                  children: [
                    // Avatar with online indicator
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF01352D).withValues(alpha: 0.1),
                                const Color(0xFF015F4D).withValues(alpha: 0.05),
                              ],
                            ),
                            border: Border.all(
                              color: conversation.unreadCount > 0
                                  ? const Color(0xFF01352D).withValues(alpha: 0.2)
                                  : Colors.grey[200]!,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF01352D).withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF01352D).withValues(alpha: 0.08),
                            backgroundImage: otherParticipant.avatar != null && otherParticipant.avatar!.isNotEmpty
                                ? NetworkImage(otherParticipant.avatar!)
                                : null,
                            child: otherParticipant.avatar == null || otherParticipant.avatar!.isEmpty
                                ? Text(
                                    otherParticipant.name.isNotEmpty 
                                        ? otherParticipant.name[0].toUpperCase()
                                        : '?',
                                    style: ThemeService.getDynamicStyle(
                                      context,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF01352D),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        // Online indicator
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green[400],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    
                    // Name and message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  otherParticipant.name,
                                  style: ThemeService.getDynamicStyle(
                                    context,
                                    fontSize: 16,
                                    fontWeight: conversation.unreadCount > 0 
                                        ? FontWeight.w700 
                                        : FontWeight.w600,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: conversation.unreadCount > 0
                                      ? const Color(0xFF01352D).withValues(alpha: 0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                    _formatTime(context, conversation.updatedAt),
                                  style: ThemeService.getDynamicStyle(
                                    context,
                                    fontSize: 11,
                                    color: conversation.unreadCount > 0 
                                        ? const Color(0xFF01352D)
                                        : Colors.grey[600],
                                    fontWeight: conversation.unreadCount > 0 
                                        ? FontWeight.w600 
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conversation.lastMessage?.content ?? (l10n?.noMessagesYet ?? 'No messages yet'),
                                  style: ThemeService.getDynamicStyle(
                                    context,
                                    fontSize: 14,
                                    color: conversation.unreadCount > 0 
                                        ? Colors.black87 
                                        : Colors.grey[600],
                                    fontWeight: conversation.unreadCount > 0 
                                        ? FontWeight.w500 
                                        : FontWeight.normal,
                                    height: 1.4,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (conversation.unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF01352D), Color(0xFF025D4F)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF01352D).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    conversation.unreadCount > 99 
                                        ? '99+' 
                                        : conversation.unreadCount.toString(),
                                    style: ThemeService.getDynamicStyle(
                                      context,
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime timestamp) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inDays > 0) {
      return l10n?.timeAgoDays(difference.inDays) ?? '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return l10n?.timeAgoHours(difference.inHours) ?? '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return l10n?.timeAgoMinutes(difference.inMinutes) ?? '${difference.inMinutes}m';
    } else {
      return l10n?.now ?? 'now';
    }
  }
}

/// Empty state widget for conversation list
class EmptyConversationList extends StatefulWidget {
  const EmptyConversationList({super.key});

  @override
  State<EmptyConversationList> createState() => _EmptyConversationListState();
}

class _EmptyConversationListState extends State<EmptyConversationList> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Icon Container
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF01352D).withValues(alpha: 0.1),
                        const Color(0xFF015F4D).withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF01352D).withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF01352D),
                          Color(0xFF025D4F),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                
                // Title
                Text(
                  l10n?.noConversationsYet ?? 'No conversations yet',
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Description
                Text(
                  l10n?.startConversationWithSeller ?? 'Start a conversation with a seller to discuss properties!',
                  textAlign: TextAlign.center,
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                
                // CTA Button
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF01352D), Color(0xFF025D4F)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF01352D).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).pushNamed('/');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.home_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              l10n?.browseProperties ?? 'Browse Properties',
                              style: ThemeService.getDynamicStyle(
                                context,
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Additional tips
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildTipItem(
                        context,
                        icon: Icons.search_rounded,
                        text: l10n?.tipsFindProperty ?? 'Find your dream property',
                      ),
                      const SizedBox(height: 12),
                      _buildTipItem(
                        context,
                        icon: Icons.message_rounded,
                        text: l10n?.tipsContactSeller ?? 'Contact the seller directly',
                      ),
                      const SizedBox(height: 12),
                      _buildTipItem(
                        context,
                        icon: Icons.handshake_rounded,
                        text: l10n?.tipsNegotiateDeal ?? 'Negotiate and close the deal',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, {required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF01352D).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF01352D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
