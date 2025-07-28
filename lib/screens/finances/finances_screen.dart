import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme.dart';
import '../../services/player_service.dart';
import '../../models/player.dart';

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  String _selectedPeriod = 'current';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              _exportFinancialReport();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Financial Overview Cards
                _buildFinancialOverview(player),
                const SizedBox(height: 24),

                // Earnings Chart
                _buildEarningsChart(player),
                const SizedBox(height: 24),

                // Recent Transactions
                _buildRecentTransactions(player),
                const SizedBox(height: 24),

                // Year-over-Year Comparison
                _buildYearlyComparison(player),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinancialOverview(Player player) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Overview',
          style: Theme.of(context).textTheme.titleLarge,
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
            _buildFinancialCard(
              'This Season',
              currencyFormat.format(player.finances.currentSeasonEarnings),
              Icons.trending_up,
              AppColors.success,
            ),
            _buildFinancialCard(
              'Career Total',
              currencyFormat.format(player.finances.careerEarnings),
              Icons.account_balance_wallet,
              AppColors.primary,
            ),
            _buildFinancialCard(
              'Contract Earnings',
              currencyFormat.format(player.finances.contractEarnings),
              Icons.description,
              AppColors.info,
            ),
            _buildFinancialCard(
              'Endorsements',
              currencyFormat.format(player.finances.endorsementEarnings),
              Icons.star,
              AppColors.accent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialCard(String title, String amount, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.subtitle,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsChart(Player player) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Earnings Trend',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: const [
                    DropdownMenuItem(value: 'current', child: Text('Current Season')),
                    DropdownMenuItem(value: 'career', child: Text('Career')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${(value / 1000000).toStringAsFixed(1)}M',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() < months.length) {
                            return Text(months[value.toInt()], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getChartData(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
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

  List<FlSpot> _getChartData() {
    // Mock data for the chart
    if (_selectedPeriod == 'current') {
      return [
        const FlSpot(0, 500000),
        const FlSpot(1, 750000),
        const FlSpot(2, 1200000),
        const FlSpot(3, 1800000),
        const FlSpot(4, 2500000),
        const FlSpot(5, 3200000),
      ];
    } else {
      return [
        const FlSpot(0, 2000000),
        const FlSpot(1, 3500000),
        const FlSpot(2, 5000000),
        const FlSpot(3, 7500000),
        const FlSpot(4, 10000000),
        const FlSpot(5, 12500000),
      ];
    }
  }

  Widget _buildRecentTransactions(Player player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                _showAllTransactions(player);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: player.finances.recentTransactions.take(5).length,
            itemBuilder: (context, index) {
              final transaction = player.finances.recentTransactions[index];
              return _buildTransactionTile(transaction);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: transaction.type == 'income' 
            ? AppColors.success.withOpacity(0.1)
            : AppColors.danger.withOpacity(0.1),
        child: Icon(
          transaction.type == 'income' ? Icons.arrow_upward : Icons.arrow_downward,
          color: transaction.type == 'income' ? AppColors.success : AppColors.danger,
          size: 20,
        ),
      ),
      title: Text(
        transaction.description,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMM dd, yyyy').format(transaction.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.subtitle,
            ),
          ),
          Text(
            transaction.category,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            currencyFormat.format(transaction.amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: transaction.type == 'income' ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(transaction.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transaction.status.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(transaction.status),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.accent;
      case 'failed':
        return AppColors.danger;
      default:
        return AppColors.subtitle;
    }
  }

  Widget _buildYearlyComparison(Player player) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Year-over-Year Comparison',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxYearlyEarnings(player),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${(value / 1000000).toStringAsFixed(1)}M',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final years = _getYearLabels(player);
                          if (value.toInt() < years.length) {
                            return Text(years[value.toInt()], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: _getBarChartData(player),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxYearlyEarnings(Player player) {
    if (player.finances.yearlyEarnings.isEmpty) return 1000000;
    return player.finances.yearlyEarnings
        .map((e) => e.earnings)
        .reduce((a, b) => a > b ? a : b) * 1.2;
  }

  List<String> _getYearLabels(Player player) {
    return player.finances.yearlyEarnings
        .map((e) => e.year.toString())
        .toList();
  }

  List<BarChartGroupData> _getBarChartData(Player player) {
    return player.finances.yearlyEarnings.asMap().entries.map((entry) {
      final index = entry.key;
      final earnings = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: earnings.earnings,
            color: AppColors.primary,
            width: 20,
          ),
        ],
      );
    }).toList();
  }

  void _showAllTransactions(Player player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TransactionsSheet(transactions: player.finances.recentTransactions),
    );
  }

  void _exportFinancialReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Financial report export feature coming soon!'),
      ),
    );
  }
}

class _TransactionsSheet extends StatefulWidget {
  final List<Transaction> transactions;

  const _TransactionsSheet({required this.transactions});

  @override
  State<_TransactionsSheet> createState() => _TransactionsSheetState();
}

class _TransactionsSheetState extends State<_TransactionsSheet> {
  @override
  Widget build(BuildContext context) {
    final transactions = widget.transactions;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'All Transactions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return _buildTransactionTile(transactions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: transaction.type == 'income' 
            ? AppColors.success.withOpacity(0.1)
            : AppColors.danger.withOpacity(0.1),
        child: Icon(
          transaction.type == 'income' ? Icons.arrow_upward : Icons.arrow_downward,
          color: transaction.type == 'income' ? AppColors.success : AppColors.danger,
          size: 20,
        ),
      ),
      title: Text(
        transaction.description,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        DateFormat('MMM dd, yyyy').format(transaction.date),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.subtitle,
        ),
      ),
      trailing: Text(
        currencyFormat.format(transaction.amount),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: transaction.type == 'income' ? AppColors.success : AppColors.danger,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 