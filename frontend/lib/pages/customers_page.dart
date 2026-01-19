/// Customers Page
///
/// Displays all customers and allows creating new ones.
/// Shows customer verification status and provides actions
/// for KYC verification and adding funding sources.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dwolla_provider.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  @override
  void initState() {
    super.initState();
    // Fetch customers when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DwollaProvider>();
      if (provider.isConfigured) {
        provider.fetchCustomers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DwollaProvider>().fetchCustomers(refresh: true);
            },
            tooltip: 'Refresh customers',
          ),
        ],
      ),
      body: Consumer<DwollaProvider>(
        builder: (context, provider, _) {
          if (!provider.isConfigured) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Please configure your Dwolla credentials first',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Go to Settings to enter your API key and secret',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (provider.isLoading && provider.customers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Customer list
              Expanded(
                child: provider.customers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No customers yet',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            Text(
                              'Click the + button to create your first customer',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.customers.length,
                        itemBuilder: (context, index) {
                          final customer = provider.customers[index];
                          return _CustomerCard(customer: customer);
                        },
                      ),
              ),

              // Error message
              if (provider.error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red[100],
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => provider.clearError(),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<DwollaProvider>(
        builder: (context, provider, _) {
          if (!provider.isConfigured) return const SizedBox();
          return FloatingActionButton.extended(
            onPressed: () => _showCreateCustomerDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Customer'),
          );
        },
      ),
    );
  }

  void _showCreateCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateCustomerDialog(),
    );
  }
}

/// Customer card widget showing customer details and actions
class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final status = customer['status'] ?? 'unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with name and status badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${customer['firstName']} ${customer['lastName']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer['email'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),

            // Customer details
            Row(
              children: [
                _DetailChip(
                  icon: Icons.badge,
                  label: 'ID: ${_truncateId(customer['id'])}',
                ),
                const SizedBox(width: 8),
                if (customer['phone'] != null)
                  _DetailChip(
                    icon: Icons.phone,
                    label: customer['phone'],
                  ),
                const SizedBox(width: 8),
                _DetailChip(
                  icon: Icons.person,
                  label: customer['type'] ?? 'personal',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Verify KYC button
                if (status == 'unverified' || status == 'retry')
                  OutlinedButton.icon(
                    onPressed: () => _showVerifyDialog(context),
                    icon: const Icon(Icons.verified_user, size: 18),
                    label: const Text('Verify KYC'),
                  ),
                const SizedBox(width: 8),

                // Add Funding Source button
                OutlinedButton.icon(
                  onPressed: () => _showAddFundingSourceDialog(context),
                  icon: const Icon(Icons.account_balance, size: 18),
                  label: const Text('Add Bank'),
                ),
                const SizedBox(width: 8),

                // View Funding Sources button
                OutlinedButton.icon(
                  onPressed: () => _showFundingSourcesDialog(context),
                  icon: const Icon(Icons.list, size: 18),
                  label: const Text('View Banks'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _truncateId(String? id) {
    if (id == null) return 'N/A';
    if (id.length > 12) return '${id.substring(0, 12)}...';
    return id;
  }

  void _showVerifyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _VerifyCustomerDialog(customer: customer),
    );
  }

  void _showAddFundingSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddFundingSourceDialog(customer: customer),
    );
  }

  void _showFundingSourcesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ViewFundingSourcesDialog(customer: customer),
    );
  }
}

/// Status badge widget with color coding
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'verified':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        break;
      case 'unverified':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        icon = Icons.warning;
        break;
      case 'document':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        icon = Icons.description;
        break;
      case 'retry':
        bgColor = Colors.amber[100]!;
        textColor = Colors.amber[700]!;
        icon = Icons.refresh;
        break;
      case 'suspended':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        icon = Icons.block;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail chip for customer info
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

/// Dialog for creating a new customer
class _CreateCustomerDialog extends StatefulWidget {
  const _CreateCustomerDialog();

  @override
  State<_CreateCustomerDialog> createState() => _CreateCustomerDialogState();
}

