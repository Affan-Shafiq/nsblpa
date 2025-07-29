import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../services/conversation_service.dart';
import '../../services/auth_service.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Conversation? _selectedConversation;
  bool _hasAttemptedLoad = false; // Track if we've attempted to load conversations

  @override
  void initState() {
    super.initState();
    // Don't manually load conversations - let the Consumer handle it
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getOtherParticipantName(_selectedConversation, Provider.of<AuthService>(context, listen: false).user?.uid ?? '') ?? 'Messages'),
        leading: _selectedConversation != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedConversation = null;
                  });
                },
              )
            : null,
        actions: [
          if (_selectedConversation == null)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Implement search
              },
            ),
          if (_selectedConversation == null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showNewConversationDialog();
              },
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // On mobile, show either conversations or chat, not both
          if (constraints.maxWidth < 600) {
            return _selectedConversation == null
                ? _buildConversationsList()
                : _buildChatArea(_selectedConversation!);
          }
          
          // On larger screens, show split view
          return Row(
            children: [
              // Conversations list (1/3 width)
              SizedBox(
                width: constraints.maxWidth * 0.4,
                child: _buildConversationsList(),
              ),
              // Chat area (2/3 width)
              Expanded(
                child: _selectedConversation != null
                    ? _buildChatArea(_selectedConversation!)
                    : _buildEmptyChatArea(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConversationsList() {
    return Consumer<ConversationService>(
      builder: (context, conversationService, child) {
        // Trigger loading only once if not already loading and no conversations loaded
        if (!_hasAttemptedLoad && !conversationService.isLoading && conversationService.conversations.isEmpty && conversationService.error == null) {
          _hasAttemptedLoad = true;
          // Use post frame callback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            conversationService.getConversations();
          });
        }

        if (conversationService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle error state (e.g., missing index)
        if (conversationService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading conversations',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  conversationService.error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.subtitle,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (conversationService.error!.contains('index'))
                  Text(
                    'This might be due to a missing Firestore index. Please check the FIRESTORE_INDEXES.md file.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Use post frame callback to avoid setState during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _hasAttemptedLoad = false; // Reset flag to allow retry
                      conversationService.resetLoadingState();
                      conversationService.getConversations();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          );
        }

        if (conversationService.conversations.isEmpty) {
          return Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.subtitle),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 8),
                      Text(
                  'Start a conversation to begin messaging',
                        style: TextStyle(
                    fontSize: 14,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showNewConversationDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('New Conversation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
          );
        }

        return ListView.builder(
          itemCount: conversationService.conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversationService.conversations[index];
            final currentUserId = Provider.of<AuthService>(context, listen: false).user?.uid ?? '';
            final isSelected = _selectedConversation?.id == conversation.id;
            final unreadCount = _getUnreadCountForUser(conversation, currentUserId);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                        child: Text(
                  _getOtherParticipantName(conversation, currentUserId)?.isNotEmpty == true
                      ? _getOtherParticipantName(conversation, currentUserId)![0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                _getOtherParticipantName(conversation, currentUserId) ?? 'Unknown User',
                          style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
                          ),
              subtitle: Text(
                conversation.lastMessage?.text ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unreadCount > 0 ? AppColors.primary : AppColors.subtitle,
                  fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTimestamp(conversation.lastMessage?.timestamp ?? conversation.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitle,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                        unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                ],
              ),
              onTap: () {
                setState(() {
                  _selectedConversation = conversation;
                });
                _loadMessages(conversation.id);
              },
              tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildChatArea(Conversation conversation) {
    return Consumer<ConversationService>(
      builder: (context, conversationService, child) {
        return Column(
          children: [
            // Chat header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.subtitle.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      _getOtherParticipantName(conversation, Provider.of<AuthService>(context, listen: false).user?.uid ?? '')?.isNotEmpty == true
                          ? _getOtherParticipantName(conversation, Provider.of<AuthService>(context, listen: false).user?.uid ?? '')![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getOtherParticipantName(conversation, Provider.of<AuthService>(context, listen: false).user?.uid ?? '') ?? 'Unknown User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Active now',
                          style: TextStyle(
                            color: AppColors.subtitle,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Messages area
            Expanded(
              child: conversationService.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMessagesList(conversationService.currentMessages),
            ),
            
            // Message input
            _buildMessageInput(conversation.id),
          ],
        );
      },
    );
  }

  Widget _buildEmptyChatArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.subtitle),
          const SizedBox(height: 16),
          Text(
            'Select a conversation',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a conversation from the list to start messaging',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<Message> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
      children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.subtitle),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.subtitle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to start the conversation',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.subtitle,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == Provider.of<AuthService>(context, listen: false).user?.uid;

        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
          if (!isMe) ...[
                  CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
                    child: Text(
                message.senderName.isNotEmpty 
                    ? message.senderName[0].toUpperCase()
                    : '?',
                      style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            const SizedBox(width: 8),
          ],
          Flexible(
                      child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: !isMe ? Border.all(color: AppColors.subtitle.withOpacity(0.2)) : null,
              ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                    Text(
                    _formatTimestamp(message.timestamp),
                      style: TextStyle(
                      color: isMe ? Colors.white70 : AppColors.subtitle,
                      fontSize: 11,
                    ),
                    ),
                  ],
                ),
              ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                message.senderName.isNotEmpty 
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(String conversationId) {
    return Container(
          padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
          top: BorderSide(color: AppColors.subtitle.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
              textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
            onPressed: _messageController.text.trim().isEmpty ? null : () => _sendMessage(conversationId),
                icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              ),
            ),
          ],
      ),
    );
  }

  Future<void> _loadMessages(String conversationId) async {
    final conversationService = Provider.of<ConversationService>(context, listen: false);
    await conversationService.getMessages(conversationId);
  }

  Future<void> _sendMessage(String conversationId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final conversationService = Provider.of<ConversationService>(context, listen: false);
    final success = await conversationService.sendMessage(conversationId, text);
    
    if (success) {
    _messageController.clear();
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  void _showNewConversationDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter the recipient\'s email address',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter the email address of the person you want to start a conversation with.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.subtitle,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              
              if (email.isNotEmpty) {
                // Basic email validation
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid email address')),
                  );
                  return;
                }

                // Check if user is trying to message themselves
                final currentUserEmail = Provider.of<AuthService>(context, listen: false).user?.email;
                if (email.toLowerCase() == currentUserEmail?.toLowerCase()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You cannot start a conversation with yourself')),
                  );
                  return;
                }

                final conversationService = Provider.of<ConversationService>(context, listen: false);
                final conversation = await conversationService.getOrCreateConversationByEmail(email);
                
                if (conversation != null) {
                  setState(() {
                    _selectedConversation = conversation;
                  });
                  _loadMessages(conversation.id);
                  Navigator.of(context).pop();
                  
                  // Refresh conversations list to show the new conversation
                  _hasAttemptedLoad = false;
                  conversationService.getConversations();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Conversation started with ${_getOtherParticipantName(conversation, Provider.of<AuthService>(context, listen: false).user?.uid ?? '') ?? 'Unknown User'}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(conversationService.error ?? 'Failed to create conversation'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Start Conversation'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('MMM d').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Helper methods to work around the Conversation model methods
  String? _getOtherParticipantName(Conversation? conversation, String currentUserId) {
    if (conversation == null) return null;
    
    for (final participantId in conversation.participants) {
      if (participantId != currentUserId) {
        return conversation.participantNames[participantId] ?? 'Unknown User';
      }
    }
    return 'Unknown User';
  }

  int _getUnreadCountForUser(Conversation conversation, String userId) {
    return conversation.unreadCount[userId] ?? 0;
  }
} 