import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../services/player_service.dart';
import '../../services/contract_service.dart';
import '../../models/player.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerService = Provider.of<PlayerService>(context, listen: false);
      final contractService = Provider.of<ContractService>(context, listen: false);
      if (playerService.currentPlayer != null) {
        contractService.getContractsForPlayer(playerService.currentPlayer!.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Contracts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddContractDialog(context);
            },
          ),
        ],
      ),
      body: Consumer2<PlayerService, ContractService>(
        builder: (context, playerService, contractService, child) {
          if (playerService.isLoading || contractService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final player = playerService.currentPlayer;
          if (player == null) {
            return const Center(child: Text('No player data available'));
          }

          final contracts = _getFilteredContracts(contractService.contracts);

          return Column(
            children: [
              // Filter Tabs
              _buildFilterTabs(),
              
              // Contracts List
              Expanded(
                child: contracts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: contracts.length,
                        itemBuilder: (context, index) {
                          return _buildContractCard(contracts[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All'),
            const SizedBox(width: 8),
            _buildFilterChip('active', 'Active'),
            const SizedBox(width: 8),
            _buildFilterChip('expired', 'Expired'),
            const SizedBox(width: 8),
            _buildFilterChip('pending', 'Pending'),
            const SizedBox(width: 16), // Add padding at the end
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  List<Contract> _getFilteredContracts(List<Contract> contracts) {
    switch (_selectedFilter) {
      case 'active':
        return contracts.where((c) => c.isActive).toList();
      case 'expired':
        return contracts.where((c) => c.isExpired).toList();
      case 'pending':
        return contracts.where((c) => c.status == 'pending').toList();
      default:
        return contracts;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: AppColors.subtitle,
          ),
          const SizedBox(height: 16),
          Text(
            'No contracts found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first contract to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showAddContractDialog(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Contract'),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(Contract contract) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isExpiringSoon = contract.daysRemaining <= 30 && contract.daysRemaining > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showContractDetails(context, contract);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contract.type.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(contract.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                contract.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildContractInfo(
                      'Annual Value',
                      currencyFormat.format(contract.annualValue),
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildContractInfo(
                      'Duration',
                      '${DateFormat('MMM yyyy').format(contract.startDate)} - ${DateFormat('MMM yyyy').format(contract.endDate)}',
                      Icons.calendar_today,
                    ),
                  ),
                ],
              ),
              if (isExpiringSoon) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: AppColors.accent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Expires in ${contract.daysRemaining} days',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = AppColors.success;
        label = 'Active';
        break;
      case 'expired':
        color = AppColors.danger;
        label = 'Expired';
        break;
      case 'pending':
        color = AppColors.accent;
        label = 'Pending';
        break;
      case 'terminated':
        color = AppColors.subtitle;
        label = 'Terminated';
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

  Widget _buildContractInfo(String label, String value, IconData icon) {
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

  void _showContractDetails(BuildContext context, Contract contract) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContractDetailsSheet(contract: contract),
    );
  }

  void _showAddContractDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddContractDialog(),
    );
  }
}

class _ContractDetailsSheet extends StatefulWidget {
  final Contract contract;

  const _ContractDetailsSheet({required this.contract});

  @override
  State<_ContractDetailsSheet> createState() => _ContractDetailsSheetState();
}

class _ContractDetailsSheetState extends State<_ContractDetailsSheet> {
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final contract = widget.contract;

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
                  Text(
                    contract.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contract.type.toUpperCase(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    contract.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  
                  // Contract Details
                  _buildDetailSection('Contract Details', [
                    _buildDetailRow('Annual Value', currencyFormat.format(contract.annualValue)),
                    _buildDetailRow('Start Date', DateFormat('MMMM dd, yyyy').format(contract.startDate)),
                    _buildDetailRow('End Date', DateFormat('MMMM dd, yyyy').format(contract.endDate)),
                    _buildDetailRow('Status', contract.status.toUpperCase()),
                    _buildDetailRow('Days Remaining', contract.daysRemaining.toString()),
                  ]),
                  
                  if (contract.incentives.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDetailSection('Incentives', [
                      ...contract.incentives.map((incentive) => _buildDetailRow('•', incentive)),
                    ]),
                  ],
                  
                  if (contract.documentUrl != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Open document
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.file_download),
                      label: const Text('Download Contract'),
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

class _AddContractDialog extends StatefulWidget {
  const _AddContractDialog();

  @override
  State<_AddContractDialog> createState() => _AddContractDialogState();
}

class _AddContractDialogState extends State<_AddContractDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _annualValueController = TextEditingController();
  String _selectedType = 'player';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _annualValueController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Contract'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Contract Title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Contract Type',
                ),
                items: const [
                  DropdownMenuItem(value: 'player', child: Text('Player Contract')),
                  DropdownMenuItem(value: 'endorsement', child: Text('Endorsement')),
                  DropdownMenuItem(value: 'sponsorship', child: Text('Sponsorship')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _annualValueController,
                decoration: const InputDecoration(
                  labelText: 'Annual Value (\$)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter annual value';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(_startDate == null 
                          ? 'Select date' 
                          : DateFormat('MMM dd, yyyy').format(_startDate!)),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(_endDate == null 
                          ? 'Select date' 
                          : DateFormat('MMM dd, yyyy').format(_endDate!)),
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate() && _startDate != null && _endDate != null) {
              final playerService = Provider.of<PlayerService>(context, listen: false);
              final contractService = Provider.of<ContractService>(context, listen: false);
              
              if (playerService.currentPlayer != null) {
                final contract = Contract(
                  id: '',
                  userId: playerService.currentPlayer!.userId,
                  type: _selectedType,
                  title: _titleController.text,
                  description: _descriptionController.text,
                  annualValue: double.parse(_annualValueController.text),
                  startDate: _startDate!,
                  endDate: _endDate!,
                  status: 'active',
                  documentUrl: null,
                  incentives: [],
                  terms: {},
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                final success = await contractService.addContract(contract);
                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contract added successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${contractService.error}')),
                  );
                }
              }
            }
          },
          child: const Text('Add Contract'),
        ),
      ],
    );
  }
} 