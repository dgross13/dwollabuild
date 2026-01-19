/// Account Page
///
/// Displays the master account (your Dwolla account) information,
/// including funding sources and balance.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dwolla_provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAccount();
    });
  }

  void _refreshAccount() {
    final provider = context.read<DwollaProvider>();
    if (provider.isConfigured) {
      provider.refreshAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAccount,
            tooltip: 'Refresh account status',
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

          if (provider.isLoading && provider.account == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account info card
                _buildAccountCard(provider),
                const SizedBox(height: 24),

                // Balance card
                _buildBalanceCard(provider),
                const SizedBox(height: 24),

                // Funding sources
                _buildFundingSourcesCard(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountCard(DwollaProvider provider) {
    final account = provider.account;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_circle,
                    size: 40,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Master Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        account?['name'] ?? 'Loading...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    account?['type']?.toUpperCase() ?? 'N/A',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _InfoRow(
              icon: Icons.badge,
              label: 'Account ID',
              value: account?['id'] ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(DwollaProvider provider) {
    final balance = provider.accountBalance;

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Account Balance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (balance == null || balance['balance'] == null)
              Text(
                'Balance not available for this account type',
                style: TextStyle(color: Colors.green[600]),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${balance['balance']['value']}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      balance['balance']['currency'] ?? 'USD',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.green[600],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundingSourcesCard(DwollaProvider provider) {
    final fundingSources = provider.accountFundingSources;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Funding Sources',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${fundingSources.length} sources',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const Divider(height: 24),
            if (fundingSources.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'No funding sources found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...fundingSources.map((fs) => _FundingSourceTile(fundingSource: fs)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FundingSourceTile extends StatelessWidget {
  final Map<String, dynamic> fundingSource;

  const _FundingSourceTile({required this.fundingSource});

  @override
  Widget build(BuildContext context) {
    final status = fundingSource['status'] ?? 'unknown';
    final isVerified = status == 'verified';
    final type = fundingSource['type'] ?? 'bank';
    final isBalance = type == 'balance';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBalance ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBalance ? Colors.green[200]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBalance ? Icons.account_balance_wallet : Icons.account_balance,
            color: isBalance ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fundingSource['name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  isBalance
                      ? 'Dwolla Balance'
                      : '${fundingSource['bankAccountType'] ?? 'Account'} - ${fundingSource['bankName'] ?? 'Bank'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isVerified ? Colors.green[100] : Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isVerified ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
