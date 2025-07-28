import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mock conversations
  final List<Conversation> _conversations = [
    Conversation(
      id: '1',
      name: 'Player Representative',
      avatar: null,
      lastMessage: 'Your contract renewal is ready for review.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      unreadCount: 1,
      isOnline: true,
    ),
    Conversation(
      id: '2',
      name: 'NSBLPA Support',
      avatar: null,
      lastMessage: 'We\'ve received your endorsement application.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
      isOnline: true,
    ),
    Conversation(
      id: '3',
      name: 'Legal Team',
      avatar: null,
      lastMessage: 'Please review the updated CBA document.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
    ),
  ];

  Conversation? _selectedConversation;

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
        title: Text(_selectedConversation?.name ?? 'Messages'),
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
              // Conversations List
              Container(
                width: 300,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
                child: _buildConversationsList(),
              ),
              
              // Chat Area
              Expanded(
                child: _selectedConversation == null
                    ? _buildEmptyChatState()
                    : _buildChatArea(_selectedConversation!),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _buildConversationTile(conversation);
      },
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final isSelected = _selectedConversation?.id == conversation.id;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedConversation = conversation;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    conversation.name[0],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimestamp(conversation.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
      ),
    );
  }

  Widget _buildEmptyChatState() {
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
            'Select a conversation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a conversation from the list to start messaging',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(Conversation conversation) {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      conversation.name[0],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (conversation.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      conversation.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: conversation.isOnline ? AppColors.success : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showChatOptions(conversation);
                },
              ),
            ],
          ),
        ),
        
        // Messages Area
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _getMessages(conversation.id).length,
              itemBuilder: (context, index) {
                final message = _getMessages(conversation.id)[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
        ),
        
        // Message Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE0E0E0)),
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
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.isFromMe;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Message> _getMessages(String conversationId) {
    // Mock messages for each conversation
    switch (conversationId) {
      case '1':
        return [
          Message(
            id: '1',
            text: 'Hello! I\'m your player representative. How can I help you today?',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isFromMe: false,
          ),
          Message(
            id: '2',
            text: 'Hi! I have some questions about my contract renewal.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
            isFromMe: true,
          ),
          Message(
            id: '3',
            text: 'Of course! I\'d be happy to help. What specific questions do you have?',
            timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
            isFromMe: false,
          ),
          Message(
            id: '4',
            text: 'Your contract renewal is ready for review. I\'ve sent you the updated terms.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            isFromMe: false,
          ),
        ];
      case '2':
        return [
          Message(
            id: '1',
            text: 'Welcome to NSBLPA Support! How can we assist you?',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
            isFromMe: false,
          ),
          Message(
            id: '2',
            text: 'I submitted an endorsement application yesterday.',
            timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
            isFromMe: true,
          ),
          Message(
            id: '3',
            text: 'We\'ve received your endorsement application and it\'s currently under review.',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isFromMe: false,
          ),
        ];
      default:
        return [];
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    // TODO: Implement actual message sending
    setState(() {
      // Add message to the conversation
    });
    
    _messageController.clear();
    _scrollToBottom();
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return DateFormat('MMM dd').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Player Representative'),
              subtitle: const Text('Contract and career guidance'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Start new conversation
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('NSBLPA Support'),
              subtitle: const Text('General inquiries and assistance'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Start new conversation
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel),
              title: const Text('Legal Team'),
              subtitle: const Text('Legal matters and documentation'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Start new conversation
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(Conversation conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Messages'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement search
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Mute Notifications'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement mute
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Conversation'),
              onTap: () {
                Navigator.of(context).pop();
                _deleteConversation(conversation);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteConversation(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Are you sure you want to delete the conversation with ${conversation.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _conversations.remove(conversation);
                if (_selectedConversation?.id == conversation.id) {
                  _selectedConversation = null;
                }
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class Conversation {
  final String id;
  final String name;
  final String? avatar;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final bool isOnline;

  Conversation({
    required this.id,
    required this.name,
    this.avatar,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isOnline,
  });
}

class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isFromMe;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isFromMe,
  });
} 