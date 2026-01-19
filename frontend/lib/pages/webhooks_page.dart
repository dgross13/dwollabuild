/// Webhooks Page
///
/// Displays all received webhook events from Dwolla.
/// Auto-refreshes every 3 seconds to show real-time events.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dwolla_provider.dart';

class WebhooksPage extends StatefulWidget {
  const WebhooksPage({super.key});

  @override
  State<WebhooksPage> createState() => _WebhooksPageState();
}

class _WebhooksPageState extends State<WebhooksPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWebhooks();
      // Auto-refresh every 3 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _fetchWebhooks();
      });
    });
  }

  void _fetchWebhooks() {
    final provider = context.read<DwollaProvider>();
    if (provider.isConfigured) {
      provider.fetchWebhooks();
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
        title: const Text('Webhooks'),
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
            onPressed: _fetchWebhooks,
            tooltip: 'Refresh now',
          ),
          Consumer<DwollaProvider>(
            builder: (context, provider, _) {
              if (provider.webhooks.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Webhooks'),
                      content: const Text(
                        'Are you sure you want to clear all webhook events?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    provider.clearWebhooks();
                  }
                },
                tooltip: 'Clear all webhooks',
              );
            },
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

          return Column(
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Webhook Events',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          Text(
                            'Dwolla sends webhook notifications when events occur '
                            '(customer verified, transfer completed, etc.)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Webhooks count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    Text(
                      '${provider.webhooks.length} events received',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Webhooks list
              Expanded(
                child: provider.webhooks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.webhook, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No webhook events yet',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            Text(
                              'Events will appear here when Dwolla sends them',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.webhooks.length,
                        itemBuilder: (context, index) {
                          final webhook = provider.webhooks[index];
                          return _WebhookCard(webhook: webhook);
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

class _WebhookCard extends StatelessWidget {
  final Map<String, dynamic> webhook;

  const _WebhookCard({required this.webhook});

  @override
  Widget build(BuildContext context) {
    final topic = webhook['topic'] ?? 'unknown';
    final timestamp = webhook['timestamp'] ?? webhook['created'];
    final resourceId = webhook['resourceId'];

    // Determine color based on topic
    Color topicColor;
    IconData topicIcon;

    if (topic.contains('customer')) {
      topicColor = Colors.blue;
      topicIcon = Icons.person;
    } else if (topic.contains('transfer')) {
      topicColor = Colors.green;
      topicIcon = Icons.swap_horiz;
    } else if (topic.contains('funding')) {
      topicColor = Colors.purple;
      topicIcon = Icons.account_balance;
    } else {
      topicColor = Colors.grey;
      topicIcon = Icons.webhook;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topic header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: topicColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(topicIcon, color: topicColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: topicColor,
                        ),
                      ),
                      Text(
                        'Event ID: ${_truncateId(webhook['id'])}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // Details
            _DetailRow(
              icon: Icons.access_time,
              label: 'Timestamp',
              value: _formatDate(timestamp),
            ),

            if (resourceId != null)
              _DetailRow(
                icon: Icons.link,
                label: 'Resource ID',
                value: _truncateId(resourceId),
              ),

            // Topic explanation
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getTopicExplanation(topic),
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncateId(String? id) {
    if (id == null) return 'N/A';
    if (id.length > 24) return '${id.substring(0, 24)}...';
    return id;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getTopicExplanation(String topic) {
    final explanations = {
      'customer_created': 'A new customer was created in Dwolla',
      'customer_verified': 'Customer passed KYC verification',
      'customer_suspended': 'Customer account was suspended',
      'customer_verification_document_needed': 'Additional documents required for verification',
      'customer_reverification_needed': 'Customer needs to reverify their information',
      'transfer_created': 'A new transfer was initiated',
      'transfer_completed': 'Transfer has been processed successfully',
      'transfer_failed': 'Transfer processing failed',
      'transfer_cancelled': 'Transfer was cancelled',
      'funding_source_added': 'A bank account was added',
      'funding_source_verified': 'Bank account was verified',
      'funding_source_removed': 'Bank account was removed',
    };

    return explanations[topic] ?? 'Dwolla event notification received';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
