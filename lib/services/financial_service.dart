import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/player.dart';

class FinancialService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Calculate and update player finances automatically
  Future<void> calculateAndUpdatePlayerFinances(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get all active contracts for the player
      final contractsSnapshot = await _firestore
          .collection('contracts')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      // Get all active endorsements for the player
      final endorsementsSnapshot = await _firestore
          .collection('endorsements')
          .where('userId', isEqualTo: userId)
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
      final yearlyEarnings = await _calculateYearlyEarnings(userId);

      // Get recent transactions
      final recentTransactions = await getRecentTransactions(userId);

      // Update player's finances
      final updatedFinances = FinancialSummary(
        currentSeasonEarnings: currentSeasonEarnings,
        careerEarnings: careerEarnings,
        endorsementEarnings: endorsementEarnings,
        contractEarnings: contractEarnings,
        yearlyEarnings: yearlyEarnings,
        recentTransactions: recentTransactions,
      );

      // Update finances in Firestore
      await _firestore
          .collection('players')
          .doc(userId)
          .update({'finances': updatedFinances.toJson()});

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error calculating finances: $e';
      notifyListeners();
    }
  }

  // Calculate yearly earnings for a player
  Future<List<FinancialRecord>> _calculateYearlyEarnings(String userId) async {
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
            .where('userId', isEqualTo: userId)
            .where('startDate', isLessThanOrEqualTo: yearEnd.toIso8601String())
            .where('endDate', isGreaterThanOrEqualTo: yearStart.toIso8601String())
            .get();

        // Get endorsements active during this year
        final endorsementsSnapshot = await _firestore
            .collection('endorsements')
            .where('userId', isEqualTo: userId)
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

  // Get recent transactions for a player
  Future<List<Transaction>> getRecentTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => Transaction.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      print('Error loading transactions: $e');
      return [];
    }
  }

  // Add a new transaction
  Future<bool> addTransaction(Transaction transaction) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final transactionData = {
        ...transaction.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('transactions')
          .add(transactionData);

      // Recalculate finances after adding transaction
      await calculateAndUpdatePlayerFinances(transaction.userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error adding transaction: $e';
      notifyListeners();
      return false;
    }
  }

  // Get financial summary for a player
  Future<FinancialSummary?> getFinancialSummary(String userId) async {
    try {
      final doc = await _firestore
          .collection('players')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['finances'] != null) {
          return FinancialSummary.fromJson(data['finances']);
        }
      }

      return null;
    } catch (e) {
      print('Error getting financial summary: $e');
      return null;
    }
  }

  // Calculate monthly earnings for a specific month
  Future<double> calculateMonthlyEarnings(String userId, int year, int month) async {
    try {
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0);

      // Get contracts active during this month
      final contractsSnapshot = await _firestore
          .collection('contracts')
          .where('userId', isEqualTo: userId)
          .where('startDate', isLessThanOrEqualTo: monthEnd.toIso8601String())
          .where('endDate', isGreaterThanOrEqualTo: monthStart.toIso8601String())
          .get();

      // Get endorsements active during this month
      final endorsementsSnapshot = await _firestore
          .collection('endorsements')
          .where('userId', isEqualTo: userId)
          .where('startDate', isLessThanOrEqualTo: monthEnd.toIso8601String())
          .where('endDate', isGreaterThanOrEqualTo: monthStart.toIso8601String())
          .get();

      double monthlyEarnings = 0.0;

      // Calculate prorated contract earnings for the month
      for (final doc in contractsSnapshot.docs) {
        final contract = Contract.fromJson({'id': doc.id, ...doc.data()});
        if (contract.isActive) {
          // Calculate how many days of this month the contract was active
          final contractStart = contract.startDate.isAfter(monthStart) ? contract.startDate : monthStart;
          final contractEnd = contract.endDate.isBefore(monthEnd) ? contract.endDate : monthEnd;
          final activeDays = contractEnd.difference(contractStart).inDays + 1;
          final daysInMonth = monthEnd.difference(monthStart).inDays + 1;
          
          monthlyEarnings += (contract.annualValue / 12) * (activeDays / daysInMonth);
        }
      }

      // Calculate endorsement earnings for the month
      for (final doc in endorsementsSnapshot.docs) {
        final endorsement = Endorsement.fromJson({'id': doc.id, ...doc.data()});
        if (endorsement.isActive) {
          // For endorsements, we'll assume they pay monthly if active
          monthlyEarnings += endorsement.value / 12; // Assuming annual value
        }
      }

      return monthlyEarnings;
    } catch (e) {
      print('Error calculating monthly earnings: $e');
      return 0.0;
    }
  }

  // Get earnings breakdown by source
  Future<Map<String, double>> getEarningsBreakdown(String userId) async {
    try {
      final breakdown = <String, double>{};

      // Contract earnings by type
      final contractsSnapshot = await _firestore
          .collection('contracts')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in contractsSnapshot.docs) {
        final contract = Contract.fromJson({'id': doc.id, ...doc.data()});
        if (contract.isActive && !contract.isExpired) {
          final type = contract.type;
          breakdown[type] = (breakdown[type] ?? 0.0) + contract.annualValue;
        }
      }

      // Endorsement earnings by category
      final endorsementsSnapshot = await _firestore
          .collection('endorsements')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in endorsementsSnapshot.docs) {
        final endorsement = Endorsement.fromJson({'id': doc.id, ...doc.data()});
        if (endorsement.isActive) {
          final category = endorsement.category;
          breakdown[category] = (breakdown[category] ?? 0.0) + endorsement.value;
        }
      }

      return breakdown;
    } catch (e) {
      print('Error getting earnings breakdown: $e');
      return {};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 