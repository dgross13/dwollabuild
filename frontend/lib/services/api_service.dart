/// API Service
///
/// Handles all HTTP communication with the Node.js backend.
/// The frontend NEVER communicates directly with Dwolla - all requests
/// go through our backend which manages authentication and tokens.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Backend server URL - change this if running on different host/port
  static const String baseUrl = 'http://localhost:3000/api';

  // Keys for storing credentials in localStorage
  static const String _keyApiKey = 'dwolla_api_key';
  static const String _keyApiSecret = 'dwolla_api_secret';

  /// Save API credentials to localStorage
  Future<void> saveCredentials(String apiKey, String apiSecret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, apiKey);
    await prefs.setString(_keyApiSecret, apiSecret);
  }

  /// Get saved API credentials from localStorage
  Future<Map<String, String?>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'apiKey': prefs.getString(_keyApiKey),
      'apiSecret': prefs.getString(_keyApiSecret),
    };
  }

  /// Clear saved credentials
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyApiSecret);
  }

  // --------------------------------------------------------------------------
  // Configuration Endpoints
  // --------------------------------------------------------------------------

  /// Configure Dwolla credentials on the backend
  /// This sends the API key and secret to the backend which will
  /// obtain an OAuth token and store it in memory
  Future<Map<String, dynamic>> configureCredentials(
      String apiKey, String apiSecret) async {
    final response = await http.post(
      Uri.parse('$baseUrl/config'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'key': apiKey,
        'secret': apiSecret,
      }),
    );

    if (response.statusCode == 200) {
      // Save to localStorage on success
      await saveCredentials(apiKey, apiSecret);
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to configure credentials');
    }
  }

  /// Check if backend is configured with valid credentials
  Future<Map<String, dynamic>> getConfigStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/config/status'));
    return jsonDecode(response.body);
  }

  // --------------------------------------------------------------------------
  // Customer Endpoints
  // --------------------------------------------------------------------------

  /// Create a new customer
  /// Returns the created customer data
  Future<Map<String, dynamic>> createCustomer({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String type = 'personal',
    String? businessName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'type': type,
        'businessName': businessName,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to create customer');
    }
  }

  /// Get all customers
  Future<List<Map<String, dynamic>>> getCustomers({bool refresh = false}) async {
    final url = refresh
        ? '$baseUrl/customers?refresh=true'
        : '$baseUrl/customers';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['customers']);
    } else {
      throw Exception('Failed to fetch customers');
    }
  }

  /// Get a specific customer by ID
  Future<Map<String, dynamic>> getCustomer(String customerId) async {
    final response = await http.get(Uri.parse('$baseUrl/customers/$customerId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to fetch customer');
    }
  }

  /// Submit KYC verification for a customer
  Future<Map<String, dynamic>> verifyCustomer(
    String customerId, {
    String? ssn,
    String? dateOfBirth,
    String? address1,
    String? city,
    String? state,
    String? postalCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers/$customerId/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ssn': ssn,
        'dateOfBirth': dateOfBirth,
        'address1': address1,
        'city': city,
        'state': state,
        'postalCode': postalCode,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to verify customer');
    }
  }

  /// Get customers eligible for payouts (verified + verified funding source)
  Future<List<Map<String, dynamic>>> getEligibleCustomers() async {
    final response = await http.get(Uri.parse('$baseUrl/customers/eligible'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['customers']);
    } else {
      throw Exception('Failed to fetch eligible customers');
    }
  }

  // --------------------------------------------------------------------------
  // Funding Source Endpoints
  // --------------------------------------------------------------------------

  /// Add a funding source to a customer
  Future<Map<String, dynamic>> addFundingSource(
    String customerId, {
    required String name,
    String? routingNumber,
    String? accountNumber,
    String accountType = 'checking',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers/$customerId/funding-sources'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'routingNumber': routingNumber,
        'accountNumber': accountNumber,
        'accountType': accountType,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to add funding source');
    }
  }

  /// Get funding sources for a customer
  Future<List<Map<String, dynamic>>> getCustomerFundingSources(
      String customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers/$customerId/funding-sources'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['fundingSources']);
    } else {
      throw Exception('Failed to fetch funding sources');
    }
  }

  /// Get IAV token for instant account verification
  Future<String> getIavToken(String customerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers/$customerId/iav-token'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      throw Exception('Failed to get IAV token');
    }
  }

  // --------------------------------------------------------------------------
  // Master Account Endpoints
  // --------------------------------------------------------------------------

  /// Get master account info
  Future<Map<String, dynamic>> getAccount() async {
    final response = await http.get(Uri.parse('$baseUrl/me'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch account');
    }
  }

  /// Get master account funding sources
  Future<List<Map<String, dynamic>>> getAccountFundingSources() async {
    final response = await http.get(Uri.parse('$baseUrl/me/funding-sources'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['fundingSources']);
    } else {
      throw Exception('Failed to fetch account funding sources');
    }
  }

  /// Get master account balance
  Future<Map<String, dynamic>> getAccountBalance() async {
    final response = await http.get(Uri.parse('$baseUrl/me/balance'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch balance');
    }
  }

  // --------------------------------------------------------------------------
  // Transfer Endpoints
  // --------------------------------------------------------------------------

  /// Create a transfer (payout)
  Future<Map<String, dynamic>> createTransfer({
    required String sourceFundingSourceUrl,
    required String destinationFundingSourceUrl,
    required double amount,
    String currency = 'USD',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transfers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sourceFundingSourceUrl': sourceFundingSourceUrl,
        'destinationFundingSourceUrl': destinationFundingSourceUrl,
        'amount': amount,
        'currency': currency,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to create transfer');
    }
  }

  /// Get all transfers
  Future<List<Map<String, dynamic>>> getTransfers() async {
    final response = await http.get(Uri.parse('$baseUrl/transfers'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['transfers']);
    } else {
      throw Exception('Failed to fetch transfers');
    }
  }

  /// Get a specific transfer
  Future<Map<String, dynamic>> getTransfer(String transferId) async {
    final response = await http.get(Uri.parse('$baseUrl/transfers/$transferId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch transfer');
    }
  }

  // --------------------------------------------------------------------------
  // Webhook Endpoints
  // --------------------------------------------------------------------------

  /// Get all received webhook events
  Future<List<Map<String, dynamic>>> getWebhooks() async {
    final response = await http.get(Uri.parse('$baseUrl/webhooks'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['webhooks']);
    } else {
      throw Exception('Failed to fetch webhooks');
    }
  }

  /// Clear all webhooks
  Future<void> clearWebhooks() async {
    await http.delete(Uri.parse('$baseUrl/webhooks'));
  }
}
