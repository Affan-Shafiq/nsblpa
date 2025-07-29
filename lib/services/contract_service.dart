import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/player.dart';

class ContractService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Contract> _contracts = [];
  List<Endorsement> _endorsements = [];
  bool _isLoading = false;
  String? _error;

  List<Contract> get contracts => _contracts;
  List<Endorsement> get endorsements => _endorsements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get contracts for a specific player
  Future<List<Contract>> getContractsForPlayer(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('contracts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _contracts = snapshot.docs
          .map((doc) => Contract.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      _isLoading = false;
      notifyListeners();
      return _contracts;
    } catch (e) {
      _isLoading = false;
      _error = 'Error loading contracts: $e';
      notifyListeners();
      return [];
    }
  }

  // Get endorsements for a specific player
  Future<List<Endorsement>> getEndorsementsForPlayer(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('endorsements')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _endorsements = snapshot.docs
          .map((doc) => Endorsement.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      _isLoading = false;
      notifyListeners();
      return _endorsements;
    } catch (e) {
      _isLoading = false;
      _error = 'Error loading endorsements: $e';
      notifyListeners();
      return [];
    }
  }

  // Add a new contract
  Future<bool> addContract(Contract contract) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final contractData = {
        ...contract.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('contracts')
          .add(contractData);

      // Update player's contractIds
      await _firestore
          .collection('players')
          .doc(contract.userId)
          .update({
        'contractIds': FieldValue.arrayUnion([docRef.id])
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error adding contract: $e';
      notifyListeners();
      return false;
    }
  }

  // Add a new endorsement
  Future<bool> addEndorsement(Endorsement endorsement) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final endorsementData = {
        ...endorsement.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('endorsements')
          .add(endorsementData);

      // Update player's endorsementIds
      await _firestore
          .collection('players')
          .doc(endorsement.userId)
          .update({
        'endorsementIds': FieldValue.arrayUnion([docRef.id])
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error adding endorsement: $e';
      notifyListeners();
      return false;
    }
  }

  // Update a contract
  Future<bool> updateContract(String contractId, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('contracts')
          .doc(contractId)
          .update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error updating contract: $e';
      notifyListeners();
      return false;
    }
  }

  // Update an endorsement
  Future<bool> updateEndorsement(String endorsementId, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('endorsements')
          .doc(endorsementId)
          .update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error updating endorsement: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete a contract
  Future<bool> deleteContract(String contractId, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('contracts')
          .doc(contractId)
          .delete();

      // Update player's contractIds
      await _firestore
          .collection('players')
          .doc(userId)
          .update({
        'contractIds': FieldValue.arrayRemove([contractId])
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error deleting contract: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete an endorsement
  Future<bool> deleteEndorsement(String endorsementId, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('endorsements')
          .doc(endorsementId)
          .delete();

      // Update player's endorsementIds
      await _firestore
          .collection('players')
          .doc(userId)
          .update({
        'endorsementIds': FieldValue.arrayRemove([endorsementId])
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error deleting endorsement: $e';
      notifyListeners();
      return false;
    }
  }

  // Get available endorsements (not assigned to any player)
  Future<List<Endorsement>> getAvailableEndorsements() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('endorsements')
          .where('status', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .get();

      final availableEndorsements = snapshot.docs
          .map((doc) => Endorsement.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      _isLoading = false;
      notifyListeners();
      return availableEndorsements;
    } catch (e) {
      _isLoading = false;
      _error = 'Error loading available endorsements: $e';
      notifyListeners();
      return [];
    }
  }

  // Apply for an endorsement
  Future<bool> applyForEndorsement(String endorsementId, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('endorsements')
          .doc(endorsementId)
          .update({
        'status': 'pending',
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error applying for endorsement: $e';
      notifyListeners();
      return false;
    }
  }

  // Calculate total earnings from contracts for a player
  Future<double> calculateContractEarnings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('contracts')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      double totalEarnings = 0.0;
      for (final doc in snapshot.docs) {
        final contract = Contract.fromJson({'id': doc.id, ...doc.data()});
        if (contract.isActive && !contract.isExpired) {
          totalEarnings += contract.annualValue;
        }
      }

      return totalEarnings;
    } catch (e) {
      print('Error calculating contract earnings: $e');
      return 0.0;
    }
  }

  // Calculate total earnings from endorsements for a player
  Future<double> calculateEndorsementEarnings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('endorsements')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      double totalEarnings = 0.0;
      for (final doc in snapshot.docs) {
        final endorsement = Endorsement.fromJson({'id': doc.id, ...doc.data()});
        if (endorsement.isActive) {
          totalEarnings += endorsement.value;
        }
      }

      return totalEarnings;
    } catch (e) {
      print('Error calculating endorsement earnings: $e');
      return 0.0;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 