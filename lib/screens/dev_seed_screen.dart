import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/seed_service.dart';
import '../theme.dart';

class DevSeedScreen extends StatefulWidget {
  const DevSeedScreen({super.key});

  @override
  State<DevSeedScreen> createState() => _DevSeedScreenState();
}

class _DevSeedScreenState extends State<DevSeedScreen> {
  bool _isSeeding = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Development - Seed Data'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Database Seeding',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will populate the database with sample data including players, contracts, endorsements, and transactions.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What will be created:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildSeedItem('5 NBA Players with realistic stats'),
                    _buildSeedItem('Multiple contracts per player'),
                    _buildSeedItem('Various endorsement deals'),
                    _buildSeedItem('Financial transactions'),
                    _buildSeedItem('5 available endorsements to apply for'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSeeding ? null : _seedAllData,
              icon: _isSeeding 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.grass),
              label: Text(_isSeeding ? 'Seeding Data...' : 'Seed All Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _status.contains('Error') 
                    ? AppColors.danger.withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _status.contains('Error') 
                      ? AppColors.danger.withOpacity(0.3)
                      : AppColors.success.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _status.contains('Error') 
                      ? AppColors.danger
                      : AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const Spacer(),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Development Notes:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• This creates realistic NBA player data\n'
                      '• Contracts include performance incentives\n'
                      '• Endorsements have varying requirements\n'
                      '• Financial calculations are automatic\n'
                      '• Available endorsements can be applied for',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedAllData() async {
    setState(() {
      _isSeeding = true;
      _status = 'Starting to seed data...';
    });

    try {
      final seedService = Provider.of<SeedService>(context, listen: false);
      
      setState(() {
        _status = 'Creating available endorsements...';
      });
      await seedService.seedAvailableEndorsements();
      
      setState(() {
        _status = 'Creating players and their data...';
      });
      await seedService.seedMultiplePlayers();
      
      setState(() {
        _status = 'Successfully seeded all data! The database now contains:\n'
                '• 5 NBA players with realistic stats\n'
                '• Multiple contracts per player\n'
                '• Various endorsement deals\n'
                '• Financial transactions\n'
                '• 5 available endorsements to apply for';
        _isSeeding = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error seeding data: $e';
        _isSeeding = false;
      });
    }
  }
} 