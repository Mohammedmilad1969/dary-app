import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'chat_models.dart';

/// Message bubble widget for displaying chat messages
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.showAvatar = true,
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
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              backgroundColor: Colors.grey[300],
              child: message.senderAvatar == null
                  ? Text(
                      message.senderName.isNotEmpty 
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
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
                color: isCurrentUser 
                    ? Colors.indigo 
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser && showAvatar)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (!isCurrentUser && showAvatar)
                    const SizedBox(height: 4),
                  
                  Text(
                    message.content,
                    style: TextStyle(
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
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: isCurrentUser 
                              ? Colors.white70 
                              : Colors.grey[600],
                        ),
                      ),
                      if (isCurrentUser) ...[
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
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              backgroundColor: Colors.grey[300],
              child: message.senderAvatar == null
                  ? Text(
                      message.senderName.isNotEmpty 
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
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
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white70,
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

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
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

    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: otherParticipant.avatar != null
                ? NetworkImage(otherParticipant.avatar!)
                : null,
            backgroundColor: Colors.grey[300],
            child: otherParticipant.avatar == null
                ? Text(
                    otherParticipant.name.isNotEmpty 
                        ? otherParticipant.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          if (conversation.unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  conversation.unreadCount > 99 
                      ? '99+' 
                      : conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        otherParticipant.name,
        style: TextStyle(
          fontWeight: conversation.unreadCount > 0 
              ? FontWeight.bold 
              : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conversation.propertyTitle != null)
            Text(
              conversation.propertyTitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          if (conversation.lastMessage != null)
            Text(
              conversation.lastMessage!.content,
              style: TextStyle(
                fontSize: 14,
                color: conversation.unreadCount > 0 
                    ? Colors.black87 
                    : Colors.grey[600],
                fontWeight: conversation.unreadCount > 0 
                    ? FontWeight.w500 
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.updatedAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: conversation.unreadCount > 0 
                  ? FontWeight.bold 
                  : FontWeight.normal,
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

/// Empty state widget for conversation list
class EmptyConversationList extends StatelessWidget {
  const EmptyConversationList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.noConversationsYet ?? 'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.startConversationWithSeller ?? 'Start a conversation with a seller to discuss properties!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to properties list
                Navigator.of(context).pushNamed('/');
              },
              icon: const Icon(Icons.home),
              label: Text(l10n?.browseProperties ?? 'Browse Properties'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
