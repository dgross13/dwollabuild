/// Dwolla Provider
///
/// State management for the entire app using ChangeNotifier.
/// Holds all the data fetched from the backend and provides methods
/// to interact with the Dwolla API through the backend.

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class DwollaProvider extends ChangeNotifier {
  final ApiService _api;

  DwollaProvider(this._api);

  // --------------------------------------------------------------------------
  // State Variables
  // --------------------------------------------------------------------------

  // Configuration state
  bool _isConfigured = false;
  bool _isLoading = false;
  String? _error;

  // Customer data
  List<Map<String, dynamic>> _customers = [];

  // Eligible customers (verified + verified funding source)
  List<Map<String, dynamic>> _eligibleCustomers = [];

  // Transfer data
  List<Map<String, dynamic>> _transfers = [];

  // Webhook data
  List<Map<String, dynamic>> _webhooks = [];

  // Account data
  Map<String, dynamic>? _account;
  List<Map<String, dynamic>> _accountFundingSources = [];
  Map<String, dynamic>? _accountBalance;

  // --------------------------------------------------------------------------
  // Getters
  // --------------------------------------------------------------------------

  bool get isConfigured => _isConfigured;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Map<String, dynamic>> get customers => _customers;
  List<Map<String, dynamic>> get eligibleCustomers => _eligibleCustomers;
  List<Map<String, dynamic>> get transfers => _transfers;
  List<Map<String, dynamic>> get webhooks => _webhooks;

  Map<String, dynamic>? get account => _account;
  List<Map<String, dynamic>> get accountFundingSources => _accountFundingSources;
  Map<String, dynamic>? get accountBalance => _accountBalance;

  // --------------------------------------------------------------------------
  // Configuration Methods
  // --------------------------------------------------------------------------

  /// Initialize the provider by checking stored credentials
  Future<void> initialize() async {
    try {
      final credentials = await _api.getCredentials();
      if (credentials['apiKey'] != null && credentials['apiSecret'] != null) {
        // Try to configure with stored credentials
        await configureCredentials(
          credentials['apiKey']!,
          credentials['apiSecret']!,
        );
      }
    } catch (e) {
      // Credentials might be invalid, just continue unconfigured
      _isConfigured = false;
    }
  }

  /// Configure Dwolla credentials
  Future<bool> configureCredentials(String apiKey, String apiSecret) async {
    _setLoading(true);
    _clearError();

    try {
      await _api.configureCredentials(apiKey, apiSecret);
      _isConfigured = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check backend configuration status
  Future<Map<String, dynamic>> checkConfigStatus() async {
    try {
      final status = await _api.getConfigStatus();
      _isConfigured = status['isConfigured'] == true;
      notifyListeners();
      return status;
    } catch (e) {
      return {'isConfigured': false, 'error': e.toString()};
    }
  }

  /// Disconnect and clear credentials
  Future<void> disconnect() async {
    await _api.clearCredentials();
    _isConfigured = false;
    _customers = [];
    _transfers = [];
    _webhooks = [];
    _account = null;
    _accountFundingSources = [];
    _accountBalance = null;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // Customer Methods
  // --------------------------------------------------------------------------

  /// Fetch all customers
  Future<void> fetchCustomers({bool refresh = false}) async {
    _setLoading(true);
    _clearError();

    try {
      _customers = await _api.getCustomers(refresh: refresh);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new customer
  Future<Map<String, dynamic>?> createCustomer({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String type = 'personal',
    String? businessName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _api.createCustomer(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        type: type,
        businessName: businessName,
      );
      // Refresh customers list
      await fetchCustomers();
      return result;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify a customer (KYC)
  Future<bool> verifyCustomer(
    String customerId, {
    String? ssn,
    String? dateOfBirth,
    String? address1,
    String? city,
    String? state,
    String? postalCode,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _api.verifyCustomer(
        customerId,
        ssn: ssn,
        dateOfBirth: dateOfBirth,
        address1: address1,
        city: city,
        state: state,
        postalCode: postalCode,
      );
      // Refresh customers list
      await fetchCustomers(refresh: true);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get funding sources for a customer
  Future<List<Map<String, dynamic>>> getCustomerFundingSources(
      String customerId) async {
    try {
      return await _api.getCustomerFundingSources(customerId);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Add funding source to a customer
  Future<bool> addFundingSource(
    String customerId, {
    required String name,
    String? routingNumber,
    String? accountNumber,
    String accountType = 'checking',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _api.addFundingSource(
        customerId,
        name: name,
        routingNumber: routingNumber,
        accountNumber: accountNumber,
        accountType: accountType,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch eligible customers (verified + verified funding source)
  Future<void> fetchEligibleCustomers() async {
    try {
      _eligibleCustomers = await _api.getEligibleCustomers();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Transfer Methods
  // --------------------------------------------------------------------------

  /// Fetch all transfers
  Future<void> fetchTransfers() async {
    try {
      _transfers = await _api.getTransfers();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Create a transfer (payout)
  Future<bool> createTransfer({
    required String sourceFundingSourceUrl,
    required String destinationFundingSourceUrl,
    required double amount,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _api.createTransfer(
        sourceFundingSourceUrl: sourceFundingSourceUrl,
        destinationFundingSourceUrl: destinationFundingSourceUrl,
        amount: amount,
      );
      // Refresh transfers list
      await fetchTransfers();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --------------------------------------------------------------------------
  // Webhook Methods
  // --------------------------------------------------------------------------

  /// Fetch all webhooks
  Future<void> fetchWebhooks() async {
    try {
      _webhooks = await _api.getWebhooks();
      notifyListeners();
    } catch (e) {
      // Silently fail for webhooks polling
    }
  }

  /// Clear all webhooks
  Future<void> clearWebhooks() async {
    try {
      await _api.clearWebhooks();
      _webhooks = [];
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Account Methods
  // --------------------------------------------------------------------------

  /// Fetch master account info
  Future<void> fetchAccount() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _api.getAccount();
      _account = result['account'];
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch master account funding sources
  Future<void> fetchAccountFundingSources() async {
    try {
      _accountFundingSources = await _api.getAccountFundingSources();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Fetch master account balance
  Future<void> fetchAccountBalance() async {
    try {
      _accountBalance = await _api.getAccountBalance();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Refresh all account data
  Future<void> refreshAccount() async {
    await Future.wait([
      fetchAccount(),
      fetchAccountFundingSources(),
      fetchAccountBalance(),
    ]);
  }

  // --------------------------------------------------------------------------
  // Helper Methods
  // --------------------------------------------------------------------------

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    // Clean up error message
    _error = error.replaceAll('Exception: ', '');
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
