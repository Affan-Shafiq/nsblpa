import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../services/seed_service.dart';
import '../services/auth_service.dart';

class DevSeedScreen extends StatelessWidget {
  const DevSeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Development Tools'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Development & Testing Tools',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Seed Data Section
            _buildSection(
              context,
              'Seed Data',
              [
                _buildActionCard(
                  'Seed Sample Player Data',
                  'Create sample player data for current user',
                  Icons.person_add,
                  () async {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final seedService = SeedService();
                    if (authService.user != null) {
                      await seedService.seedPlayerData(authService.user!.uid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sample player data seeded successfully!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
                _buildActionCard(
                  'Seed Multiple Players',
                  'Create multiple sample players for testing',
                  Icons.group_add,
                  () async {
                    final seedService = SeedService();
                    await seedService.seedMultiplePlayers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Multiple players seeded successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  'Create Admin User',
                  'Make current user an admin (for testing)',
                  Icons.admin_panel_settings,
                  () async {
                    await _createAdminUser(context);
                  },
                ),
                _buildActionCard(
                  'Seed Sample Endorsements',
                  'Create sample endorsement opportunities',
                  Icons.star,
                  () async {
                    await _seedSampleEndorsements();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sample endorsements seeded successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Database Management Section
            _buildSection(
              context,
              'Database Management',
              [
                _buildActionCard(
                  'Clear All Data',
                  'Delete all data (use with caution)',
                  Icons.delete_forever,
                  () async {
                    await _showClearDataDialog(context);
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppColors.danger : AppColors.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.danger : null,
          ),
        ),
        subtitle: Text(description),
        trailing: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? AppColors.danger : AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Execute'),
        ),
      ),
    );
  }

  Future<void> _createAdminUser(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    try {
      // Update the user's role to admin
      await FirebaseFirestore.instance
          .collection('players')
          .where('userId', isEqualTo: user.uid)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          querySnapshot.docs.first.reference.update({'role': 'admin'});
        } else {
          // Create admin user if doesn't exist
          FirebaseFirestore.instance.collection('players').add({
            'userId': user.uid,
            'firstName': user.displayName?.split(' ').first ?? 'Admin',
            'lastName': user.displayName?.split(' ').last ?? 'User',
            'email': user.email,
            'profileImageUrl': user.photoURL,
            'team': 'NSBLPA',
            'position': 'Administrator',
            'jerseyNumber': 0,
            'dateOfBirth': DateTime(1990, 1, 1).toIso8601String(),
            'nationality': 'Admin',
            'stats': {
              'gamesPlayed': 0,
              'pointsPerGame': 0.0,
              'reboundsPerGame': 0.0,
              'assistsPerGame': 0.0,
              'stealsPerGame': 0.0,
              'blocksPerGame': 0.0,
              'fieldGoalPercentage': 0.0,
              'threePointPercentage': 0.0,
              'freeThrowPercentage': 0.0,
              'totalPoints': 0,
              'totalRebounds': 0,
              'totalAssists': 0,
            },
            'contractIds': [],
            'endorsementIds': [],
            'finances': {
              'currentSeasonEarnings': 0.0,
              'careerEarnings': 0.0,
              'endorsementEarnings': 0.0,
              'contractEarnings': 0.0,
              'yearlyEarnings': [],
              'recentTransactions': [],
            },
            'memberSince': FieldValue.serverTimestamp(),
            'role': 'admin',
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User role updated to admin successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating admin user: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _seedSampleEndorsements() async {
    final sampleEndorsements = [
      {
        'userId': '', // Empty for available endorsements
        'brandName': 'Nike',
        'category': 'Sports Equipment',
        'description': 'Official footwear and apparel partnership for the upcoming season.',
        'value': 500000.0,
        'duration': '2 years',
        'status': 'available',
        'imageUrl': null,
        'requirements': ['Active player status', 'Minimum 15 games played', 'Social media presence'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': '',
        'brandName': 'Gatorade',
        'category': 'Beverages',
        'description': 'Hydration and sports drink endorsement deal.',
        'value': 250000.0,
        'duration': '1 year',
        'status': 'available',
        'imageUrl': null,
        'requirements': ['Team endorsement', 'Game day appearances'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': '',
        'brandName': 'Under Armour',
        'category': 'Sports Equipment',
        'description': 'Performance wear and training gear partnership.',
        'value': 350000.0,
        'duration': '3 years',
        'status': 'available',
        'imageUrl': null,
        'requirements': ['Exclusive brand partnership', 'Training camp participation'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': '',
        'brandName': 'McDonald\'s',
        'category': 'Food & Beverages',
        'description': 'Local restaurant chain endorsement and promotional appearances.',
        'value': 150000.0,
        'duration': '1 year',
        'status': 'available',
        'imageUrl': null,
        'requirements': ['Local market appeal', 'Community involvement'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': '',
        'brandName': 'Beats by Dre',
        'category': 'Electronics',
        'description': 'Headphones and audio equipment endorsement.',
        'value': 200000.0,
        'duration': '2 years',
        'status': 'available',
        'imageUrl': null,
        'requirements': ['Social media promotion', 'Product integration'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = FirebaseFirestore.instance.batch();
    
    for (final endorsement in sampleEndorsements) {
      final docRef = FirebaseFirestore.instance.collection('endorsements').doc();
      batch.set(docRef, endorsement);
    }
    
    await batch.commit();
  }

  Future<void> _showClearDataDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete ALL data from the database. This action cannot be undone. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    // Clear players
    final playersSnapshot = await FirebaseFirestore.instance.collection('players').get();
    final batch1 = FirebaseFirestore.instance.batch();
    for (final doc in playersSnapshot.docs) {
      batch1.delete(doc.reference);
    }
    await batch1.commit();

    // Clear endorsements
    final endorsementsSnapshot = await FirebaseFirestore.instance.collection('endorsements').get();
    final batch2 = FirebaseFirestore.instance.batch();
    for (final doc in endorsementsSnapshot.docs) {
      batch2.delete(doc.reference);
    }
    await batch2.commit();

    // Clear contracts
    final contractsSnapshot = await FirebaseFirestore.instance.collection('contracts').get();
    final batch3 = FirebaseFirestore.instance.batch();
    for (final doc in contractsSnapshot.docs) {
      batch3.delete(doc.reference);
    }
    await batch3.commit();
  }
} 