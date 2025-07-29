import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../services/player_service.dart';
import '../../services/auth_service.dart';
import '../../services/seed_service.dart';
import '../../models/player.dart';
import '../../widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load player data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerService = Provider.of<PlayerService>(context, listen: false);
      if (playerService.currentPlayer == null) {
        playerService.updateAuth(Provider.of<AuthService>(context, listen: false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<PlayerService>(
        builder: (context, playerService, child) {
          if (playerService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final player = playerService.currentPlayer;
          if (player == null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.primary,
                title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await Provider.of<AuthService>(context, listen: false).signOut();
                      if (mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_off, size: 64, color: AppColors.subtitle),
                    const SizedBox(height: 16),
                    const Text(
                      'No player data available',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.subtitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please contact support to set up your profile',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.subtitle,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        final seedService = SeedService();
                        if (authService.user != null) {
                          await seedService.seedPlayerData(authService.user!.uid);
                          // Refresh player data
                          final playerService = Provider.of<PlayerService>(context, listen: false);
                          playerService.updateAuth(authService);
                        }
                      },
                      icon: const Icon(Icons.data_usage),
                      label: const Text('Seed Sample Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () async {
                        final seedService = SeedService();
                        await seedService.seedMultiplePlayers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sample players seeded successfully!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.group_add),
                      label: const Text('Seed Multiple Players'),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Welcome, ${player.firstName}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, Color(0xFF1565C0)],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await Provider.of<AuthService>(context, listen: false).signOut();
                      if (mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Player Profile Card
                    _buildPlayerProfileCard(player),
                    const SizedBox(height: 20),

                    // Quick Stats
                    _buildQuickStats(player),
                    const SizedBox(height: 20),

                    // Financial Overview
                    _buildFinancialOverview(player),
                    const SizedBox(height: 20),

                    // Recent Activity
                    _buildRecentActivity(player),
                    const SizedBox(height: 20),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 20),

                    // Union Updates
                    _buildUnionUpdates(),
                    const SizedBox(height: 40), // Bottom padding
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerProfileCard(Player player) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: AppColors.primary,
              backgroundImage: player.profileImageUrl != null
                  ? NetworkImage(player.profileImageUrl!)
                  : null,
              child: player.profileImageUrl == null
                  ? Text(
                      _getInitials(player.firstName, player.lastName),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${player.position} • ${player.team} • #${player.jerseyNumber}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.subtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.subtitle),
                      const SizedBox(width: 6),
                      Text(
                        'Member since ${DateFormat('MMM yyyy').format(player.memberSince)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                Navigator.of(context).pushNamed('/profile');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(Player player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Season Stats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            StatTile(
              label: 'Games Played',
              value: player.stats.gamesPlayed.toString(),
              icon: Icons.sports_basketball,
              color: AppColors.primary,
            ),
            StatTile(
              label: 'Points Per Game',
              value: player.stats.pointsPerGame.toStringAsFixed(1),
              icon: Icons.trending_up,
              color: AppColors.success,
            ),
            StatTile(
              label: 'Rebounds Per Game',
              value: player.stats.reboundsPerGame.toStringAsFixed(1),
              icon: Icons.height,
              color: AppColors.accent,
            ),
            StatTile(
              label: 'Assists Per Game',
              value: player.stats.assistsPerGame.toStringAsFixed(1),
              icon: Icons.share,
              color: AppColors.info,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialOverview(Player player) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This Season',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.subtitle,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(player.finances.currentSeasonEarnings),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Career Total',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.subtitle,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(player.finances.careerEarnings),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildFinancialItem(
                        'Contracts',
                        currencyFormat.format(player.finances.contractEarnings),
                        Icons.description,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildFinancialItem(
                        'Endorsements',
                        currencyFormat.format(player.finances.endorsementEarnings),
                        Icons.star,
                        AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.subtitle,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(Player player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                context.go('/finances');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: player.finances.recentTransactions.take(3).length,
            itemBuilder: (context, index) {
              final transaction = player.finances.recentTransactions[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: transaction.type == 'income' 
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.danger.withOpacity(0.1),
                  child: Icon(
                    transaction.type == 'income' ? Icons.arrow_upward : Icons.arrow_downward,
                    color: transaction.type == 'income' ? AppColors.success : AppColors.danger,
                    size: 18,
                  ),
                ),
                title: Text(
                  transaction.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(transaction.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.subtitle,
                  ),
                ),
                trailing: Text(
                  NumberFormat.currency(symbol: '\$').format(transaction.amount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: transaction.type == 'income' ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              'View Contracts',
              Icons.description,
              AppColors.primary,
              () => context.go('/contracts'),
            ),
            _buildActionCard(
              'Endorsements',
              Icons.star,
              AppColors.accent,
              () => context.go('/endorsements'),
            ),
            _buildActionCard(
              'Union Resources',
              Icons.group,
              AppColors.info,
              () => context.go('/union'),
            ),
            _buildActionCard(
              'Messages',
              Icons.message,
              AppColors.success,
              () => context.go('/messaging'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnionUpdates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Union Updates',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.newspaper, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'New CBA Announced',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'The NSBLPA has successfully negotiated a new Collective Bargaining Agreement with improved benefits for all players.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '2 days ago',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String firstName, String lastName) {
    String firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    
    if (firstInitial.isEmpty && lastInitial.isEmpty) {
      return '?';
    }
    
    return firstInitial + lastInitial;
  }
} 