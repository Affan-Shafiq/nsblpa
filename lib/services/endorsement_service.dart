import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/player.dart';

class EndorsementService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  String? _error;
  List<Endorsement> _availableEndorsements = [];
  List<Endorsement> _myEndorsements = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Endorsement> get availableEndorsements => _availableEndorsements;
  List<Endorsement> get myEndorsements => _myEndorsements;

  // Load available endorsements (status: 'available') excluding those already applied by current user
  Future<void> loadAvailableEndorsements() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        _availableEndorsements = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get all available endorsements
      final availableQuery = await _firestore
          .collection('endorsements')
          .where('status', isEqualTo: 'available')
          .get();
      
      // Get user's applied endorsements to filter them out
      final userEndorsementsQuery = await _firestore
          .collection('endorsements')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      // Create a set of brand names that the user has already applied for
      final appliedBrandNames = <String>{};
      for (final doc in userEndorsementsQuery.docs) {
        final data = doc.data();
        appliedBrandNames.add(data['brandName'] ?? '');
      }
      
      // Filter out endorsements the user has already applied for
      _availableEndorsements = availableQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Endorsement.fromJson(data);
      }).where((endorsement) => !appliedBrandNames.contains(endorsement.brandName)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error loading endorsements: $e';
      notifyListeners();
    }
  }

  // Load player's endorsements
  Future<void> loadMyEndorsements() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _isLoading = true;
      _error = null;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('endorsements')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      _myEndorsements = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Endorsement.fromJson(data);
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error loading my endorsements: $e';
      notifyListeners();
    }
  }

  // Request endorsement (player action)
  Future<bool> requestEndorsement(Endorsement endorsement) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'User not authenticated';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create a new endorsement request
      await _firestore.collection('endorsements').add({
        'userId': user.uid,
        'brandName': endorsement.brandName,
        'category': endorsement.category,
        'description': endorsement.description,
        'value': endorsement.value,
        'duration': endorsement.duration,
        'status': 'pending',
        'imageUrl': endorsement.imageUrl,
        'requirements': endorsement.requirements,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      
      // Reload my endorsements
      await loadMyEndorsements();
      
      // Reload available endorsements to hide the applied one
      await loadAvailableEndorsements();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error requesting endorsement: $e';
      notifyListeners();
      return false;
    }
  }

  // Get endorsement by ID
  Future<Endorsement?> getEndorsement(String endorsementId) async {
    try {
      final doc = await _firestore.collection('endorsements').doc(endorsementId).get();
      
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return Endorsement.fromJson(data);
    } catch (e) {
      print('Error getting endorsement: $e');
      return null;
    }
  }

  // Update endorsement status
  Future<bool> updateEndorsementStatus(String endorsementId, String status) async {
    try {
      await _firestore.collection('endorsements').doc(endorsementId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating endorsement status: $e');
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 