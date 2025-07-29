import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'auth_service.dart';

class ConversationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;
  
  List<Conversation> _conversations = [];
  List<Message> _currentMessages = [];
  Conversation? _currentConversation;
  bool _isLoading = false;
  String? _error;

  List<Conversation> get conversations => _conversations;
  List<Message> get currentMessages => _currentMessages;
  Conversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ConversationService(this._authService) {
    // Automatically load conversations when service is created
    _loadConversationsIfNeeded();
  }

  // Check if conversations need to be loaded
  bool _hasLoadedConversations = false;

  // Helper method to get current user's name from players collection
  Future<String> _getCurrentUserName() async {
    if (_authService.user == null) return 'User';
    
    try {
      final currentUserSnapshot = await _firestore
          .collection('players')
          .where('userId', isEqualTo: _authService.user!.uid)
          .get();
      
      if (currentUserSnapshot.docs.isNotEmpty) {
        final currentUserData = currentUserSnapshot.docs.first.data();
        final userName = '${currentUserData['firstName'] ?? ''} ${currentUserData['lastName'] ?? ''}'.trim();
        if (userName.isNotEmpty) {
          return userName;
        }
        return currentUserData['email'] ?? 'User';
      }
    } catch (e) {
      print('Error getting current user name: $e');
    }
    
    return _authService.user!.email ?? 'User';
  }

  // Automatically load conversations if not already loaded
  Future<void> _loadConversationsIfNeeded() async {
    if (!_hasLoadedConversations && _authService.user != null) {
      await getConversations();
      _hasLoadedConversations = true;
    }
  }

  // Get all conversations for current user
  Future<List<Conversation>> getConversations() async {
    if (_authService.user == null) return [];

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: _authService.user!.uid)
          .orderBy('updatedAt', descending: true)
          .get();

      _conversations = snapshot.docs.map((doc) {
        return Conversation.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();

      _isLoading = false;
      _error = null;
      _hasLoadedConversations = true;
      notifyListeners();
      return _conversations;
    } catch (e) {
      _isLoading = false;
      _error = 'Error loading conversations: $e';
      _hasLoadedConversations = false;
      notifyListeners();
      return [];
    }
  }

  // Reset loading state for retry
  void resetLoadingState() {
    _hasLoadedConversations = false;
    _error = null;
    notifyListeners();
  }

  // Debug method to check conversation participants
  Future<void> debugConversations() async {
    if (_authService.user == null) return;

    try {
      final snapshot = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: _authService.user!.uid)
          .get();

      print('=== Conversation Debug Info ===');
      print('Current user UID: ${_authService.user!.uid}');
      print('Found ${snapshot.docs.length} conversations');
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('Conversation ID: ${doc.id}');
        print('Participants: ${data['participants']}');
        print('Participant Names: ${data['participantNames']}');
        print('---');
      }
    } catch (e) {
      print('Error debugging conversations: $e');
    }
  }

  // Get or create conversation with another user by email
  Future<Conversation?> getOrCreateConversationByEmail(String receiverEmail) async {
    if (_authService.user == null) return null;

    try {
      // First, find the user by email
      final userSnapshot = await _firestore
          .collection('players')
          .where('email', isEqualTo: receiverEmail)
          .get();

      if (userSnapshot.docs.isEmpty) {
        _error = 'User with email $receiverEmail not found';
        notifyListeners();
        return null;
      }

      final receiverDoc = userSnapshot.docs.first;
      final receiverData = receiverDoc.data();
      final receiverUserId = receiverData['userId'];
      
      // Validate that we have a Firebase Auth UID
      if (receiverUserId == null || receiverUserId.isEmpty) {
        _error = 'User with email $receiverEmail does not have a valid Firebase Auth UID';
        notifyListeners();
        return null;
      }
      
      final receiverName = '${receiverData['firstName'] ?? ''} ${receiverData['lastName'] ?? ''}'.trim();

      // Get current user's name
      final currentUserName = await _getCurrentUserName();

      // Check if conversation already exists (check both participants)
      final existingSnapshot = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: _authService.user!.uid)
          .get();

      for (final doc in existingSnapshot.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(receiverUserId)) {
          return Conversation.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }
      }

      // Also check if conversation exists from receiver's side
      final receiverConversationSnapshot = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: receiverUserId)
          .get();

      for (final doc in receiverConversationSnapshot.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(_authService.user!.uid)) {
          return Conversation.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }
      }

      // Create new conversation
      final conversationData = {
        'participants': [_authService.user!.uid, receiverUserId],
        'participantNames': {
          _authService.user!.uid: currentUserName,
          receiverUserId: receiverName.isNotEmpty ? receiverName : receiverEmail,
        },
        'lastMessage': null,
        'unreadCount': {
          _authService.user!.uid: 0,
          receiverUserId: 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('conversations').add(conversationData);
      
      return Conversation.fromJson({
        'id': docRef.id,
        ...conversationData,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      _error = 'Error creating conversation: $e';
      notifyListeners();
      return null;
    }
  }

  // Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _currentMessages = snapshot.docs.map((doc) {
        return Message.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();

      // Mark messages as read
      await _markMessagesAsRead(conversationId);

      _isLoading = false;
      notifyListeners();
      return _currentMessages;
    } catch (e) {
      _isLoading = false;
      _error = 'Error loading messages: $e';
      notifyListeners();
      return [];
    }
  }

  // Send a message
  Future<bool> sendMessage(String conversationId, String text) async {
    if (_authService.user == null) return false;

    try {
      final senderName = await _getCurrentUserName();
      final messageData = {
        'senderId': _authService.user!.uid,
        'senderName': senderName,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [_authService.user!.uid], // Sender has read it
      };

      // Add message to subcollection
      final messageRef = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(messageData);

      // Update conversation
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessage': {
          'text': text,
          'senderId': _authService.user!.uid,
          'timestamp': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add message to current messages list
      final newMessage = Message.fromJson({
        'id': messageRef.id,
        ...messageData,
        'timestamp': DateTime.now(),
      });

      _currentMessages.insert(0, newMessage);
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Error sending message: $e';
      notifyListeners();
      return false;
    }
  }

  // Mark messages as read
  Future<void> _markMessagesAsRead(String conversationId) async {
    if (_authService.user == null) return;

    try {
      // Get unread messages
      final unreadMessages = _currentMessages.where((msg) => 
        msg.senderId != _authService.user!.uid && 
        !msg.readBy.contains(_authService.user!.uid)
      ).toList();

      // Mark each unread message as read
      for (final message in unreadMessages) {
        await _firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .doc(message.id)
            .update({
          'readBy': FieldValue.arrayUnion([_authService.user!.uid])
        });
      }

      // Update unread count in conversation
      if (unreadMessages.isNotEmpty) {
        await _firestore
            .collection('conversations')
            .doc(conversationId)
            .update({
          'unreadCount.${_authService.user!.uid}': 0
        });
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Set current conversation
  void setCurrentConversation(Conversation conversation) {
    _currentConversation = conversation;
    notifyListeners();
  }

  // Clear current conversation
  void clearCurrentConversation() {
    _currentConversation = null;
    _currentMessages = [];
    notifyListeners();
  }

  // Listen to real-time messages
  Stream<List<Message>> listenToMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Message.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  // Listen to real-time conversations
  Stream<List<Conversation>> listenToConversations() {
    if (_authService.user == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: _authService.user!.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Conversation.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }
} 