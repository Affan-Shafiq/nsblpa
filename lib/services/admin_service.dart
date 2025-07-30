import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/player.dart';

class AdminService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  String? _error;
  List<Endorsement> _pendingEndorsements = [];
  List<Endorsement> _allEndorsements = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Endorsement> get pendingEndorsements => _pendingEndorsements;
  List<Endorsement> get allEndorsements => _allEndorsements;

  // Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('players')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (doc.docs.isEmpty) return false;
      
      final playerData = doc.docs.first.data();
      return playerData['role'] == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Load all endorsements for admin view
  Future<void> loadAllEndorsements() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final querySnapshot = await _firestore.collection('endorsements').get();
      
      _allEndorsements = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Endorsement.fromJson(data);
      }).toList();

      _pendingEndorsements = _allEndorsements
          .where((e) => e.status == 'pending')
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error loading endorsements: $e';
      notifyListeners();
    }
  }

  // Create new endorsement (admin only)
  Future<bool> createEndorsement({
    required String brandName,
    required String category,
    required String description,
    required double value,
    required String duration,
    String? imageUrl,
    required List<String> requirements,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if user is admin
      if (!await isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      final endorsementData = {
        'userId': '', // Empty for available endorsements
        'brandName': brandName,
        'category': category,
        'description': description,
        'value': value,
        'duration': duration,
        'status': 'available',
        'imageUrl': imageUrl,
        'requirements': requirements,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('endorsements').add(endorsementData);

      _isLoading = false;
      notifyListeners();
      
      // Reload endorsements
      await loadAllEndorsements();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error creating endorsement: $e';
      notifyListeners();
      return false;
    }
  }

  // Approve endorsement request
  Future<bool> approveEndorsement(String endorsementId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if user is admin
      if (!await isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      await _firestore.collection('endorsements').doc(endorsementId).update({
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      
      // Reload endorsements
      await loadAllEndorsements();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error approving endorsement: $e';
      notifyListeners();
      return false;
    }
  }

  // Reject endorsement request (delete from database)
  Future<bool> rejectEndorsement(String endorsementId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if user is admin
      if (!await isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      // Delete the endorsement request from database
      await _firestore.collection('endorsements').doc(endorsementId).delete();

      _isLoading = false;
      notifyListeners();
      
      // Reload endorsements
      await loadAllEndorsements();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error rejecting endorsement: $e';
      notifyListeners();
      return false;
    }
  }

  // Get player details for endorsement requests
  Future<Player?> getPlayerDetails(String userId) async {
    try {
      final doc = await _firestore
          .collection('players')
          .where('userId', isEqualTo: userId)
          .get();

      if (doc.docs.isEmpty) return null;

      final data = doc.docs.first.data();
      data['id'] = doc.docs.first.id;
      return Player.fromJson(data);
    } catch (e) {
      print('Error getting player details: $e');
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 