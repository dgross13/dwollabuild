/// Visualizer Page
///
/// Displays flow diagrams to help understand how the Dwolla system works.
/// Uses simple HTML/CSS-style diagrams built with Flutter widgets.

import 'package:flutter/material.dart';

class VisualizerPage extends StatelessWidget {
  const VisualizerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flow Visualizer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Understanding Dwolla Flows',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Visual diagrams to help you understand how the Dwolla payment system works end-to-end.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Diagram 1: Customer Payment Flow
            _buildDiagram1(),
            const SizedBox(height: 32),

            // Diagram 2: Master Account Flow
            _buildDiagram2(),
            const SizedBox(height: 32),

            // Diagram 3: API Flow
            _buildDiagram3(),
            const SizedBox(height: 32),

            // Diagram 4: Webhook Flow
            _buildDiagram4(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagram1() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schema, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Diagram 1: Customer Payment Flow',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'The complete flow from customer creation to receiving payment',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Flow diagram
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FlowStep(
                    icon: Icons.person_add,
                    label: 'Create\nCustomer',
                    color: Colors.blue,
                    description: 'Register new customer with basic info',
                  ),
                  _FlowArrow(),
                  _FlowStep(
                    icon: Icons.verified_user,
                    label: 'KYC\nVerification',
                    color: Colors.orange,
                    description: 'Submit SSN, DOB, address for identity check',
                  ),
                  _FlowArrow(),
                  _FlowStep(
                    icon: Icons.account_balance,
                    label: 'Add Funding\nSource',
                    color: Colors.purple,
                    description: 'Link bank account for receiving funds',
                  ),
                  _FlowArrow(),
                  _FlowStep(
                    icon: Icons.send,
                    label: 'Receive\nTransfer',
                    color: Colors.green,
                    description: 'Money sent from master account',
                  ),
                  _FlowArrow(),
                  _FlowStep(
                    icon: Icons.webhook,
                    label: 'Webhook\nNotification',
                    color: Colors.teal,
                    description: 'Get real-time status updates',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Points:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('- Customers start as "unverified"'),
                  Text('- KYC verification is required to receive transfers'),
                  Text('- Bank account must be verified before receiving money'),
                  Text('- Webhooks notify you of status changes in real-time'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagram2() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.business, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Diagram 2: Master Account Payment Flow',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'How your master account sends payments to workers/customers',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Flow diagram
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FlowStep(
                    icon: Icons.business,
                    label: 'Master\nAccount',
                    color: Colors.green,
                    description: 'Your verified business account',
                  ),
                  _FlowArrow(),
                  _FlowStep(
                    icon: Icons.account_balance,
                    label: 'Verified\nBank',
                    color: Colors.green,
                    description: 'Your linked funding source',
                  ),
                  _FlowArrow(),
                  _FlowStep(
                    icon: Icons.attach_money,
                    label: 'Create\nTransfer',
                    color: Colors.orange,
                    description: 'Specify amount and recipient',
                  ),
                  _FlowArrow(),
                  _FlowStep(
                    icon: Icons.person,
                    label: 'Verified\nWorker',
                    color: Colors.blue,
                    description: 'Recipient must be verified',
                  ),
                  _FlowArrow(),
                  _FlowStep(
                    icon: Icons.check_circle,
                    label: 'Transfer\nComplete',
                    color: Colors.teal,
                    description: 'Money arrives in worker\'s bank',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requirements for Sending:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('1. Your master account must be verified'),
                  Text('2. Your funding source must be verified'),
                  Text('3. Recipient customer must be verified'),
                  Text('4. Recipient funding source must be verified'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagram3() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.api, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Diagram 3: API Request Flow',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'How your app communicates with Dwolla through the backend',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Flow diagram - vertical for this one
            Center(
              child: Column(
                children: [
                  _ApiFlowBox(
                    icon: Icons.phone_android,
                    label: 'Flutter Frontend',
                    color: Colors.blue,
                    items: ['User Interface', 'Stores API Key in localStorage', 'Never sees access token'],
                  ),
                  _VerticalArrow(label: 'HTTP Request'),
                  _ApiFlowBox(
                    icon: Icons.dns,
                    label: 'Node.js Backend',
                    color: Colors.green,
                    items: ['Stores credentials in memory', 'Manages OAuth tokens', 'Auto-refreshes expired tokens'],
                  ),
                  _VerticalArrow(label: 'Dwolla SDK'),
                  _ApiFlowBox(
                    icon: Icons.cloud,
                    label: 'Dwolla API',
                    color: Colors.orange,
                    items: ['Sandbox environment', 'Returns data + webhooks', 'Uses Location headers'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagram4() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.webhook, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Diagram 4: Webhook Event Types',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Common webhook events you\'ll receive from Dwolla',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Event categories
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _EventCategory(
                  title: 'Customer Events',
                  color: Colors.blue,
                  events: [
                    'customer_created',
                    'customer_verified',
                    'customer_suspended',
                    'customer_verification_document_needed',
                  ],
                ),
                _EventCategory(
                  title: 'Transfer Events',
                  color: Colors.green,
                  events: [
                    'transfer_created',
                    'transfer_completed',
                    'transfer_failed',
                    'transfer_cancelled',
                  ],
                ),
                _EventCategory(
                  title: 'Funding Source Events',
                  color: Colors.purple,
                  events: [
                    'funding_source_added',
                    'funding_source_verified',
                    'funding_source_removed',
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Webhook Best Practices:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('- Always return 200 OK to acknowledge receipt'),
                  Text('- Verify webhook signatures in production'),
                  Text('- Process webhooks idempotently (same event may arrive twice)'),
                  Text('- Use webhooks to update your local database'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String description;

  const _FlowStep({
    required this.icon,
    required this.label,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: description,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.arrow_forward,
        color: Colors.grey[400],
        size: 24,
      ),
    );
  }
}

class _VerticalArrow extends StatelessWidget {
  final String label;

  const _VerticalArrow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(Icons.arrow_downward, color: Colors.grey[400]),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiFlowBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final List<String> items;

  const _ApiFlowBox({
    required this.icon,
    required this.label,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _EventCategory extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> events;

  const _EventCategory({
    required this.title,
    required this.color,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...events.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    event,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
