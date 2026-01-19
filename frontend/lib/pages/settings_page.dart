/// Settings Page
///
/// Allows users to enter their Dwolla API Key and Secret.
/// These credentials are stored in localStorage on the frontend
/// and sent to the backend to obtain OAuth tokens.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dwolla_provider.dart';
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  bool _obscureSecret = true;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final api = context.read<ApiService>();
    final credentials = await api.getCredentials();
    if (credentials['apiKey'] != null) {
      _apiKeyController.text = credentials['apiKey']!;
    }
    if (credentials['apiSecret'] != null) {
      _apiSecretController.text = credentials['apiSecret']!;
    }
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isConnecting = true);

    final provider = context.read<DwollaProvider>();
    final success = await provider.configureCredentials(
      _apiKeyController.text.trim(),
      _apiSecretController.text.trim(),
    );

    setState(() => _isConnecting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connected to Dwolla successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to connect'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    final provider = context.read<DwollaProvider>();
    await provider.disconnect();
    _apiKeyController.clear();
    _apiSecretController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected from Dwolla')),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<DwollaProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Dwolla API Configuration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your Dwolla Sandbox API credentials to get started. '
                  'You can find these in your Dwolla Dashboard under Applications.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Connection Status
                _buildStatusCard(provider),
                const SizedBox(height: 24),

                // Credentials Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'API Credentials',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // API Key field
                          TextFormField(
                            controller: _apiKeyController,
                            decoration: const InputDecoration(
                              labelText: 'API Key',
                              hintText: 'Enter your Dwolla API Key',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.key),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'API Key is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // API Secret field
                          TextFormField(
                            controller: _apiSecretController,
                            obscureText: _obscureSecret,
                            decoration: InputDecoration(
                              labelText: 'API Secret',
                              hintText: 'Enter your Dwolla API Secret',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureSecret
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(
                                      () => _obscureSecret = !_obscureSecret);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'API Secret is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isConnecting ? null : _connect,
                                  icon: _isConnecting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.power),
                                  label: Text(
                                    _isConnecting
                                        ? 'Connecting...'
                                        : 'Save & Connect',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              if (provider.isConfigured) ...[
                                const SizedBox(width: 16),
                                OutlinedButton.icon(
                                  onPressed: _disconnect,
                                  icon: const Icon(Icons.power_off),
                                  label: const Text('Disconnect'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 24),
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Help section
                _buildHelpCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(DwollaProvider provider) {
    final isConnected = provider.isConfigured;

    return Card(
      color: isConnected ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isConnected ? Icons.check_circle : Icons.warning,
              color: isConnected ? Colors.green : Colors.orange,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Connected' : 'Not Connected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                  Text(
                    isConnected
                        ? 'Your Dwolla sandbox credentials are configured'
                        : 'Enter your API credentials to connect',
                    style: TextStyle(
                      color: isConnected ? Colors.green[600] : Colors.orange[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'How to get your API credentials',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('1. Log in to your Dwolla Dashboard'),
            const Text('2. Go to Applications > Create Application'),
            const Text('3. Select "Sandbox" environment'),
            const Text('4. Copy your Key and Secret'),
            const SizedBox(height: 12),
            Text(
              'Note: Never share your API Secret or use production '
              'credentials in this learning dashboard.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.blue[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
