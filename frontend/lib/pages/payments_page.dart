/// Payments Page
///
/// Allows creating transfers (payouts) from master account to customers.
/// Shows eligible customers (verified customers with funding sources).
/// Toggle available to include unverified funding sources.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dwolla_provider.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  bool _includeUnverified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final provider = context.read<DwollaProvider>();
    if (provider.isConfigured) {
      provider.fetchEligibleCustomers(includeUnverified: _includeUnverified);
      provider.fetchAccountFundingSources();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              final provider = context.read<DwollaProvider>();
              provider.syncCustomersAndFundingSources(includeUnverified: _includeUnverified);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing customers & funding sources from Dwolla...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Sync from Dwolla',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
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
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Create a Payout',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _includeUnverified
                      ? 'Transfer money from your master account to an eligible customer. '
                        'Showing all funding sources (including unverified) for verified customers.'
                      : 'Transfer money from your master account to an eligible customer. '
                        'Customers must be verified and have a verified funding source.',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Toggle for unverified funding sources
                Card(
                  color: _includeUnverified ? Colors.blue[50] : Colors.grey[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          _includeUnverified ? Icons.toggle_on : Icons.toggle_off,
                          color: _includeUnverified ? Colors.blue : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Include unverified funding sources',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _includeUnverified
                                    ? 'Showing all funding sources for verified customers'
                                    : 'Only showing verified funding sources',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _includeUnverified,
                          onChanged: (value) {
                            setState(() => _includeUnverified = value);
                            _refreshData();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Payment form
                _PaymentForm(
                  eligibleCustomers: provider.eligibleCustomers,
                  masterFundingSources: provider.accountFundingSources,
                  allowUnverified: _includeUnverified,
                ),

                // Error display
                if (provider.error != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
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
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => provider.clearError(),
                        ),
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
}

class _PaymentForm extends StatefulWidget {
  final List<Map<String, dynamic>> eligibleCustomers;
  final List<Map<String, dynamic>> masterFundingSources;
  final bool allowUnverified;

  const _PaymentForm({
    required this.eligibleCustomers,
    required this.masterFundingSources,
    this.allowUnverified = false,
  });

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  final _amountController = TextEditingController();
  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? _selectedCustomerFundingSource;
  Map<String, dynamic>? _selectedMasterFundingSource;
  bool _isProcessing = false;

  List<Map<String, dynamic>> get _verifiedMasterSources {
    return widget.masterFundingSources
        .where((fs) => fs['status'] == 'verified')
        .toList();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedMasterFundingSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a source funding source'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCustomer == null || _selectedCustomerFundingSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a recipient'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final provider = context.read<DwollaProvider>();
    final success = await provider.createTransfer(
      sourceFundingSourceUrl: _selectedMasterFundingSource!['url'],
      destinationFundingSourceUrl: _selectedCustomerFundingSource!['url'],
      amount: amount,
      allowUnverified: widget.allowUnverified,
    );

    setState(() => _isProcessing = false);

    if (success && mounted) {
      _amountController.clear();
      setState(() {
        _selectedCustomer = null;
        _selectedCustomerFundingSource = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Select source funding source
            _buildSectionHeader('Step 1: Select Source (Your Account)', Icons.account_balance),
            const SizedBox(height: 12),

            if (_verifiedMasterSources.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No verified funding sources found on your master account. '
                        'Go to My Account to add one.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedMasterFundingSource,
                decoration: const InputDecoration(
                  labelText: 'Source Funding Source',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                items: _verifiedMasterSources.map((fs) {
                  return DropdownMenuItem(
                    value: fs,
                    child: Text('${fs['name']} (${fs['type']})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedMasterFundingSource = value);
                },
              ),

            const SizedBox(height: 24),

            // Step 2: Select recipient
            _buildSectionHeader('Step 2: Select Recipient', Icons.person),
            const SizedBox(height: 12),

            if (widget.eligibleCustomers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No eligible customers found. Customers must be verified '
                        'and have a verified funding source to receive payments.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedCustomer,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Customer',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: widget.eligibleCustomers.map((customer) {
                      return DropdownMenuItem(
                        value: customer,
                        child: Text(
                          '${customer['firstName']} ${customer['lastName']} (${customer['email']})',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomer = value;
                        _selectedCustomerFundingSource = null;
                      });
                    },
                  ),

                  if (_selectedCustomer != null) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedCustomerFundingSource,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Bank Account',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      items: (_selectedCustomer!['fundingSources'] as List?)
                              ?.map<DropdownMenuItem<Map<String, dynamic>>>(
                                  (fs) {
                            final isVerified = fs['status'] == 'verified';
                            return DropdownMenuItem(
                              value: Map<String, dynamic>.from(fs),
                              child: Row(
                                children: [
                                  Expanded(child: Text(fs['name'] ?? 'Unknown')),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isVerified ? Colors.green[100] : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      fs['status'] ?? 'unknown',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isVerified ? Colors.green[700] : Colors.orange[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList() ??
                          [],
                      onChanged: (value) {
                        setState(() => _selectedCustomerFundingSource = value);
                      },
                    ),
                  ],
                ],
              ),

            const SizedBox(height: 24),

            // Step 3: Enter amount
            _buildSectionHeader('Step 3: Enter Amount', Icons.attach_money),
            const SizedBox(height: 12),

            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (USD)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processPayment,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isProcessing ? 'Processing...' : 'Send Payment'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
