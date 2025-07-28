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
      } else {
        print('Creating default player data');
        // Create default player data if not exists
        _currentPlayer = _createDefaultPlayer();
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
      contracts: [],
      endorsements: [],
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

      // Find the document by userId and update it
      final querySnapshot = await _firestore
          .collection('players')
          .where('userId', isEqualTo: _authService!.user!.uid)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update(updates);
      }

      // Update local player data
      _currentPlayer = Player(
        id: _currentPlayer!.id,
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
        contracts: _currentPlayer!.contracts,
        endorsements: _currentPlayer!.endorsements,
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
      // Find the document by userId and update it
      final querySnapshot = await _firestore
          .collection('players')
          .where('userId', isEqualTo: _authService!.user!.uid)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({'stats': stats.toJson()});
      }

      _currentPlayer = Player(
        id: _currentPlayer!.id,
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
        contracts: _currentPlayer!.contracts,
        endorsements: _currentPlayer!.endorsements,
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
          .collection('players')
          .doc(_currentPlayer!.id)
          .collection('contracts')
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
      await _firestore
          .collection('players')
          .doc(_currentPlayer!.id)
          .collection('contracts')
          .add(contract.toJson());

      // Refresh contracts
      final contracts = await getContracts();
      _currentPlayer = Player(
        id: _currentPlayer!.id,
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
        contracts: contracts,
        endorsements: _currentPlayer!.endorsements,
        finances: _currentPlayer!.finances,
        memberSince: _currentPlayer!.memberSince,
      );

      notifyListeners();
    } catch (e) {
      _error = 'Error adding contract';
      notifyListeners();
    }
  }

  Future<List<Endorsement>> getEndorsements() async {
    if (_currentPlayer == null) return [];

    try {
      final snapshot = await _firestore
          .collection('players')
          .doc(_currentPlayer!.id)
          .collection('endorsements')
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

  Future<void> applyForEndorsement(String endorsementId) async {
    if (_currentPlayer == null) return;

    try {
      await _firestore
          .collection('players')
          .doc(_currentPlayer!.id)
          .collection('endorsements')
          .doc(endorsementId)
          .set({
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
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
          .collection('players')
          .doc(_currentPlayer!.id)
          .collection('transactions')
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 