/// Transfers Page
///
/// Displays all transfers with their current status.
/// Auto-refreshes every 3 seconds to show real-time updates.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dwolla_provider.dart';

class TransfersPage extends StatefulWidget {
  const TransfersPage({super.key});

  @override
  State<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends State<TransfersPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTransfers();
      // Auto-refresh every 3 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _fetchTransfers();
      });
    });
  }

  void _fetchTransfers() {
    final provider = context.read<DwollaProvider>();
    if (provider.isConfigured) {
      provider.fetchTransfers();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Auto-refresh indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync, size: 14, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  'Auto-refresh',
                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTransfers,
            tooltip: 'Refresh now',
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

          if (provider.transfers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No transfers yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Create a payment to see transfers here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Status legend
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatusLegendItem(
                      color: Colors.orange,
                      label: 'Pending',
                    ),
                    const SizedBox(width: 16),
                    _StatusLegendItem(
                      color: Colors.green,
                      label: 'Processed',
                    ),
                    const SizedBox(width: 16),
                    _StatusLegendItem(
                      color: Colors.red,
                      label: 'Failed',
                    ),
                    const SizedBox(width: 16),
                    _StatusLegendItem(
                      color: Colors.grey,
                      label: 'Cancelled',
                    ),
                  ],
                ),
              ),

              // Transfers list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.transfers.length,
                  itemBuilder: (context, index) {
                    final transfer = provider.transfers[index];
                    return _TransferCard(transfer: transfer);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _TransferCard extends StatelessWidget {
  final Map<String, dynamic> transfer;

  const _TransferCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final status = transfer['status'] ?? 'unknown';
    final amount = transfer['amount'];
    final created = transfer['created'];
    final sourceDetails = transfer['sourceDetails'];
    final destinationDetails = transfer['destinationDetails'];

    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'processed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transfer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'ID: ${_truncateId(transfer['id'])}',
                        style: TextStyle(
                          fontSize: 12,
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Amount
            Row(
              children: [
                const Icon(Icons.attach_money, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Amount: ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  amount != null
                      ? '\$${amount['value']} ${amount['currency']}'
                      : 'N/A',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Source funding source
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.output, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'From: ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Expanded(
                  child: Text(
                    _getFundingSourceDisplay(sourceDetails),
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Destination funding source
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.input, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'To: ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Expanded(
                  child: Text(
                    _getFundingSourceDisplay(destinationDetails),
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Created timestamp
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Created: ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  _formatDate(created),
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFundingSourceDisplay(Map<String, dynamic>? details) {
    if (details == null) return 'Unknown';
    final name = details['name'] ?? 'Unknown';
    final type = details['type'];
    final bankName = details['bankName'];

    String display = name;
    if (bankName != null && bankName.isNotEmpty) {
      display += ' ($bankName)';
    } else if (type != null) {
      display += ' ($type)';
    }
    return display;
  }

  String _truncateId(String? id) {
    if (id == null) return 'N/A';
    if (id.length > 20) return '${id.substring(0, 20)}...';
    return id;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
