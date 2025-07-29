import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/player.dart';
import 'auth_service.dart';

class PlayerService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _baseUrl = 'https://nsblpa.com';
  
  Player? _currentPlayer;
  bool _isLoading = false;
  String? _error;
  AuthService? _authService;

  Player? get currentPlayer => _currentPlayer;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateAuth(AuthService authService) {
    _authService = authService;
    if (authService.isLoggedIn) {
      _loadPlayerData();
    }
  }

  Future<void> _loadPlayerData() async {
    print('_loadPlayerData called');
    if (_authService?.user == null) {
      print('No auth service or user');
      return;
    }

    try {
      print('Loading player data for user: ${_authService!.user!.uid}');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('players')
          .where('userId', isEqualTo: _authService!.user!.uid)
          .get();

      print('Firestore query found ${querySnapshot.docs.length} documents');

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        print('Player data from Firestore: $data');
        _currentPlayer = Player.fromJson({
          'id': doc.id,
          ...data,
        });
        
        // Calculate and update finances automatically
        await _calculateAndUpdateFinances();
      } else {
        print('Creating default player data');
        // Create default player data if not exists
        _currentPlayer = _createDefaultPlayer();
        await _savePlayerToFirestore();
      }

      print('Current player set: ${_currentPlayer?.firstName} ${_currentPlayer?.lastName}');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading player data: $e');
      _isLoading = false;
      _error = 'Error loading player data: $e';
      notifyListeners();
    }
  }

  Player _createDefaultPlayer() {
    return Player(
      id: _authService!.user!.uid,
      userId: _authService!.user!.uid,
      firstName: _authService!.user!.displayName?.split(' ').first ?? 'Player',
      lastName: _authService!.user!.displayName?.split(' ').last ?? 'Name',
      email: _authService!.user!.email ?? '',
      profileImageUrl: _authService!.user!.photoURL,
      team: 'TBD',
      position: 'TBD',
      jerseyNumber: 0,
      dateOfBirth: DateTime(1990, 1, 1),
      nationality: 'TBD',
      stats: PlayerStats(
        gamesPlayed: 0,
        pointsPerGame: 0.0,
        reboundsPerGame: 0.0,
        assistsPerGame: 0.0,
        stealsPerGame: 0.0,
        blocksPerGame: 0.0,
        fieldGoalPercentage: 0.0,
        threePointPercentage: 0.0,
        freeThrowPercentage: 0.0,
        totalPoints: 0,
        totalRebounds: 0,
        totalAssists: 0,
      ),
      contractIds: [],
      endorsementIds: [],
      finances: FinancialSummary(
        currentSeasonEarnings: 0.0,
        careerEarnings: 0.0,
        endorsementEarnings: 0.0,
        contractEarnings: 0.0,
        yearlyEarnings: [],
        recentTransactions: [],
      ),
      memberSince: DateTime.now(),
    );
  }

  Future<void> _savePlayerToFirestore() async {
    if (_currentPlayer == null) return;

    try {
      await _firestore
          .collection('players')
          .doc(_currentPlayer!.id)
          .set(_currentPlayer!.toJson());
    } catch (e) {
      print('Error saving player to Firestore: $e');
    }
  }

  Future<void> _calculateAndUpdateFinances() async {
    if (_currentPlayer == null) return;

    try {
      // Get all contracts for the player
      final contractsSnapshot = await _firestore
          .collection('contracts')
          .where('userId', isEqualTo: _currentPlayer!.userId)
          .where('status', isEqualTo: 'active')
          .get();

      // Get all endorsements for the player
      final endorsementsSnapshot = await _firestore
          .collection('endorsements')
          .where('userId', isEqualTo: _currentPlayer!.userId)
          .where('status', isEqualTo: 'active')
          .get();

      // Calculate contract earnings
      double contractEarnings = 0.0;
      final contracts = <Contract>[];
      for (final doc in contractsSnapshot.docs) {
        final contract = Contract.fromJson({'id': doc.id, ...doc.data()});
        contracts.add(contract);
        if (contract.isActive && !contract.isExpired) {
          contractEarnings += contract.annualValue;
        }
      }

      // Calculate endorsement earnings
      double endorsementEarnings = 0.0;
      final endorsements = <Endorsement>[];
      for (final doc in endorsementsSnapshot.docs) {
        final endorsement = Endorsement.fromJson({'id': doc.id, ...doc.data()});
        endorsements.add(endorsement);
        if (endorsement.isActive) {
          endorsementEarnings += endorsement.value;
        }
      }

      // Calculate current season earnings (assuming season runs from October to June)
      final now = DateTime.now();
      final currentYear = now.month >= 10 ? now.year : now.year - 1;
      final seasonStart = DateTime(currentYear, 10, 1);
      final seasonEnd = DateTime(currentYear + 1, 6, 30);

      double currentSeasonEarnings = 0.0;
      if (now.isAfter(seasonStart) && now.isBefore(seasonEnd)) {
        // Calculate prorated earnings for current season
        final daysInSeason = seasonEnd.difference(seasonStart).inDays;
        final daysElapsed = now.difference(seasonStart).inDays;
        final prorationFactor = daysElapsed / daysInSeason;

        currentSeasonEarnings = (contractEarnings + endorsementEarnings) * prorationFactor;
      }

      // Calculate career earnings (sum of all historical earnings)
      double careerEarnings = contractEarnings + endorsementEarnings;

      // Get yearly earnings history
      final yearlyEarnings = await _calculateYearlyEarnings();

      // Get recent transactions
      final recentTransactions = await getRecentTransactions();

      // Update player's finances
      final updatedFinances = FinancialSummary(
        currentSeasonEarnings: currentSeasonEarnings,
        careerEarnings: careerEarnings,
        endorsementEarnings: endorsementEarnings,
        contractEarnings: contractEarnings,
        yearlyEarnings: yearlyEarnings,
        recentTransactions: recentTransactions,
      );

      // Update local player data
      _currentPlayer = Player(
        id: _currentPlayer!.id,
        userId: _currentPlayer!.userId,
        firstName: _currentPlayer!.firstName,
        lastName: _currentPlayer!.lastName,
        email: _currentPlayer!.email,
        profileImageUrl: _currentPlayer!.profileImageUrl,
        team: _currentPlayer!.team,
        position: _currentPlayer!.position,
        jerseyNumber: _currentPlayer!.jerseyNumber,
        dateOfBirth: _currentPlayer!.dateOfBirth,
        nationality: _currentPlayer!.nationality,
        stats: _currentPlayer!.stats,
        contractIds: contracts.map((c) => c.id).toList(),
        endorsementIds: endorsements.map((e) => e.id).toList(),
        finances: updatedFinances,
        memberSince: _currentPlayer!.memberSince,
      );

      // Update finances in Firestore
      await _firestore
          .collection('players')
          .doc(_currentPlayer!.id)
          .update({'finances': updatedFinances.toJson()});

      notifyListeners();
    } catch (e) {
      print('Error calculating finances: $e');
    }
  }

  Future<List<FinancialRecord>> _calculateYearlyEarnings() async {
    if (_currentPlayer == null) return [];

    try {
      final yearlyEarnings = <FinancialRecord>[];
      final currentYear = DateTime.now().year;

      // Calculate earnings for the last 5 years
      for (int year = currentYear - 4; year <= currentYear; year++) {
        final yearStart = DateTime(year, 1, 1);
        final yearEnd = DateTime(year, 12, 31);

        // Get contracts active during this year
        final contractsSnapshot = await _firestore
            .collection('contracts')
            .where('userId', isEqualTo: _currentPlayer!.userId)
            .where('startDate', isLessThanOrEqualTo: yearEnd.toIso8601String())
            .where('endDate', isGreaterThanOrEqualTo: yearStart.toIso8601String())
            .get();

        // Get endorsements active during this year
        final endorsementsSnapshot = await _firestore
            .collection('endorsements')
            .where('userId', isEqualTo: _currentPlayer!.userId)
            .where('startDate', isLessThanOrEqualTo: yearEnd.toIso8601String())
            .where('endDate', isGreaterThanOrEqualTo: yearStart.toIso8601String())
            .get();

        double yearContracts = 0.0;
        double yearEndorsements = 0.0;

        for (final doc in contractsSnapshot.docs) {
          final contract = Contract.fromJson({'id': doc.id, ...doc.data()});
          yearContracts += contract.annualValue;
        }

        for (final doc in endorsementsSnapshot.docs) {
          final endorsement = Endorsement.fromJson({'id': doc.id, ...doc.data()});
          yearEndorsements += endorsement.value;
        }

        yearlyEarnings.add(FinancialRecord(
          year: year,
          earnings: yearContracts + yearEndorsements,
          endorsements: yearEndorsements,
          contracts: yearContracts,
        ));
      }

      return yearlyEarnings;
    } catch (e) {
      print('Error calculating yearly earnings: $e');
      return [];
    }
  }

  Future<void> updatePlayerProfile({
    String? firstName,
    String? lastName,
    String? team,
    String? position,
    int? jerseyNumber,
    String? nationality,
    String? profileImageUrl,
  }) async {
    if (_currentPlayer == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updates = <String, dynamic>{};
      if (firstName != null) updates['firstName'] = firstName;
      if (lastName != null) updates['lastName'] = lastName;
      if (team != null) updates['team'] = team;
      if (position != null) updates['position'] = position;
      if (jerseyNumber != null) updates['jerseyNumber'] = jerseyNumber;
      if (nationality != null) updates['nationality'] = nationality;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      // Update in Firestore
      await _firestore
          .collection('players')
          .doc(_currentPlayer!.id)
          .update(updates);

      // Update local player data
      _currentPlayer = Player(
        id: _currentPlayer!.id,
        userId: _currentPlayer!.userId,
        firstName: firstName ?? _currentPlayer!.firstName,
        lastName: lastName ?? _currentPlayer!.lastName,
        email: _currentPlayer!.email,
        profileImageUrl: profileImageUrl ?? _currentPlayer!.profileImageUrl,
        team: team ?? _currentPlayer!.team,
        position: position ?? _currentPlayer!.position,
        jerseyNumber: jerseyNumber ?? _currentPlayer!.jerseyNumber,
        dateOfBirth: _currentPlayer!.dateOfBirth,
        nationality: nationality ?? _currentPlayer!.nationality,
        stats: _currentPlayer!.stats,
        contractIds: _currentPlayer!.contractIds,
        endorsementIds: _currentPlayer!.endorsementIds,
        finances: _currentPlayer!.finances,
        memberSince: _currentPlayer!.memberSince,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error updating profile';
      notifyListeners();
    }
  }

  Future<void> updatePlayerStats(PlayerStats stats) async {
    if (_currentPlayer == null) return;

    try {
      await _firestore
          .collection('players')
          .doc(_currentPlayer!.id)
          .update({'stats': stats.toJson()});

      _currentPlayer = Player(
        id: _currentPlayer!.id,
        userId: _currentPlayer!.userId,
        firstName: _currentPlayer!.firstName,
        lastName: _currentPlayer!.lastName,
        email: _currentPlayer!.email,
        profileImageUrl: _currentPlayer!.profileImageUrl,
        team: _currentPlayer!.team,
        position: _currentPlayer!.position,
        jerseyNumber: _currentPlayer!.jerseyNumber,
        dateOfBirth: _currentPlayer!.dateOfBirth,
        nationality: _currentPlayer!.nationality,
        stats: stats,
        contractIds: _currentPlayer!.contractIds,
        endorsementIds: _currentPlayer!.endorsementIds,
        finances: _currentPlayer!.finances,
        memberSince: _currentPlayer!.memberSince,
      );

      notifyListeners();
    } catch (e) {
      _error = 'Error updating stats';
      notifyListeners();
    }
  }

  Future<List<Contract>> getContracts() async {
    if (_currentPlayer == null) return [];

    try {
      final snapshot = await _firestore
          .collection('contracts')
          .where('userId', isEqualTo: _currentPlayer!.userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Contract.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      _error = 'Error loading contracts';
      notifyListeners();
      return [];
    }
  }

  Future<void> addContract(Contract contract) async {
    if (_currentPlayer == null) return;

    try {
      final contractData = {
        ...contract.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('contracts')
          .add(contractData);

      // Update player's contractIds
      final updatedContractIds = List<String>.from(_currentPlayer!.contractIds)
        ..add(docRef.id);

      await _firestore
          .collection('players')
          .doc(_currentPlayer!.id)
          .update({'contractIds': updatedContractIds});

      // Recalculate finances
      await _calculateAndUpdateFinances();

      notifyListeners();
    } catch (e) {
      _error = 'Error adding contract';
      notifyListeners();
    }
  }

  Future<void> updateContract(String contractId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('contracts')
          .doc(contractId)
          .update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recalculate finances
      await _calculateAndUpdateFinances();

      notifyListeners();
    } catch (e) {
      _error = 'Error updating contract';
      notifyListeners();
    }
  }

  Future<void> deleteContract(String contractId) async {
    if (_currentPlayer == null) return;

    try {
      await _firestore
          .collection('contracts')
          .doc(contractId)
          .delete();

      // Update player's contractIds
      final updatedContractIds = List<String>.from(_currentPlayer!.contractIds)
        ..remove(contractId);

      await _firestore
          .collection('players')
          .doc(_currentPlayer!.id)
          .update({'contractIds': updatedContractIds});

      // Recalculate finances
      await _calculateAndUpdateFinances();

      notifyListeners();
    } catch (e) {
      _error = 'Error deleting contract';
      notifyListeners();
    }
  }

  Future<List<Endorsement>> getEndorsements() async {
    if (_currentPlayer == null) return [];

    try {
      final snapshot = await _firestore
          .collection('endorsements')
          .where('userId', isEqualTo: _currentPlayer!.userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Endorsement.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      _error = 'Error loading endorsements';
      notifyListeners();
      return [];
    }
  }

  Future<void> addEndorsement(Endorsement endorsement) async {
    if (_currentPlayer == null) return;

    try {
      final endorsementData = {
        ...endorsement.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('endorsements')
          .add(endorsementData);

      // Update player's endorsementIds
      final updatedEndorsementIds = List<String>.from(_currentPlayer!.endorsementIds)
        ..add(docRef.id);

      await _firestore
          .collection('players')
          .doc(_currentPlayer!.id)
          .update({'endorsementIds': updatedEndorsementIds});

      // Recalculate finances
      await _calculateAndUpdateFinances();

      notifyListeners();
    } catch (e) {
      _error = 'Error adding endorsement';
      notifyListeners();
    }
  }

  Future<void> updateEndorsement(String endorsementId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('endorsements')
          .doc(endorsementId)
          .update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recalculate finances
      await _calculateAndUpdateFinances();

      notifyListeners();
    } catch (e) {
      _error = 'Error updating endorsement';
      notifyListeners();
    }
  }

  Future<void> deleteEndorsement(String endorsementId) async {
    if (_currentPlayer == null) return;

    try {
      await _firestore
          .collection('endorsements')
          .doc(endorsementId)
          .delete();

      // Update player's endorsementIds
      final updatedEndorsementIds = List<String>.from(_currentPlayer!.endorsementIds)
        ..remove(endorsementId);

      await _firestore
          .collection('players')
          .doc(_currentPlayer!.id)
          .update({'endorsementIds': updatedEndorsementIds});

      // Recalculate finances
      await _calculateAndUpdateFinances();

      notifyListeners();
    } catch (e) {
      _error = 'Error deleting endorsement';
      notifyListeners();
    }
  }

  Future<void> applyForEndorsement(String endorsementId) async {
    if (_currentPlayer == null) return;

    try {
      await _firestore
          .collection('endorsements')
          .doc(endorsementId)
          .update({
        'status': 'pending',
        'userId': _currentPlayer!.userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      _error = 'Error applying for endorsement';
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getUnionContent() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/content'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load union content');
      }
    } catch (e) {
      // Return mock data for development
      return {
        'announcements': [
          {
            'id': '1',
            'title': 'New Collective Bargaining Agreement',
            'content': 'The NSBLPA has successfully negotiated a new CBA with improved benefits.',
            'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          },
        ],
        'benefits': [
          {
            'id': '1',
            'title': 'Health Insurance',
            'description': 'Comprehensive health coverage for all active players',
            'coverage': 'Medical, Dental, Vision',
          },
          {
            'id': '2',
            'title': 'Pension Plan',
            'description': 'Retirement benefits for eligible players',
            'coverage': '401(k) with employer match',
          },
        ],
        'resources': [
          {
            'id': '1',
            'title': 'Player Handbook',
            'url': '$_baseUrl/resources/handbook.pdf',
            'type': 'pdf',
          },
          {
            'id': '2',
            'title': 'Contract Guidelines',
            'url': '$_baseUrl/resources/contracts.pdf',
            'type': 'pdf',
          },
        ],
      };
    }
  }

  Future<List<Transaction>> getRecentTransactions() async {
    if (_currentPlayer == null) return [];

    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: _currentPlayer!.userId)
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => Transaction.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      _error = 'Error loading transactions';
      notifyListeners();
      return [];
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    if (_currentPlayer == null) return;

    try {
      final transactionData = {
        ...transaction.toJson(),
        'userId': _currentPlayer!.userId,
      };

      await _firestore
          .collection('transactions')
          .add(transactionData);

      // Recalculate finances
      await _calculateAndUpdateFinances();

      notifyListeners();
    } catch (e) {
      _error = 'Error adding transaction';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 