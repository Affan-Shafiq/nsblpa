import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme.dart';
import '../../models/player.dart';
import '../../services/player_service.dart';
import '../../services/auth_service.dart';
import '../../services/endorsement_service.dart';

class EndorsementsScreen extends StatefulWidget {
  const EndorsementsScreen({super.key});

  @override
  State<EndorsementsScreen> createState() => _EndorsementsScreenState();
}

class _EndorsementsScreenState extends State<EndorsementsScreen> {
  String _selectedCategory = 'all';
  String _selectedRegion = 'all';
  String _sortBy = 'value';

  // Mock endorsement opportunities - will be replaced with real data from Firestore
  final List<Endorsement> _availableEndorsements = [
    Endorsement(
      id: '1',
      userId: '',
      brandName: 'Nike',
      category: 'Sports Equipment',
      description: 'Official footwear and apparel partnership for the upcoming season.',
      value: 500000,
      duration: '2 years',
      status: 'available',
      imageUrl: null,
      requirements: ['Active player status', 'Minimum 15 games played', 'Social media presence'],
      startDate: null,
      endDate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Endorsement(
      id: '2',
      userId: '',
      brandName: 'Gatorade',
      category: 'Beverages',
      description: 'Hydration and sports drink endorsement deal.',
      value: 250000,
      duration: '1 year',
      status: 'available',
      imageUrl: null,
      requirements: ['Team endorsement', 'Game day appearances'],
      startDate: null,
      endDate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Endorsement(
      id: '3',
      userId: '',
      brandName: 'Under Armour',
      category: 'Sports Equipment',
      description: 'Performance wear and training gear partnership.',
      value: 350000,
      duration: '3 years',
      status: 'available',
      imageUrl: null,
      requirements: ['Exclusive brand partnership', 'Training camp participation'],
      startDate: null,
      endDate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Endorsement(
      id: '4',
      userId: '',
      brandName: 'McDonald\'s',
      category: 'Food & Beverages',
      description: 'Local restaurant chain endorsement and promotional appearances.',
      value: 150000,
      duration: '1 year',
      status: 'available',
      imageUrl: null,
      requirements: ['Local market appeal', 'Community involvement'],
      startDate: null,
      endDate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Endorsement(
      id: '5',
      userId: '',
      brandName: 'Beats by Dre',
      category: 'Electronics',
      description: 'Headphones and audio equipment endorsement.',
      value: 200000,
      duration: '2 years',
      status: 'available',
      imageUrl: null,
      requirements: ['Social media promotion', 'Product integration'],
      startDate: null,
      endDate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Load endorsements when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final endorsementService = Provider.of<EndorsementService>(context, listen: false);
      endorsementService.loadAvailableEndorsements();
      endorsementService.loadMyEndorsements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Endorsements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),
          
          // Endorsements List
          Expanded(
            child: Consumer<EndorsementService>(
              builder: (context, endorsementService, child) {
                if (endorsementService.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      // Tab Bar
                      Container(
                        color: Colors.white,
                        child: const TabBar(
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.subtitle,
                          indicatorColor: AppColors.primary,
                          tabs: [
                            Tab(text: 'Available Opportunities'),
                            Tab(text: 'My Endorsements'),
                          ],
                        ),
                      ),
                      
                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildAvailableEndorsements(endorsementService),
                            _buildMyEndorsements(endorsementService),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All Categories'),
            const SizedBox(width: 8),
            _buildFilterChip('Sports Equipment', 'Sports'),
            const SizedBox(width: 8),
            _buildFilterChip('Beverages', 'Beverages'),
            const SizedBox(width: 8),
            _buildFilterChip('Food & Beverages', 'Food'),
            const SizedBox(width: 8),
            _buildFilterChip('Electronics', 'Electronics'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildAvailableEndorsements(EndorsementService endorsementService) {
    final filteredEndorsements = _getFilteredEndorsements(endorsementService.availableEndorsements);
    
    if (filteredEndorsements.isEmpty) {
      return _buildEmptyState('No endorsement opportunities available');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredEndorsements.length,
      itemBuilder: (context, index) {
        return _buildEndorsementCard(filteredEndorsements[index], isAvailable: true);
      },
    );
  }

  Widget _buildMyEndorsements(EndorsementService endorsementService) {
    if (endorsementService.myEndorsements.isEmpty) {
      return _buildEmptyState('No active endorsements');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: endorsementService.myEndorsements.length,
      itemBuilder: (context, index) {
        return _buildEndorsementCard(endorsementService.myEndorsements[index], isAvailable: false);
      },
    );
  }

  List<Endorsement> _getFilteredEndorsements(List<Endorsement> endorsements) {
    var filtered = endorsements;
    
    if (_selectedCategory != 'all') {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }
    
    // Sort by value
    filtered.sort((a, b) => b.value.compareTo(a.value));
    
    return filtered;
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline,
            size: 64,
            color: AppColors.subtitle,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndorsementCard(Endorsement endorsement, {required bool isAvailable}) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showEndorsementDetails(context, endorsement, isAvailable);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Brand Logo Placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(endorsement.category),
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          endorsement.brandName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          endorsement.category,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAvailable)
                    _buildStatusChip(endorsement.status)
                  else
                    _buildStatusChip(endorsement.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                endorsement.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildEndorsementInfo(
                      'Value',
                      currencyFormat.format(endorsement.value),
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildEndorsementInfo(
                      'Duration',
                      endorsement.duration,
                      Icons.schedule,
                    ),
                  ),
                ],
              ),
              if (isAvailable) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _applyForEndorsement(endorsement);
                    },
                    child: const Text('Apply Now'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Sports Equipment':
        return Icons.sports_basketball;
      case 'Beverages':
        return Icons.local_drink;
      case 'Food & Beverages':
        return Icons.restaurant;
      case 'Electronics':
        return Icons.devices;
      default:
        return Icons.star;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'available':
        color = AppColors.success;
        label = 'Available';
        break;
      case 'active':
        color = AppColors.primary;
        label = 'Active';
        break;
      case 'pending':
        color = AppColors.accent;
        label = 'Pending';
        break;
      case 'expired':
        color = AppColors.danger;
        label = 'Expired';
        break;
      default:
        color = AppColors.subtitle;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEndorsementInfo(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.subtitle),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.subtitle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showEndorsementDetails(BuildContext context, Endorsement endorsement, bool isAvailable) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EndorsementDetailsSheet(
        endorsement: endorsement,
        isAvailable: isAvailable,
      ),
    );
  }

  void _applyForEndorsement(Endorsement endorsement) async {
    final endorsementService = Provider.of<EndorsementService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply for ${endorsement.brandName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to apply for this endorsement?'),
            const SizedBox(height: 16),
            Text(
              'Requirements:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...endorsement.requirements.map((req) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(req)),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await endorsementService.requestEndorsement(endorsement);
              
              if (success && mounted) {
                // Refresh available endorsements to hide the applied one
                await endorsementService.loadAvailableEndorsements();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Application submitted for ${endorsement.brandName}!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${endorsementService.error}'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter & Sort'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Sort by Value (High to Low)'),
              leading: Radio<String>(
                value: 'value',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: const Text('Sort by Duration'),
              leading: Radio<String>(
                value: 'duration',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _EndorsementDetailsSheet extends StatefulWidget {
  final Endorsement endorsement;
  final bool isAvailable;

  const _EndorsementDetailsSheet({
    required this.endorsement,
    required this.isAvailable,
  });

  @override
  State<_EndorsementDetailsSheet> createState() => _EndorsementDetailsSheetState();
}

class _EndorsementDetailsSheetState extends State<_EndorsementDetailsSheet> {
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final endorsement = widget.endorsement;

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
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getCategoryIcon(endorsement.category),
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              endorsement.brandName,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              endorsement.category,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    endorsement.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  
                  // Endorsement Details
                  _buildDetailSection('Deal Details', [
                    _buildDetailRow('Value', currencyFormat.format(endorsement.value)),
                    _buildDetailRow('Duration', endorsement.duration),
                    _buildDetailRow('Status', endorsement.status.toUpperCase()),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildDetailSection('Requirements', [
                    ...endorsement.requirements.map((req) => _buildDetailRow('•', req)),
                  ]),
                  
                  if (widget.isAvailable) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Apply logic would go here
                        },
                        child: const Text('Apply for Endorsement'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Sports Equipment':
        return Icons.sports_basketball;
      case 'Beverages':
        return Icons.local_drink;
      case 'Food & Beverages':
        return Icons.restaurant;
      case 'Electronics':
        return Icons.devices;
      default:
        return Icons.star;
    }
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
} 