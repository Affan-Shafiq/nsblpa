import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../models/player.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminService = Provider.of<AdminService>(context, listen: false);
      adminService.loadAllEndorsements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Consumer<AdminService>(
        builder: (context, adminService, child) {
          if (adminService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${adminService.error}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.danger,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      adminService.clearError();
                      adminService.loadAllEndorsements();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: const TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.subtitle,
                    indicatorColor: AppColors.primary,
                    tabs: [
                      Tab(text: 'Pending Requests'),
                      Tab(text: 'All Endorsements'),
                      Tab(text: 'Add New'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPendingRequestsTab(adminService),
                      _buildAllEndorsementsTab(adminService),
                      _buildAddNewTab(adminService),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingRequestsTab(AdminService adminService) {
    final pendingEndorsements = adminService.pendingEndorsements;

    if (pendingEndorsements.isEmpty) {
      return _buildEmptyState(
        'No pending endorsement requests',
        Icons.check_circle_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: pendingEndorsements.length,
      itemBuilder: (context, index) {
        return _buildPendingRequestCard(pendingEndorsements[index], adminService);
      },
    );
  }

  Widget _buildAllEndorsementsTab(AdminService adminService) {
    final allEndorsements = adminService.allEndorsements;

    if (allEndorsements.isEmpty) {
      return _buildEmptyState(
        'No endorsements found',
        Icons.star_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: allEndorsements.length,
      itemBuilder: (context, index) {
        return _buildEndorsementCard(allEndorsements[index]);
      },
    );
  }

  Widget _buildAddNewTab(AdminService adminService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _AddEndorsementForm(adminService: adminService),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.subtitle),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.subtitle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestCard(Endorsement endorsement, AdminService adminService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        endorsement.brandName,
                        style: Theme.of(context).textTheme.titleLarge,
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
                    NumberFormat.currency(symbol: '\$').format(endorsement.value),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveEndorsement(endorsement.id, adminService),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectEndorsement(endorsement.id, adminService),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: AppColors.danger),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndorsementCard(Endorsement endorsement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        endorsement.brandName,
                        style: Theme.of(context).textTheme.titleLarge,
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
                    NumberFormat.currency(symbol: '\$').format(endorsement.value),
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
          ],
        ),
      ),
    );
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
        color = AppColors.subtitle;
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

  void _approveEndorsement(String endorsementId, AdminService adminService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Endorsement'),
        content: const Text('Are you sure you want to approve this endorsement request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await adminService.approveEndorsement(endorsementId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Endorsement approved successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectEndorsement(String endorsementId, AdminService adminService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Endorsement'),
        content: const Text('Are you sure you want to reject this endorsement request? This action will permanently delete the request from the database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await adminService.rejectEndorsement(endorsementId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Endorsement request deleted'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete Request'),
          ),
        ],
      ),
    );
  }
}

class _AddEndorsementForm extends StatefulWidget {
  final AdminService adminService;

  const _AddEndorsementForm({required this.adminService});

  @override
  State<_AddEndorsementForm> createState() => _AddEndorsementFormState();
}

class _AddEndorsementFormState extends State<_AddEndorsementForm> {
  final _formKey = GlobalKey<FormState>();
  final _brandNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _durationController = TextEditingController();
  final _requirementsController = TextEditingController();
  final List<String> _requirements = [];

  @override
  void dispose() {
    _brandNameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _durationController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add New Endorsement',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _brandNameController,
            decoration: const InputDecoration(
              labelText: 'Brand Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter brand name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter category';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _valueController,
                  decoration: const InputDecoration(
                    labelText: 'Value (\$)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter value';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter duration';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Requirements section
          Text(
            'Requirements',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          if (_requirements.isNotEmpty) ...[
            ..._requirements.map((req) => Chip(
              label: Text(req),
              onDeleted: () {
                setState(() {
                  _requirements.remove(req);
                });
              },
            )),
            const SizedBox(height: 8),
          ],
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _requirementsController,
                  decoration: const InputDecoration(
                    labelText: 'Add Requirement',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_requirementsController.text.isNotEmpty) {
                    setState(() {
                      _requirements.add(_requirementsController.text);
                      _requirementsController.clear();
                    });
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Create Endorsement'),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final success = await widget.adminService.createEndorsement(
        brandName: _brandNameController.text,
        category: _categoryController.text,
        description: _descriptionController.text,
        value: double.parse(_valueController.text),
        duration: _durationController.text,
        requirements: _requirements,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Endorsement created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Clear form
        _formKey.currentState!.reset();
        _brandNameController.clear();
        _categoryController.clear();
        _descriptionController.clear();
        _valueController.clear();
        _durationController.clear();
        _requirementsController.clear();
        setState(() {
          _requirements.clear();
        });
      }
    }
  }
} 