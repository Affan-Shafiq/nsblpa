import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

// Helper function to convert Firestore data to DateTime
DateTime _parseDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is String) {
    return DateTime.parse(value);
  } else if (value is DateTime) {
    return value;
  }
  throw FormatException('Cannot parse date: $value');
}

class Player {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImageUrl;
  final String team;
  final String position;
  final int jerseyNumber;
  final DateTime dateOfBirth;
  final String nationality;
  final PlayerStats stats;
  final List<Contract> contracts;
  final List<Endorsement> endorsements;
  final FinancialSummary finances;
  final DateTime memberSince;

  Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImageUrl,
    required this.team,
    required this.position,
    required this.jerseyNumber,
    required this.dateOfBirth,
    required this.nationality,
    required this.stats,
    required this.contracts,
    required this.endorsements,
    required this.finances,
    required this.memberSince,
  });

  String get fullName => '$firstName $lastName';
  String get displayName => '$firstName $lastName';
  int get age => DateTime.now().year - dateOfBirth.year;

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      team: json['team'] ?? '',
      position: json['position'] ?? '',
      jerseyNumber: json['jerseyNumber'] ?? 0,
      dateOfBirth: _parseDateTime(json['dateOfBirth']),
      nationality: json['nationality'] ?? '',
      stats: PlayerStats.fromJson(json['stats'] ?? {}),
      contracts: (json['contracts'] as List? ?? [])
          .map((c) => Contract.fromJson(c))
          .toList(),
      endorsements: (json['endorsements'] as List? ?? [])
          .map((e) => Endorsement.fromJson(e))
          .toList(),
      finances: FinancialSummary.fromJson(json['finances'] ?? {}),
      memberSince: _parseDateTime(json['memberSince']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'team': team,
      'position': position,
      'jerseyNumber': jerseyNumber,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'nationality': nationality,
      'stats': stats.toJson(),
      'contracts': contracts.map((c) => c.toJson()).toList(),
      'endorsements': endorsements.map((e) => e.toJson()).toList(),
      'finances': finances.toJson(),
      'memberSince': memberSince.toIso8601String(),
    };
  }
}

class PlayerStats {
  final int gamesPlayed;
  final double pointsPerGame;
  final double reboundsPerGame;
  final double assistsPerGame;
  final double stealsPerGame;
  final double blocksPerGame;
  final double fieldGoalPercentage;
  final double threePointPercentage;
  final double freeThrowPercentage;
  final int totalPoints;
  final int totalRebounds;
  final int totalAssists;

  PlayerStats({
    required this.gamesPlayed,
    required this.pointsPerGame,
    required this.reboundsPerGame,
    required this.assistsPerGame,
    required this.stealsPerGame,
    required this.blocksPerGame,
    required this.fieldGoalPercentage,
    required this.threePointPercentage,
    required this.freeThrowPercentage,
    required this.totalPoints,
    required this.totalRebounds,
    required this.totalAssists,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      gamesPlayed: json['gamesPlayed'] ?? 0,
      pointsPerGame: (json['pointsPerGame'] ?? 0).toDouble(),
      reboundsPerGame: (json['reboundsPerGame'] ?? 0).toDouble(),
      assistsPerGame: (json['assistsPerGame'] ?? 0).toDouble(),
      stealsPerGame: (json['stealsPerGame'] ?? 0).toDouble(),
      blocksPerGame: (json['blocksPerGame'] ?? 0).toDouble(),
      fieldGoalPercentage: (json['fieldGoalPercentage'] ?? 0).toDouble(),
      threePointPercentage: (json['threePointPercentage'] ?? 0).toDouble(),
      freeThrowPercentage: (json['freeThrowPercentage'] ?? 0).toDouble(),
      totalPoints: json['totalPoints'] ?? 0,
      totalRebounds: json['totalRebounds'] ?? 0,
      totalAssists: json['totalAssists'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gamesPlayed': gamesPlayed,
      'pointsPerGame': pointsPerGame,
      'reboundsPerGame': reboundsPerGame,
      'assistsPerGame': assistsPerGame,
      'stealsPerGame': stealsPerGame,
      'blocksPerGame': blocksPerGame,
      'fieldGoalPercentage': fieldGoalPercentage,
      'threePointPercentage': threePointPercentage,
      'freeThrowPercentage': freeThrowPercentage,
      'totalPoints': totalPoints,
      'totalRebounds': totalRebounds,
      'totalAssists': totalAssists,
    };
  }
}

class Contract {
  final String id;
  final String type; // 'player', 'endorsement', 'sponsorship'
  final String title;
  final String description;
  final double annualValue;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'active', 'expired', 'pending', 'terminated'
  final String? documentUrl;
  final List<String> incentives;
  final Map<String, dynamic> terms;

