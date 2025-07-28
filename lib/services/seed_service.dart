import 'package:cloud_firestore/cloud_firestore.dart';
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

      // Sample player data
      final playerData = {
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
        'status': 'active',
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
        'contracts': [
          {
            'id': 'contract_001',
            'team': 'Brooklyn Nets',
            'type': 'Player Contract',
            'startDate': Timestamp.fromDate(DateTime(2023, 10, 1)),
            'endDate': Timestamp.fromDate(DateTime(2026, 9, 30)),
            'totalValue': 45000000,
            'annualSalary': 15000000,
            'status': 'active',
            'documentUrl': 'https://example.com/contracts/contract_001.pdf'
          }
        ],
        'endorsements': [
          {
            'id': 'endorsement_001',
            'brand': 'Nike',
            'category': 'Athletic Wear',
            'type': 'Shoe Deal',
            'startDate': Timestamp.fromDate(DateTime(2023, 1, 1)),
            'endDate': Timestamp.fromDate(DateTime(2025, 12, 31)),
            'totalValue': 5000000,
            'annualValue': 2500000,
            'status': 'active',
            'requirements': [
              'Wear Nike shoes during games',
              'Attend 4 promotional events per year',
              'Social media posts (2 per month)'
            ]
          },
          {
            'id': 'endorsement_002',
            'brand': 'Gatorade',
            'category': 'Beverages',
            'type': 'Beverage Deal',
            'startDate': Timestamp.fromDate(DateTime(2023, 6, 1)),
            'endDate': Timestamp.fromDate(DateTime(2024, 5, 31)),
            'totalValue': 1200000,
            'annualValue': 1200000,
            'status': 'active',
            'requirements': [
              'Use Gatorade during games',
              'Appear in 2 commercials',
              'Social media posts (1 per month)'
            ]
          }
        ],
        'finances': {
          'currentSeasonEarnings': 16250000,
          'careerEarnings': 45000000,
          'endorsementEarnings': 3700000,
          'contractEarnings': 15000000,
          'yearlyEarnings': [
            {
              'year': 2023,
              'contractEarnings': 15000000,
              'endorsementEarnings': 3700000,
              'totalEarnings': 18700000
            },
            {
              'year': 2022,
              'contractEarnings': 12000000,
              'endorsementEarnings': 2800000,
              'totalEarnings': 14800000
            },
            {
              'year': 2021,
              'contractEarnings': 8000000,
              'endorsementEarnings': 1500000,
              'totalEarnings': 9500000
            }
          ],
          'recentTransactions': [
            {
              'id': 'txn_001',
              'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
              'type': 'salary',
              'description': 'Monthly salary payment',
              'amount': 1250000,
              'category': 'Contract'
            },
            {
              'id': 'txn_002',
              'date': Timestamp.fromDate(DateTime(2024, 1, 10)),
              'type': 'endorsement',
              'description': 'Nike quarterly payment',
              'amount': 625000,
              'category': 'Endorsement'
            },
            {
              'id': 'txn_003',
              'date': Timestamp.fromDate(DateTime(2024, 1, 5)),
              'type': 'endorsement',
              'description': 'Gatorade monthly payment',
              'amount': 100000,
              'category': 'Endorsement'
            }
          ]
        }
      };

      // Add the data to Firestore
      await _firestore.collection('players').doc(userId).set(playerData);
      print('Successfully seeded player data for user: $userId');
    } catch (e) {
      print('Error seeding player data: $e');
    }
  }

  Future<void> seedMultiplePlayers() async {
    final players = [
      {
        'id': 'sample_player_1',
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
        'status': 'active',
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
        'contracts': [
          {
            'id': 'contract_001',
            'team': 'Brooklyn Nets',
            'type': 'Player Contract',
            'startDate': Timestamp.fromDate(DateTime(2023, 10, 1)),
            'endDate': Timestamp.fromDate(DateTime(2026, 9, 30)),
            'totalValue': 45000000,
            'annualSalary': 15000000,
            'status': 'active',
            'documentUrl': 'https://example.com/contracts/contract_001.pdf'
          }
        ],
        'endorsements': [
          {
            'id': 'endorsement_001',
            'brand': 'Nike',
            'category': 'Athletic Wear',
            'type': 'Shoe Deal',
            'startDate': Timestamp.fromDate(DateTime(2023, 1, 1)),
            'endDate': Timestamp.fromDate(DateTime(2025, 12, 31)),
            'totalValue': 5000000,
            'annualValue': 2500000,
            'status': 'active',
            'requirements': [
              'Wear Nike shoes during games',
              'Attend 4 promotional events per year',
              'Social media posts (2 per month)'
            ]
          }
        ],
        'finances': {
          'currentSeasonEarnings': 16250000,
          'careerEarnings': 45000000,
          'endorsementEarnings': 3700000,
          'contractEarnings': 15000000,
          'yearlyEarnings': [
            {
              'year': 2023,
              'contractEarnings': 15000000,
              'endorsementEarnings': 3700000,
              'totalEarnings': 18700000
            }
          ],
          'recentTransactions': [
            {
              'id': 'txn_001',
              'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
              'type': 'salary',
              'description': 'Monthly salary payment',
              'amount': 1250000,
              'category': 'Contract'
            }
          ]
        }
      },
      {
        'id': 'sample_player_2',
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
        'status': 'active',
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
        },
        'contracts': [
          {
            'id': 'contract_002',
            'team': 'Los Angeles Lakers',
            'type': 'Player Contract',
            'startDate': Timestamp.fromDate(DateTime(2023, 10, 1)),
            'endDate': Timestamp.fromDate(DateTime(2025, 9, 30)),
            'totalValue': 20000000,
            'annualSalary': 10000000,
            'status': 'active',
            'documentUrl': 'https://example.com/contracts/contract_002.pdf'
          }
        ],
        'endorsements': [
          {
            'id': 'endorsement_003',
            'brand': 'Adidas',
            'category': 'Athletic Wear',
            'type': 'Apparel Deal',
            'startDate': Timestamp.fromDate(DateTime(2023, 3, 1)),
            'endDate': Timestamp.fromDate(DateTime(2026, 2, 28)),
            'totalValue': 3000000,
            'annualValue': 1000000,
            'status': 'active',
            'requirements': [
              'Wear Adidas apparel during games',
              'Attend 3 promotional events per year',
              'Social media posts (3 per month)'
            ]
          }
        ],
        'finances': {
          'currentSeasonEarnings': 11000000,
          'careerEarnings': 20000000,
          'endorsementEarnings': 1000000,
          'contractEarnings': 10000000,
          'yearlyEarnings': [
            {
              'year': 2023,
              'contractEarnings': 10000000,
              'endorsementEarnings': 1000000,
              'totalEarnings': 11000000
            }
          ],
          'recentTransactions': [
            {
              'id': 'txn_004',
              'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
              'type': 'salary',
              'description': 'Monthly salary payment',
              'amount': 833333,
              'category': 'Contract'
            }
          ]
        }
      }
    ];

    for (final player in players) {
      final id = player['id'] as String;
      final playerData = Map<String, dynamic>.from(player);
      playerData.remove('id'); // Remove the id from the data since it's the document ID
      
      await _firestore.collection('players').doc(id).set(playerData);
      print('Seeded player: ${player['firstName']} ${player['lastName']}');
    }
    
    print('Successfully seeded ${players.length} players');
  }
} 