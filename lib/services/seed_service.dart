import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/player.dart';

class SeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedPlayerData(String userId) async {
    try {
      // Check if data already exists
      final doc = await _firestore.collection('players').doc(userId).get();
      if (doc.exists) {
        print('Player data already exists for user: $userId');
        return;
      }

      // Create player data with new structure
      final playerData = {
        'userId': userId,
        'firstName': 'Michael',
        'lastName': 'Johnson',
        'email': 'michael.johnson@nsblpa.com',
        'profileImageUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'team': 'Brooklyn Nets',
        'position': 'Point Guard',
        'jerseyNumber': 23,
        'dateOfBirth': Timestamp.fromDate(DateTime(1995, 3, 15)),
        'nationality': 'USA',
        'memberSince': FieldValue.serverTimestamp(),
        'stats': {
          'gamesPlayed': 82,
          'pointsPerGame': 24.5,
          'reboundsPerGame': 4.2,
          'assistsPerGame': 8.7,
          'stealsPerGame': 1.8,
          'blocksPerGame': 0.3,
          'fieldGoalPercentage': 0.456,
          'threePointPercentage': 0.389,
          'freeThrowPercentage': 0.892,
          'totalPoints': 2009,
          'totalRebounds': 344,
          'totalAssists': 713
        },
        'contractIds': [], // Will be populated after creating contracts
        'endorsementIds': [], // Will be populated after creating endorsements
        'finances': {
          'currentSeasonEarnings': 0.0,
          'careerEarnings': 0.0,
          'endorsementEarnings': 0.0,
          'contractEarnings': 0.0,
          'yearlyEarnings': [],
          'recentTransactions': []
        }
      };

      // Add the player data to Firestore
      await _firestore.collection('players').doc(userId).set(playerData);

      // Create contracts for this player
      final contractIds = await _createContractsForPlayer(userId);

      // Create endorsements for this player
      final endorsementIds = await _createEndorsementsForPlayer(userId);

      // Create transactions for this player
      await _createTransactionsForPlayer(userId);

      // Update player with contract and endorsement IDs
      await _firestore.collection('players').doc(userId).update({
        'contractIds': contractIds,
        'endorsementIds': endorsementIds,
      });

      print('Successfully seeded player data for user: $userId');
    } catch (e) {
      print('Error seeding player data: $e');
    }
  }

  Future<List<String>> _createContractsForPlayer(String userId) async {
    final contracts = [
      {
        'userId': userId,
        'type': 'player',
        'title': 'NBA Player Contract - Brooklyn Nets',
        'description': 'Standard NBA player contract with performance incentives',
        'annualValue': 15000000.0,
        'startDate': Timestamp.fromDate(DateTime(2023, 10, 1)),
        'endDate': Timestamp.fromDate(DateTime(2026, 9, 30)),
        'status': 'active',
        'documentUrl': 'https://example.com/contracts/contract_001.pdf',
        'incentives': [
          'All-Star selection: \$500,000',
          'Playoff appearance: \$250,000',
          'Conference Finals: \$500,000',
          'NBA Finals: \$1,000,000',
          'MVP: \$2,000,000'
        ],
        'terms': {
          'guaranteed': true,
          'teamOption': false,
          'playerOption': true,
          'noTradeClause': false
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': userId,
        'type': 'sponsorship',
        'title': 'Local Business Partnership',
        'description': 'Partnership with local Brooklyn businesses',
        'annualValue': 500000.0,
        'startDate': Timestamp.fromDate(DateTime(2023, 11, 1)),
        'endDate': Timestamp.fromDate(DateTime(2024, 10, 31)),
        'status': 'active',
        'documentUrl': null,
        'incentives': [
          'Community events: \$25,000 per event',
          'Charity appearances: \$15,000 per appearance'
        ],
        'terms': {
          'guaranteed': true,
          'renewable': true,
          'exclusivity': false
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }
    ];

    final contractIds = <String>[];
    for (final contract in contracts) {
      final docRef = await _firestore.collection('contracts').add(contract);
      contractIds.add(docRef.id);
    }

    return contractIds;
  }

  Future<List<String>> _createEndorsementsForPlayer(String userId) async {
    final endorsements = [
      {
        'userId': userId,
        'brandName': 'Nike',
        'category': 'Athletic Wear',
        'description': 'Exclusive shoe and apparel endorsement deal',
        'value': 2500000.0,
        'duration': '3 years',
        'status': 'active',
        'imageUrl': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=300&h=200&fit=crop',
        'requirements': [
          'Wear Nike shoes during all games',
          'Attend 4 promotional events per year',
          'Social media posts (2 per month)',
          'Appear in 2 commercials per year'
        ],
        'startDate': Timestamp.fromDate(DateTime(2023, 1, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 12, 31)),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': userId,
        'brandName': 'Gatorade',
        'category': 'Beverages',
        'description': 'Official sports drink endorsement',
        'value': 1200000.0,
        'duration': '2 years',
        'status': 'active',
        'imageUrl': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300&h=200&fit=crop',
        'requirements': [
          'Use Gatorade during games and practices',
          'Appear in 2 commercials',
          'Social media posts (1 per month)',
          'Attend 2 promotional events per year'
        ],
        'startDate': Timestamp.fromDate(DateTime(2023, 6, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 5, 31)),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }
    ];

    final endorsementIds = <String>[];
    for (final endorsement in endorsements) {
      final docRef = await _firestore.collection('endorsements').add(endorsement);
      endorsementIds.add(docRef.id);
    }

    return endorsementIds;
  }

  Future<void> _createTransactionsForPlayer(String userId) async {
    final transactions = [
      {
        'userId': userId,
        'description': 'Monthly salary payment - Brooklyn Nets',
        'amount': 1250000.0,
        'type': 'income',
        'category': 'salary',
        'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
        'status': 'completed'
      },
      {
        'userId': userId,
        'description': 'Nike quarterly endorsement payment',
        'amount': 625000.0,
        'type': 'income',
        'category': 'endorsement',
        'date': Timestamp.fromDate(DateTime(2024, 1, 10)),
        'status': 'completed'
      },
      {
        'userId': userId,
        'description': 'Gatorade monthly endorsement payment',
        'amount': 100000.0,
        'type': 'income',
        'category': 'endorsement',
        'date': Timestamp.fromDate(DateTime(2024, 1, 5)),
        'status': 'completed'
      },
      {
        'userId': userId,
        'description': 'Local business partnership payment',
        'amount': 41666.67,
        'type': 'income',
        'category': 'sponsorship',
        'date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'status': 'completed'
      }
    ];

    for (final transaction in transactions) {
      await _firestore.collection('transactions').add(transaction);
    }
  }

  Future<void> seedMultiplePlayers() async {
    final players = [
      {
        'id': 'player_michael_johnson',
        'firstName': 'Michael',
        'lastName': 'Johnson',
        'email': 'michael.johnson@nsblpa.com',
        'profileImageUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'team': 'Brooklyn Nets',
        'position': 'Point Guard',
        'jerseyNumber': 23,
        'dateOfBirth': Timestamp.fromDate(DateTime(1995, 3, 15)),
        'nationality': 'USA',
        'memberSince': FieldValue.serverTimestamp(),
        'stats': {
          'gamesPlayed': 82,
          'pointsPerGame': 24.5,
          'reboundsPerGame': 4.2,
          'assistsPerGame': 8.7,
          'stealsPerGame': 1.8,
          'blocksPerGame': 0.3,
          'fieldGoalPercentage': 0.456,
          'threePointPercentage': 0.389,
          'freeThrowPercentage': 0.892,
          'totalPoints': 2009,
          'totalRebounds': 344,
          'totalAssists': 713
        }
      },
      {
        'id': 'player_sarah_williams',
        'firstName': 'Sarah',
        'lastName': 'Williams',
        'email': 'sarah.williams@nsblpa.com',
        'profileImageUrl': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
        'team': 'Los Angeles Lakers',
        'position': 'Shooting Guard',
        'jerseyNumber': 8,
        'dateOfBirth': Timestamp.fromDate(DateTime(1997, 7, 22)),
        'nationality': 'USA',
        'memberSince': FieldValue.serverTimestamp(),
        'stats': {
          'gamesPlayed': 78,
          'pointsPerGame': 18.9,
          'reboundsPerGame': 5.1,
          'assistsPerGame': 3.8,
          'stealsPerGame': 1.2,
          'blocksPerGame': 0.5,
          'fieldGoalPercentage': 0.423,
          'threePointPercentage': 0.367,
          'freeThrowPercentage': 0.845,
          'totalPoints': 1474,
          'totalRebounds': 398,
          'totalAssists': 296
        }
      },
      {
        'id': 'player_james_rodriguez',
        'firstName': 'James',
        'lastName': 'Rodriguez',
        'email': 'james.rodriguez@nsblpa.com',
        'profileImageUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
        'team': 'Miami Heat',
        'position': 'Power Forward',
        'jerseyNumber': 34,
        'dateOfBirth': Timestamp.fromDate(DateTime(1993, 11, 8)),
        'nationality': 'USA',
        'memberSince': FieldValue.serverTimestamp(),
        'stats': {
          'gamesPlayed': 75,
          'pointsPerGame': 22.1,
          'reboundsPerGame': 8.9,
          'assistsPerGame': 2.1,
          'stealsPerGame': 0.8,
          'blocksPerGame': 1.2,
          'fieldGoalPercentage': 0.512,
          'threePointPercentage': 0.298,
          'freeThrowPercentage': 0.756,
          'totalPoints': 1658,
          'totalRebounds': 668,
          'totalAssists': 158
        }
      },
      {
        'id': 'player_emma_davis',
        'firstName': 'Emma',
        'lastName': 'Davis',
        'email': 'emma.davis@nsblpa.com',
        'profileImageUrl': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        'team': 'Golden State Warriors',
        'position': 'Small Forward',
        'jerseyNumber': 30,
        'dateOfBirth': Timestamp.fromDate(DateTime(1996, 4, 12)),
        'nationality': 'USA',
        'memberSince': FieldValue.serverTimestamp(),
        'stats': {
          'gamesPlayed': 80,
          'pointsPerGame': 16.7,
          'reboundsPerGame': 6.3,
          'assistsPerGame': 4.2,
          'stealsPerGame': 1.5,
          'blocksPerGame': 0.7,
          'fieldGoalPercentage': 0.445,
          'threePointPercentage': 0.401,
          'freeThrowPercentage': 0.823,
          'totalPoints': 1336,
          'totalRebounds': 504,
          'totalAssists': 336
        }
      },
      {
        'id': 'player_david_chen',
        'firstName': 'David',
        'lastName': 'Chen',
        'email': 'david.chen@nsblpa.com',
        'profileImageUrl': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        'team': 'Boston Celtics',
        'position': 'Center',
        'jerseyNumber': 42,
        'dateOfBirth': Timestamp.fromDate(DateTime(1994, 9, 3)),
        'nationality': 'USA',
        'memberSince': FieldValue.serverTimestamp(),
        'stats': {
          'gamesPlayed': 76,
          'pointsPerGame': 14.2,
          'reboundsPerGame': 11.8,
          'assistsPerGame': 1.9,
          'stealsPerGame': 0.6,
          'blocksPerGame': 2.1,
          'fieldGoalPercentage': 0.587,
          'threePointPercentage': 0.000,
          'freeThrowPercentage': 0.634,
          'totalPoints': 1079,
          'totalRebounds': 897,
          'totalAssists': 144
        }
      }
    ];

    for (final player in players) {
      final id = player['id'] as String;
      final playerData = Map<String, dynamic>.from(player);
      playerData.remove('id'); // Remove the id from the data since it's the document ID
      
      // Add required fields for new structure
      playerData['userId'] = id;
      playerData['contractIds'] = [];
      playerData['endorsementIds'] = [];
      playerData['finances'] = {
        'currentSeasonEarnings': 0.0,
        'careerEarnings': 0.0,
        'endorsementEarnings': 0.0,
        'contractEarnings': 0.0,
        'yearlyEarnings': [],
        'recentTransactions': []
      };
      
      await _firestore.collection('players').doc(id).set(playerData);
      
      // Create contracts for this player
      final contractIds = await _createContractsForMultiplePlayers(id);
      
      // Create endorsements for this player
      final endorsementIds = await _createEndorsementsForMultiplePlayers(id);
      
      // Create transactions for this player
      await _createTransactionsForMultiplePlayers(id);
      
      // Update player with contract and endorsement IDs
      await _firestore.collection('players').doc(id).update({
        'contractIds': contractIds,
        'endorsementIds': endorsementIds,
      });
      
      print('Seeded player: ${player['firstName']} ${player['lastName']}');
    }
    
    print('Successfully seeded ${players.length} players');
  }

  Future<List<String>> _createContractsForMultiplePlayers(String userId) async {
    // Different contract data for each player based on their team/position
    final contracts = <Map<String, dynamic>>[];
    
    switch (userId) {
      case 'player_michael_johnson':
        contracts.addAll([
          {
            'userId': userId,
            'type': 'player',
            'title': 'NBA Player Contract - Brooklyn Nets',
            'description': 'Star point guard contract with performance incentives',
            'annualValue': 15000000.0,
            'startDate': Timestamp.fromDate(DateTime(2023, 10, 1)),
            'endDate': Timestamp.fromDate(DateTime(2026, 9, 30)),
            'status': 'active',
            'documentUrl': 'https://example.com/contracts/contract_001.pdf',
            'incentives': [
              'All-Star selection: \$500,000',
              'Playoff appearance: \$250,000',
              'Conference Finals: \$500,000',
              'NBA Finals: \$1,000,000',
              'MVP: \$2,000,000'
            ],
            'terms': {
              'guaranteed': true,
              'teamOption': false,
              'playerOption': true,
              'noTradeClause': false
            },
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
        ]);
        break;
        
      case 'player_sarah_williams':
        contracts.addAll([
          {
            'userId': userId,
            'type': 'player',
            'title': 'NBA Player Contract - Los Angeles Lakers',
            'description': 'Shooting guard contract with championship incentives',
            'annualValue': 10000000.0,
            'startDate': Timestamp.fromDate(DateTime(2023, 10, 1)),
            'endDate': Timestamp.fromDate(DateTime(2025, 9, 30)),
            'status': 'active',
            'documentUrl': 'https://example.com/contracts/contract_002.pdf',
            'incentives': [
              'Championship: \$1,000,000',
              'All-Star selection: \$300,000',
              'Playoff appearance: \$200,000'
            ],
            'terms': {
              'guaranteed': true,
              'teamOption': true,
              'playerOption': false,
              'noTradeClause': false
            },
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
        ]);
        break;
        
      case 'player_james_rodriguez':
        contracts.addAll([
          {
            'userId': userId,
            'type': 'player',
            'title': 'NBA Player Contract - Miami Heat',
            'description': 'Power forward contract with rebounding incentives',
            'annualValue': 12000000.0,
            'startDate': Timestamp.fromDate(DateTime(2023, 10, 1)),
            'endDate': Timestamp.fromDate(DateTime(2027, 9, 30)),
            'status': 'active',
            'documentUrl': 'https://example.com/contracts/contract_003.pdf',
            'incentives': [
              'Double-double average: \$500,000',
              'All-Star selection: \$400,000',
              'Defensive Player of the Year: \$1,000,000'
            ],
            'terms': {
              'guaranteed': true,
              'teamOption': false,
              'playerOption': false,
              'noTradeClause': false
            },
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
        ]);
        break;
        
      case 'player_emma_davis':
        contracts.addAll([
          {
            'userId': userId,
            'type': 'player',
            'title': 'NBA Player Contract - Golden State Warriors',
            'description': 'Small forward contract with shooting incentives',
            'annualValue': 8000000.0,
            'startDate': Timestamp.fromDate(DateTime(2023, 10, 1)),
            'endDate': Timestamp.fromDate(DateTime(2025, 9, 30)),
            'status': 'active',
            'documentUrl': 'https://example.com/contracts/contract_004.pdf',
            'incentives': [
              '40% 3-point shooting: \$300,000',
              'All-Star selection: \$250,000',
              'Most Improved Player: \$500,000'
            ],
            'terms': {
              'guaranteed': true,
              'teamOption': true,
              'playerOption': false,
              'noTradeClause': false
            },
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
        ]);
        break;
        
      case 'player_david_chen':
        contracts.addAll([
          {
            'userId': userId,
            'type': 'player',
            'title': 'NBA Player Contract - Boston Celtics',
            'description': 'Center contract with defensive incentives',
            'annualValue': 9000000.0,
            'startDate': Timestamp.fromDate(DateTime(2023, 10, 1)),
            'endDate': Timestamp.fromDate(DateTime(2026, 9, 30)),
            'status': 'active',
            'documentUrl': 'https://example.com/contracts/contract_005.pdf',
            'incentives': [
              '10+ rebounds per game: \$400,000',
              '2+ blocks per game: \$300,000',
              'All-Defensive Team: \$500,000'
            ],
            'terms': {
              'guaranteed': true,
              'teamOption': false,
              'playerOption': true,
              'noTradeClause': false
            },
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
        ]);
        break;
    }

    final contractIds = <String>[];
    for (final contract in contracts) {
      final docRef = await _firestore.collection('contracts').add(contract);
      contractIds.add(docRef.id);
    }

    return contractIds;
  }

  Future<List<String>> _createEndorsementsForMultiplePlayers(String userId) async {
    // Different endorsement data for each player
    final endorsements = <Map<String, dynamic>>[];
    
    switch (userId) {
      case 'player_michael_johnson':
        endorsements.addAll([
          {
            'userId': userId,
            'brandName': 'Nike',
            'category': 'Athletic Wear',
            'description': 'Exclusive shoe and apparel endorsement deal',
            'value': 2500000.0,
            'duration': '3 years',
            'status': 'active',
            'imageUrl': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=300&h=200&fit=crop',
            'requirements': [
              'Wear Nike shoes during all games',
              'Attend 4 promotional events per year',
              'Social media posts (2 per month)',
              'Appear in 2 commercials per year'
            ],
            'startDate': Timestamp.fromDate(DateTime(2023, 1, 1)),
            'endDate': Timestamp.fromDate(DateTime(2025, 12, 31)),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          {
            'userId': userId,
            'brandName': 'Gatorade',
            'category': 'Beverages',
            'description': 'Official sports drink endorsement',
            'value': 1200000.0,
            'duration': '2 years',
            'status': 'active',
            'imageUrl': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300&h=200&fit=crop',
            'requirements': [
              'Use Gatorade during games and practices',
              'Appear in 2 commercials',
              'Social media posts (1 per month)',
              'Attend 2 promotional events per year'
            ],
            'startDate': Timestamp.fromDate(DateTime(2023, 6, 1)),
            'endDate': Timestamp.fromDate(DateTime(2025, 5, 31)),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
        ]);
        break;
        
      case 'player_sarah_williams':
        endorsements.addAll([
          {
            'userId': userId,
            'brandName': 'Adidas',
            'category': 'Athletic Wear',
            'description': 'Apparel and footwear endorsement',
            'value': 1000000.0,
            'duration': '2 years',
            'status': 'active',
            'imageUrl': 'https://images.unsplash.com/photo-1543508282-6319a3e2621f?w=300&h=200&fit=crop',
            'requirements': [
              'Wear Adidas apparel during games',
              'Attend 3 promotional events per year',
              'Social media posts (3 per month)',
              'Appear in 1 commercial per year'
            ],
            'startDate': Timestamp.fromDate(DateTime(2023, 3, 1)),
            'endDate': Timestamp.fromDate(DateTime(2025, 2, 28)),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
        ]);
        break;
        
      case 'player_james_rodriguez':
        endorsements.addAll([
          {
            'userId': userId,
            'brandName': 'Under Armour',
            'category': 'Athletic Wear',
            'description': 'Performance apparel endorsement',
            'value': 800000.0,
            'duration': '3 years',
            'status': 'active',
            'imageUrl': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=300&h=200&fit=crop',
            'requirements': [
              'Wear Under Armour during games',
              'Attend 2 promotional events per year',
              'Social media posts (2 per month)'
            ],
            'startDate': Timestamp.fromDate(DateTime(2023, 2, 1)),
            'endDate': Timestamp.fromDate(DateTime(2026, 1, 31)),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
        ]);
        break;
        
      case 'player_emma_davis':
        endorsements.addAll([
          {
            'userId': userId,
            'brandName': 'Puma',
            'category': 'Athletic Wear',
            'description': 'Shoe and apparel endorsement',
            'value': 600000.0,
            'duration': '2 years',
            'status': 'active',
            'imageUrl': 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=300&h=200&fit=crop',
            'requirements': [
              'Wear Puma shoes during games',
              'Attend 2 promotional events per year',
              'Social media posts (1 per month)'
            ],
            'startDate': Timestamp.fromDate(DateTime(2023, 4, 1)),
            'endDate': Timestamp.fromDate(DateTime(2025, 3, 31)),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
        ]);
        break;
        
      case 'player_david_chen':
        endorsements.addAll([
          {
            'userId': userId,
            'brandName': 'New Balance',
            'category': 'Athletic Wear',
            'description': 'Footwear endorsement deal',
            'value': 400000.0,
            'duration': '2 years',
            'status': 'active',
            'imageUrl': 'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=300&h=200&fit=crop',
            'requirements': [
              'Wear New Balance shoes during games',
              'Attend 1 promotional event per year',
              'Social media posts (1 per month)'
            ],
            'startDate': Timestamp.fromDate(DateTime(2023, 5, 1)),
            'endDate': Timestamp.fromDate(DateTime(2025, 4, 30)),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
        ]);
        break;
    }

    final endorsementIds = <String>[];
    for (final endorsement in endorsements) {
      final docRef = await _firestore.collection('endorsements').add(endorsement);
      endorsementIds.add(docRef.id);
    }

    return endorsementIds;
  }

  Future<void> _createTransactionsForMultiplePlayers(String userId) async {
    // Different transaction data for each player based on their contracts/endorsements
    final transactions = <Map<String, dynamic>>[];
    
    switch (userId) {
      case 'player_michael_johnson':
        transactions.addAll([
          {
            'userId': userId,
            'description': 'Monthly salary payment - Brooklyn Nets',
            'amount': 1250000.0,
            'type': 'income',
            'category': 'salary',
            'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
            'status': 'completed'
          },
          {
            'userId': userId,
            'description': 'Nike quarterly endorsement payment',
            'amount': 625000.0,
            'type': 'income',
            'category': 'endorsement',
            'date': Timestamp.fromDate(DateTime(2024, 1, 10)),
            'status': 'completed'
          },
          {
            'userId': userId,
            'description': 'Gatorade monthly endorsement payment',
            'amount': 100000.0,
            'type': 'income',
            'category': 'endorsement',
            'date': Timestamp.fromDate(DateTime(2024, 1, 5)),
            'status': 'completed'
          }
        ]);
        break;
        
      case 'player_sarah_williams':
        transactions.addAll([
          {
            'userId': userId,
            'description': 'Monthly salary payment - Los Angeles Lakers',
            'amount': 833333.0,
            'type': 'income',
            'category': 'salary',
            'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
            'status': 'completed'
          },
          {
            'userId': userId,
            'description': 'Adidas quarterly endorsement payment',
            'amount': 250000.0,
            'type': 'income',
            'category': 'endorsement',
            'date': Timestamp.fromDate(DateTime(2024, 1, 10)),
            'status': 'completed'
          }
        ]);
        break;
        
      case 'player_james_rodriguez':
        transactions.addAll([
          {
            'userId': userId,
            'description': 'Monthly salary payment - Miami Heat',
            'amount': 1000000.0,
            'type': 'income',
            'category': 'salary',
            'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
            'status': 'completed'
          },
          {
            'userId': userId,
            'description': 'Under Armour quarterly endorsement payment',
            'amount': 200000.0,
            'type': 'income',
            'category': 'endorsement',
            'date': Timestamp.fromDate(DateTime(2024, 1, 10)),
            'status': 'completed'
          }
        ]);
        break;
        
      case 'player_emma_davis':
        transactions.addAll([
          {
            'userId': userId,
            'description': 'Monthly salary payment - Golden State Warriors',
            'amount': 666667.0,
            'type': 'income',
            'category': 'salary',
            'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
            'status': 'completed'
          },
          {
            'userId': userId,
            'description': 'Puma quarterly endorsement payment',
            'amount': 150000.0,
            'type': 'income',
            'category': 'endorsement',
            'date': Timestamp.fromDate(DateTime(2024, 1, 10)),
            'status': 'completed'
          }
        ]);
        break;
        
      case 'player_david_chen':
        transactions.addAll([
          {
            'userId': userId,
            'description': 'Monthly salary payment - Boston Celtics',
            'amount': 750000.0,
            'type': 'income',
            'category': 'salary',
            'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
            'status': 'completed'
          },
          {
            'userId': userId,
            'description': 'New Balance quarterly endorsement payment',
            'amount': 100000.0,
            'type': 'income',
            'category': 'endorsement',
            'date': Timestamp.fromDate(DateTime(2024, 1, 10)),
            'status': 'completed'
          }
        ]);
        break;
    }

    for (final transaction in transactions) {
      await _firestore.collection('transactions').add(transaction);
    }
  }

  Future<void> seedAvailableEndorsements() async {
    try {
      final availableEndorsements = [
        {
          'userId': '', // Empty for available endorsements
          'brandName': 'Coca-Cola',
          'category': 'Beverages',
          'description': 'Global beverage brand looking for NBA player ambassador',
          'value': 800000.0,
          'duration': '2 years',
          'status': 'available',
          'imageUrl': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300&h=200&fit=crop',
          'requirements': [
            'Appear in 3 commercials per year',
            'Social media posts (4 per month)',
            'Attend 5 promotional events per year',
            'Minimum 15 points per game average'
          ],
          'startDate': null, // Will be set when applied
          'endDate': null, // Will be set when applied
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': '',
          'brandName': 'McDonald\'s',
          'category': 'Food & Beverage',
          'description': 'Fast food chain seeking NBA player for marketing campaign',
          'value': 600000.0,
          'duration': '1 year',
          'status': 'available',
          'imageUrl': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=300&h=200&fit=crop',
          'requirements': [
            'Appear in 2 commercials',
            'Social media posts (2 per month)',
            'Attend 3 promotional events',
            'Minimum 10 points per game average'
          ],
          'startDate': null,
          'endDate': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': '',
          'brandName': 'Samsung',
          'category': 'Electronics',
          'description': 'Electronics giant looking for tech-savvy NBA player',
          'value': 1200000.0,
          'duration': '3 years',
          'status': 'available',
          'imageUrl': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=300&h=200&fit=crop',
          'requirements': [
            'Appear in 4 commercials per year',
            'Social media posts (6 per month)',
            'Attend 6 promotional events per year',
            'Minimum 20 points per game average',
            'Active social media presence'
          ],
          'startDate': null,
          'endDate': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': '',
          'brandName': 'State Farm',
          'category': 'Insurance',
          'description': 'Insurance company seeking reliable NBA player',
          'value': 900000.0,
          'duration': '2 years',
          'status': 'available',
          'imageUrl': 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=300&h=200&fit=crop',
          'requirements': [
            'Appear in 3 commercials per year',
            'Social media posts (3 per month)',
            'Attend 4 promotional events per year',
            'Clean public image',
            'Minimum 15 points per game average'
          ],
          'startDate': null,
          'endDate': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': '',
          'brandName': 'T-Mobile',
          'category': 'Telecommunications',
          'description': 'Mobile carrier looking for NBA player ambassador',
          'value': 750000.0,
          'duration': '2 years',
          'status': 'available',
          'imageUrl': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300&h=200&fit=crop',
          'requirements': [
            'Appear in 2 commercials per year',
            'Social media posts (4 per month)',
            'Attend 3 promotional events per year',
            'Active on social media',
            'Minimum 12 points per game average'
          ],
          'startDate': null,
          'endDate': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }
      ];

      for (final endorsement in availableEndorsements) {
        await _firestore.collection('endorsements').add(endorsement);
      }

      print('Successfully seeded ${availableEndorsements.length} available endorsements');
    } catch (e) {
      print('Error seeding available endorsements: $e');
    }
  }

  Future<void> seedAllData() async {
    try {
      print('Starting to seed all data...');
      
      // Seed available endorsements first
      await seedAvailableEndorsements();
      
      // Seed multiple players
      await seedMultiplePlayers();
      
      print('Successfully seeded all data!');
    } catch (e) {
      print('Error seeding all data: $e');
    }
  }
} 