  Contract({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.annualValue,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.documentUrl,
    required this.incentives,
    required this.terms,
  });

  bool get isActive => status == 'active';
  bool get isExpired => DateTime.now().isAfter(endDate);
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      annualValue: (json['annualValue'] ?? 0).toDouble(),
      startDate: _parseDateTime(json['startDate']),
      endDate: _parseDateTime(json['endDate']),
      status: json['status'] ?? '',
      documentUrl: json['documentUrl'],
      incentives: List<String>.from(json['incentives'] ?? []),
      terms: json['terms'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'annualValue': annualValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'documentUrl': documentUrl,
      'incentives': incentives,
      'terms': terms,
    };
  }
}

class Endorsement {
  final String id;
  final String brandName;
  final String category;
  final String description;
  final double value;
  final String duration;
  final String status; // 'active', 'expired', 'pending', 'available'
  final String? imageUrl;
  final List<String> requirements;
  final DateTime? startDate;
  final DateTime? endDate;

  Endorsement({
    required this.id,
    required this.brandName,
    required this.category,
    required this.description,
    required this.value,
    required this.duration,
    required this.status,
    this.imageUrl,
    required this.requirements,
    this.startDate,
    this.endDate,
  });

  bool get isAvailable => status == 'available';
  bool get isActive => status == 'active';

  factory Endorsement.fromJson(Map<String, dynamic> json) {
    return Endorsement(
      id: json['id'] ?? '',
      brandName: json['brandName'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      duration: json['duration'] ?? '',
      status: json['status'] ?? '',
      imageUrl: json['imageUrl'],
      requirements: List<String>.from(json['requirements'] ?? []),
      startDate: json['startDate'] != null ? _parseDateTime(json['startDate']) : null,
      endDate: json['endDate'] != null ? _parseDateTime(json['endDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandName': brandName,
      'category': category,
      'description': description,
      'value': value,
      'duration': duration,
      'status': status,
      'imageUrl': imageUrl,
      'requirements': requirements,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}

class FinancialSummary {
  final double currentSeasonEarnings;
  final double careerEarnings;
  final double endorsementEarnings;
  final double contractEarnings;
  final List<FinancialRecord> yearlyEarnings;
  final List<Transaction> recentTransactions;

  FinancialSummary({
    required this.currentSeasonEarnings,
    required this.careerEarnings,
    required this.endorsementEarnings,
    required this.contractEarnings,
    required this.yearlyEarnings,
    required this.recentTransactions,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      currentSeasonEarnings: (json['currentSeasonEarnings'] ?? 0).toDouble(),
      careerEarnings: (json['careerEarnings'] ?? 0).toDouble(),
      endorsementEarnings: (json['endorsementEarnings'] ?? 0).toDouble(),
      contractEarnings: (json['contractEarnings'] ?? 0).toDouble(),
      yearlyEarnings: (json['yearlyEarnings'] as List? ?? [])
          .map((e) => FinancialRecord.fromJson(e))
          .toList(),
      recentTransactions: (json['recentTransactions'] as List? ?? [])
          .map((t) => Transaction.fromJson(t))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentSeasonEarnings': currentSeasonEarnings,
      'careerEarnings': careerEarnings,
      'endorsementEarnings': endorsementEarnings,
      'contractEarnings': contractEarnings,
      'yearlyEarnings': yearlyEarnings.map((e) => e.toJson()).toList(),
      'recentTransactions': recentTransactions.map((t) => t.toJson()).toList(),
    };
  }
}

class FinancialRecord {
  final int year;
  final double earnings;
  final double endorsements;
  final double contracts;

  FinancialRecord({
    required this.year,
    required this.earnings,
    required this.endorsements,
    required this.contracts,
  });

  factory FinancialRecord.fromJson(Map<String, dynamic> json) {
    return FinancialRecord(
      year: json['year'] ?? 0,
      earnings: (json['earnings'] ?? 0).toDouble(),
      endorsements: (json['endorsements'] ?? 0).toDouble(),
      contracts: (json['contracts'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'earnings': earnings,
      'endorsements': endorsements,
      'contracts': contracts,
    };
  }
}

class Transaction {
  final String id;
  final String description;
  final double amount;
  final String type; // 'income', 'expense'
  final String category;
  final DateTime date;
  final String status; // 'completed', 'pending', 'failed'

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.status,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      date: _parseDateTime(json['date']),
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'status': status,
    };
  }
} 