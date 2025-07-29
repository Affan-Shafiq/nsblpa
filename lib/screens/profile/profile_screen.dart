import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../services/player_service.dart';
import '../../models/player.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _teamController;
  late TextEditingController _positionController;
  late TextEditingController _jerseyNumberController;
  late TextEditingController _nationalityController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _teamController = TextEditingController();
    _positionController = TextEditingController();
    _jerseyNumberController = TextEditingController();
    _nationalityController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _teamController.dispose();
    _positionController.dispose();
    _jerseyNumberController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  void _populateControllers(Player player) {
    _firstNameController.text = player.firstName;
    _lastNameController.text = player.lastName;
    _teamController.text = player.team;
    _positionController.text = player.position;
    _jerseyNumberController.text = player.jerseyNumber.toString();
    _nationalityController.text = player.nationality;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final playerService = Provider.of<PlayerService>(context, listen: false);
    final jerseyNumber = int.tryParse(_jerseyNumberController.text) ?? 0;

    await playerService.updatePlayerProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      team: _teamController.text.trim(),
      position: _positionController.text.trim(),
      jerseyNumber: jerseyNumber,
      nationality: _nationalityController.text.trim(),
    );

    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          Consumer<PlayerService>(
            builder: (context, playerService, child) {
              final player = playerService.currentPlayer;
              if (player == null) return const SizedBox.shrink();

              if (_isEditing) {
                return Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _populateControllers(player);
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: _saveProfile,
                      child: const Text('Save'),
                    ),
                  ],
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _populateControllers(player);
                    });
                  },
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<PlayerService>(
        builder: (context, playerService, child) {
          if (playerService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final player = playerService.currentPlayer;
          if (player == null) {
            return const Center(child: Text('No player data available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _buildProfileHeader(player),
                  const SizedBox(height: 24),

                  // Personal Information
                  _buildPersonalInfo(player),
                  const SizedBox(height: 24),

                  // Player Stats
                  _buildPlayerStats(player),
                  const SizedBox(height: 24),

                  // Career Information
                  _buildCareerInfo(player),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Player player) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 65,
                  backgroundColor: AppColors.primary,
                  backgroundImage: player.profileImageUrl != null
                      ? NetworkImage(player.profileImageUrl!)
                      : null,
                  child: player.profileImageUrl == null
                      ? Text(
                          player.firstName[0] + player.lastName[0],
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              player.fullName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${player.position} • ${player.team}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.subtitle,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Jersey #${player.jerseyNumber}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(Player player) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nationalityController,
                decoration: const InputDecoration(
                  labelText: 'Nationality',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your nationality';
                  }
                  return null;
                },
              ),
            ] else ...[
              _buildInfoRow('Full Name', player.fullName),
              _buildInfoRow('Email', player.email),
              _buildInfoRow('Nationality', player.nationality),
              _buildInfoRow('Date of Birth', DateFormat('MMMM dd, yyyy').format(player.dateOfBirth)),
              _buildInfoRow('Age', '${player.age} years old'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStats(Player player) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_basketball, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Season Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.4,
              children: [
                _buildStatItem('Games Played', player.stats.gamesPlayed.toString()),
                _buildStatItem('Points Per Game', player.stats.pointsPerGame.toStringAsFixed(1)),
                _buildStatItem('Rebounds Per Game', player.stats.reboundsPerGame.toStringAsFixed(1)),
                _buildStatItem('Assists Per Game', player.stats.assistsPerGame.toStringAsFixed(1)),
                _buildStatItem('Steals Per Game', player.stats.stealsPerGame.toStringAsFixed(1)),
                _buildStatItem('Blocks Per Game', player.stats.blocksPerGame.toStringAsFixed(1)),
                _buildStatItem('FG%', '${player.stats.fieldGoalPercentage.toStringAsFixed(1)}%'),
                _buildStatItem('3P%', '${player.stats.threePointPercentage.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerInfo(Player player) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Career Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _teamController,
                      decoration: const InputDecoration(
                        labelText: 'Team',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your team';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _positionController,
                      decoration: const InputDecoration(
                        labelText: 'Position',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your position';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jerseyNumberController,
                decoration: const InputDecoration(
                  labelText: 'Jersey Number',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your jersey number';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ] else ...[
              _buildInfoRow('Team', player.team),
              _buildInfoRow('Position', player.position),
              _buildInfoRow('Jersey Number', '#${player.jerseyNumber}'),
              _buildInfoRow('Member Since', DateFormat('MMMM yyyy').format(player.memberSince)),
              _buildInfoRow('Active Contracts', player.contractIds.length.toString()),
              _buildInfoRow('Active Endorsements', player.endorsementIds.length.toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.subtitle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.subtitle.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.subtitle,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
} 