class _CreateCustomerDialogState extends State<_CreateCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  String _customerType = 'personal';
  bool _isCreating = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _createCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final provider = context.read<DwollaProvider>();
    final result = await provider.createCustomer(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      type: _customerType,
      businessName: _customerType == 'business'
          ? _businessNameController.text.trim()
          : null,
    );

    setState(() => _isCreating = false);

    if (result != null && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Customer'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Customer type selector
              Row(
                children: [
                  const Text('Type: '),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Personal'),
                    selected: _customerType == 'personal',
                    onSelected: (selected) {
                      if (selected) setState(() => _customerType = 'personal');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Business'),
                    selected: _customerType == 'business',
                    onSelected: (selected) {
                      if (selected) setState(() => _customerType = 'business');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.trim().isEmpty == true) return 'Required';
                  if (!v!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),

              if (_customerType == 'business') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
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
          onPressed: _isCreating ? null : _createCustomer,
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

/// Dialog for verifying a customer (KYC)
class _VerifyCustomerDialog extends StatefulWidget {
  final Map<String, dynamic> customer;

  const _VerifyCustomerDialog({required this.customer});

  @override
  State<_VerifyCustomerDialog> createState() => _VerifyCustomerDialogState();
}

class _VerifyCustomerDialogState extends State<_VerifyCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ssnController = TextEditingController(text: '1234');
  final _dobController = TextEditingController(text: '1990-01-01');
  final _addressController = TextEditingController(text: '123 Main St');
  final _cityController = TextEditingController(text: 'San Francisco');
  final _stateController = TextEditingController(text: 'CA');
  final _postalController = TextEditingController(text: '94105');
  bool _isVerifying = false;

  @override
  void dispose() {
    _ssnController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isVerifying = true);

    final provider = context.read<DwollaProvider>();
    final success = await provider.verifyCustomer(
      widget.customer['id'],
      ssn: _ssnController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      address1: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalController.text.trim(),
    );

    setState(() => _isVerifying = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification submitted!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Customer (KYC)'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Sandbox Testing Tips:\n'
                  '- SSN ending in 0000 = verified\n'
                  '- SSN ending in 0001 = retry status\n'
                  '- SSN ending in 0002 = document status',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ssnController,
                decoration: const InputDecoration(
                  labelText: 'SSN (last 4 digits)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _postalController,
                decoration: const InputDecoration(
                  labelText: 'Postal Code',
                  border: OutlineInputBorder(),
                ),
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
          onPressed: _isVerifying ? null : _verify,
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Verification'),
        ),
      ],
    );
  }
}

/// Dialog for adding a funding source
class _AddFundingSourceDialog extends StatefulWidget {
  final Map<String, dynamic> customer;

  const _AddFundingSourceDialog({required this.customer});

  @override
  State<_AddFundingSourceDialog> createState() =>
      _AddFundingSourceDialogState();
}

class _AddFundingSourceDialogState extends State<_AddFundingSourceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _routingController = TextEditingController(text: '222222226');
  final _accountController = TextEditingController(text: '123456789');
  String _accountType = 'checking';
  bool _isAdding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _routingController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _addFundingSource() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAdding = true);

    final provider = context.read<DwollaProvider>();
    final success = await provider.addFundingSource(
      widget.customer['id'],
      name: _nameController.text.trim(),
      routingNumber: _routingController.text.trim(),
      accountNumber: _accountController.text.trim(),
      accountType: _accountType,
    );

    setState(() => _isAdding = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funding source added!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Funding Source'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Sandbox Test Bank:\n'
                  'Routing: 222222226\n'
                  'Account: Any 9+ digits',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Nickname *',
                  hintText: 'e.g., My Checking Account',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _routingController,
                decoration: const InputDecoration(
                  labelText: 'Routing Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Text('Account Type: '),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Checking'),
                    selected: _accountType == 'checking',
                    onSelected: (s) {
                      if (s) setState(() => _accountType = 'checking');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Savings'),
                    selected: _accountType == 'savings',
                    onSelected: (s) {
                      if (s) setState(() => _accountType = 'savings');
                    },
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
          onPressed: _isAdding ? null : _addFundingSource,
          child: _isAdding
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}

/// Dialog for viewing funding sources
class _ViewFundingSourcesDialog extends StatefulWidget {
  final Map<String, dynamic> customer;

  const _ViewFundingSourcesDialog({required this.customer});

  @override
  State<_ViewFundingSourcesDialog> createState() =>
      _ViewFundingSourcesDialogState();
}

class _ViewFundingSourcesDialogState extends State<_ViewFundingSourcesDialog> {
  List<Map<String, dynamic>> _fundingSources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFundingSources();
  }

  Future<void> _loadFundingSources() async {
    final provider = context.read<DwollaProvider>();
    final sources =
        await provider.getCustomerFundingSources(widget.customer['id']);
    setState(() {
      _fundingSources = sources;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Funding Sources - ${widget.customer['firstName']} ${widget.customer['lastName']}',
      ),
      content: SizedBox(
        width: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _fundingSources.isEmpty
                ? const Center(
                    child: Text('No funding sources found'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _fundingSources.length,
                    itemBuilder: (context, index) {
                      final fs = _fundingSources[index];
                      final status = fs['status'] ?? 'unknown';
                      final isVerified = status == 'verified';

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.account_balance,
                            color: isVerified ? Colors.green : Colors.orange,
                          ),
                          title: Text(fs['name'] ?? 'Unknown'),
                          subtitle: Text(
                            '${fs['bankAccountType'] ?? 'account'} - ${fs['bankName'] ?? 'Unknown Bank'}',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isVerified
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isVerified
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
