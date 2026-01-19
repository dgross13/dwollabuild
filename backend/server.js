/**
 * Dwolla Sandbox Practice Dashboard - Backend Server
 *
 * This server handles all Dwolla API interactions and provides endpoints
 * for the Flutter frontend to interact with Dwolla's sandbox environment.
 *
 * Key Features:
 * - OAuth token management with automatic refresh
 * - Customer creation and verification
 * - Funding source management
 * - Transfer/payout processing
 * - Webhook event handling
 */

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const crypto = require('crypto');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// ============================================================================
// IN-MEMORY STORAGE
// ============================================================================

/**
 * Storage for Dwolla configuration and tokens
 * - key: Dwolla API Key
 * - secret: Dwolla API Secret
 * - accessToken: Current OAuth access token
 * - expiresIn: Token lifetime in seconds
 * - tokenCreatedAt: Timestamp when token was created
 */
let dwollaConfig = {
  key: null,
  secret: null,
  accessToken: null,
  expiresIn: null,
  tokenCreatedAt: null
};

/**
 * Storage for customers created through the dashboard
 * Used for duplicate checking and quick lookups
 */
let customersStore = [];

/**
 * Storage for transfers created through the dashboard
 */
let transfersStore = [];

/**
 * Storage for webhook events received from Dwolla
 */
let webhooksStore = [];

/**
 * Dwolla SDK client instance
 */
let dwollaClient = null;

// ============================================================================
// DWOLLA SDK & TOKEN MANAGEMENT
// ============================================================================

/**
 * Initialize the Dwolla client with provided credentials
 * Uses sandbox environment for learning purposes
 */
function initializeDwollaClient(key, secret) {
  const Client = require('dwolla-v2').Client;

  // Initialize Dwolla client for SANDBOX environment
  // In production, you would use 'production' instead of 'sandbox'
  dwollaClient = new Client({
    key: key,
    secret: secret,
    environment: 'sandbox'
  });

  console.log('[Dwolla] Client initialized for sandbox environment');
}

/**
 * Get a valid access token, refreshing if expired
 *
 * Dwolla OAuth tokens expire after a set time (usually 1 hour).
 * This function checks if the current token is still valid,
 * and requests a new one if it's expired.
 *
 * @returns {Promise<string>} Valid access token
 */
async function getValidAccessToken() {
  if (!dwollaConfig.key || !dwollaConfig.secret) {
    throw new Error('Dwolla credentials not configured. Please set up API key and secret.');
  }

  // Check if we have a valid token that hasn't expired
  // We subtract 60 seconds as a buffer to ensure the token doesn't expire mid-request
  const now = Date.now();
  const tokenAge = (now - dwollaConfig.tokenCreatedAt) / 1000; // Convert to seconds
  const isExpired = !dwollaConfig.accessToken || tokenAge >= (dwollaConfig.expiresIn - 60);

  if (isExpired) {
    console.log('[Dwolla] Token expired or missing, requesting new token...');

    // Request new OAuth token using client credentials grant
    // This is the standard way to authenticate with Dwolla's API
    try {
      const response = await dwollaClient.auth.client();

      dwollaConfig.accessToken = response.access_token;
      dwollaConfig.expiresIn = response.expires_in;
      dwollaConfig.tokenCreatedAt = Date.now();

      console.log('[Dwolla] New token obtained, expires in:', response.expires_in, 'seconds');
    } catch (error) {
      console.error('[Dwolla] Token request failed:', error.message);
      throw new Error('Failed to obtain Dwolla access token. Check your API credentials.');
    }
  }

  return dwollaConfig.accessToken;
}

/**
 * Make an authenticated request to the Dwolla API
 * Automatically handles token refresh before each request
 *
 * @param {string} method - HTTP method (get, post, delete)
 * @param {string} url - Dwolla API endpoint URL
 * @param {object} body - Request body (for POST requests)
 * @returns {Promise<object>} API response
 */
async function dwollaRequest(method, url, body = null) {
  // Ensure we have a valid token before making the request
  await getValidAccessToken();

  try {
    let response;

    if (method === 'get') {
      // GET request - fetching data from Dwolla
      response = await dwollaClient.get(url);
    } else if (method === 'post') {
      // POST request - creating resources in Dwolla
      response = await dwollaClient.post(url, body);
    } else if (method === 'delete') {
      // DELETE request - removing resources from Dwolla
      response = await dwollaClient.delete(url);
    }

    return response;
  } catch (error) {
    console.error(`[Dwolla] API ${method.toUpperCase()} ${url} failed:`, error.message);
    throw error;
  }
}

// ============================================================================
// API ROUTES
// ============================================================================

// ----------------------------------------------------------------------------
// CONFIGURATION ENDPOINTS
// ----------------------------------------------------------------------------

/**
 * POST /api/config
 * Save Dwolla API credentials and initialize the client
 *
 * This endpoint receives the API key and secret from the frontend,
 * stores them in memory, initializes the Dwolla client, and obtains
 * an initial access token to verify the credentials are valid.
 */
app.post('/api/config', async (req, res) => {
  try {
    const { key, secret } = req.body;

    if (!key || !secret) {
      return res.status(400).json({
        error: 'Both API key and secret are required'
      });
    }

    // Store credentials in memory (NOT persisted, NOT hardcoded)
    dwollaConfig.key = key;
    dwollaConfig.secret = secret;

    // Initialize the Dwolla SDK client
    initializeDwollaClient(key, secret);

    // Immediately request an access token to verify credentials
    await getValidAccessToken();

    // Clear any previous data when reconfiguring
    customersStore = [];
    transfersStore = [];
    webhooksStore = [];

    console.log('[Config] Dwolla credentials configured successfully');

    res.json({
      success: true,
      message: 'Dwolla credentials configured successfully',
      tokenExpiresIn: dwollaConfig.expiresIn
    });
  } catch (error) {
    console.error('[Config] Error:', error.message);
    res.status(400).json({
      error: error.message || 'Failed to configure Dwolla credentials'
    });
  }
});

/**
 * GET /api/config/status
 * Check if Dwolla is configured and token status
 */
app.get('/api/config/status', (req, res) => {
  const isConfigured = !!(dwollaConfig.key && dwollaConfig.secret);
  const hasToken = !!dwollaConfig.accessToken;

  let tokenStatus = 'none';
  if (hasToken) {
    const now = Date.now();
    const tokenAge = (now - dwollaConfig.tokenCreatedAt) / 1000;
    const remainingTime = dwollaConfig.expiresIn - tokenAge;
    tokenStatus = remainingTime > 0 ? 'valid' : 'expired';
  }

  res.json({
    isConfigured,
    hasToken,
    tokenStatus,
    remainingTokenTime: hasToken ? Math.max(0, dwollaConfig.expiresIn - ((Date.now() - dwollaConfig.tokenCreatedAt) / 1000)) : 0
  });
});

// ----------------------------------------------------------------------------
// CUSTOMER ENDPOINTS
// ----------------------------------------------------------------------------

/**
 * POST /api/customers
 * Create a new customer in Dwolla
 *
 * This endpoint:
 * 1. Validates that email/phone don't already exist (duplicate check)
 * 2. Creates the customer in Dwolla
 * 3. Follows the Location header to get the created customer details
 * 4. Stores minimal metadata locally for future duplicate checks
 */
app.post('/api/customers', async (req, res) => {
  try {
    const { firstName, lastName, email, phone, type, businessName } = req.body;

    // Validation: Required fields
    if (!firstName || !lastName || !email) {
      return res.status(400).json({
        error: 'First name, last name, and email are required'
      });
    }

    // Validation: Check for duplicate email in our local store
    const emailExists = customersStore.some(c => c.email.toLowerCase() === email.toLowerCase());
    if (emailExists) {
      return res.status(400).json({
        error: 'A customer with this email already exists'
      });
    }

    // Validation: Check for duplicate phone if provided
    if (phone) {
      const phoneExists = customersStore.some(c => c.phone === phone);
      if (phoneExists) {
        return res.status(400).json({
          error: 'A customer with this phone number already exists'
        });
      }
    }

    // Build the customer request body based on type
    // Dwolla supports different customer types with different required fields
    let customerBody = {
      firstName,
      lastName,
      email
    };

    // Add optional fields if provided
    if (phone) customerBody.phone = phone;

    // For business customers, additional fields are required
    if (type === 'business') {
      customerBody.type = 'business';
      customerBody.businessName = businessName || `${firstName} ${lastName} Business`;
      customerBody.businessType = 'soleProprietorship'; // Simplified for sandbox
    }

    console.log('[Customers] Creating customer:', email);

    // DWOLLA API CALL: Create customer
    // POST https://api-sandbox.dwolla.com/customers
    // Returns 201 with Location header containing the new customer URL
    const response = await dwollaRequest('post', 'customers', customerBody);

    // The response headers contain the Location of the created resource
    // Dwolla returns 201 with empty body, so we need to follow the Location
    const customerUrl = response.headers.get('location');

    console.log('[Customers] Customer created, fetching details from:', customerUrl);

    // DWOLLA API CALL: Fetch created customer details
    // GET the customer URL from Location header
    const customerDetails = await dwollaRequest('get', customerUrl);
    const customer = customerDetails.body;

    // Extract customer ID from the URL
    // URL format: https://api-sandbox.dwolla.com/customers/{id}
    const customerId = customerUrl.split('/').pop();

    // Store minimal metadata locally for duplicate checking and quick lookups
    const customerRecord = {
      id: customerId,
      url: customerUrl,
      firstName: customer.firstName,
      lastName: customer.lastName,
      email: customer.email,
      phone: phone || null,
      type: customer.type || 'personal',
      status: customer.status, // unverified, verified, document, retry, suspended
      createdAt: customer.created
    };

    customersStore.push(customerRecord);

    console.log('[Customers] Customer stored locally:', customerId, 'Status:', customer.status);

    res.status(201).json({
      success: true,
      customer: customerRecord
    });
  } catch (error) {
    console.error('[Customers] Error creating customer:', error.message);

    // Parse Dwolla error messages for user-friendly display
    let errorMessage = 'Failed to create customer';
    if (error.body && error.body._embedded && error.body._embedded.errors) {
      errorMessage = error.body._embedded.errors.map(e => e.message).join('. ');
    } else if (error.message) {
      errorMessage = error.message;
    }

    res.status(400).json({ error: errorMessage });
  }
});

/**
 * GET /api/customers
 * List all customers (from local store with fresh status from Dwolla)
 */
app.get('/api/customers', async (req, res) => {
  try {
    // Optionally refresh status from Dwolla for each customer
    // For performance, we'll return local data but include an option to refresh
    const includeRefresh = req.query.refresh === 'true';

    if (includeRefresh && customersStore.length > 0) {
      // Refresh status for all customers from Dwolla
      for (let i = 0; i < customersStore.length; i++) {
        try {
          const details = await dwollaRequest('get', customersStore[i].url);
          customersStore[i].status = details.body.status;
        } catch (err) {
          console.warn('[Customers] Failed to refresh status for:', customersStore[i].id);
        }
      }
    }

    res.json({ customers: customersStore });
  } catch (error) {
    console.error('[Customers] Error listing customers:', error.message);
    res.status(500).json({ error: 'Failed to list customers' });
  }
});

/**
 * GET /api/customers/:id
 * Get a specific customer's details from Dwolla
 */
app.get('/api/customers/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Find customer in local store
    const localCustomer = customersStore.find(c => c.id === id);
    if (!localCustomer) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    // DWOLLA API CALL: Get customer details
    // GET https://api-sandbox.dwolla.com/customers/{id}
    const response = await dwollaRequest('get', localCustomer.url);
    const customer = response.body;

    // Update local store with fresh status
    localCustomer.status = customer.status;

    res.json({ customer: { ...localCustomer, dwollaData: customer } });
  } catch (error) {
    console.error('[Customers] Error getting customer:', error.message);
    res.status(500).json({ error: 'Failed to get customer details' });
  }
});

/**
 * POST /api/customers/:id/verify
 * Submit verification information for a customer (KYC)
 *
 * In sandbox, this simulates the verification process.
 * For unverified customers, we can upgrade them by providing SSN/address info.
 */
app.post('/api/customers/:id/verify', async (req, res) => {
  try {
    const { id } = req.params;
    const { ssn, dateOfBirth, address1, city, state, postalCode } = req.body;

    // Find customer in local store
    const localCustomer = customersStore.find(c => c.id === id);
    if (!localCustomer) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    console.log('[Customers] Verifying customer:', id);

    // For sandbox testing, we'll update the customer with verification info
    // In sandbox, using specific SSN patterns triggers different verification statuses:
    // - SSN ending in 0000: verified
    // - SSN ending in 0001: retry status
    // - SSN ending in 0002: document status
    // - SSN ending in 0003: suspended status

    const verificationBody = {
      firstName: localCustomer.firstName,
      lastName: localCustomer.lastName,
      email: localCustomer.email,
      type: 'personal',
      address1: address1 || '123 Main St',
      city: city || 'San Francisco',
      state: state || 'CA',
      postalCode: postalCode || '94105',
      dateOfBirth: dateOfBirth || '1990-01-01',
      ssn: ssn || '1234' // Last 4 digits for personal verified customers
    };

    // DWOLLA API CALL: Update customer with verification info
    // POST to the customer URL with additional KYC data
    // This upgrades an unverified customer to verified (in sandbox with correct SSN)
    await dwollaRequest('post', localCustomer.url, verificationBody);

    // Fetch updated customer to get new status
    const updatedResponse = await dwollaRequest('get', localCustomer.url);
    const updatedCustomer = updatedResponse.body;

    // Update local store
    localCustomer.status = updatedCustomer.status;

    console.log('[Customers] Customer verification submitted, new status:', updatedCustomer.status);

    res.json({
      success: true,
      message: `Verification submitted. Customer status: ${updatedCustomer.status}`,
      customer: localCustomer
    });
  } catch (error) {
    console.error('[Customers] Error verifying customer:', error.message);

    let errorMessage = 'Failed to verify customer';
    if (error.body && error.body._embedded && error.body._embedded.errors) {
      errorMessage = error.body._embedded.errors.map(e => e.message).join('. ');
    }

    res.status(400).json({ error: errorMessage });
  }
});

// ----------------------------------------------------------------------------
// FUNDING SOURCE ENDPOINTS
// ----------------------------------------------------------------------------

/**
 * POST /api/customers/:id/funding-sources
 * Add a funding source to a customer
 *
 * In sandbox, we can create funding sources directly without going through
 * the full IAV (Instant Account Verification) flow.
 */
app.post('/api/customers/:id/funding-sources', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, routingNumber, accountNumber, accountType } = req.body;

    // Find customer in local store
    const localCustomer = customersStore.find(c => c.id === id);
    if (!localCustomer) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    // Validation
    if (!name) {
      return res.status(400).json({ error: 'Account nickname (name) is required' });
    }

    console.log('[Funding] Adding funding source for customer:', id);

    // Build funding source body
    // For sandbox, we can use test routing/account numbers
    const fundingSourceBody = {
      routingNumber: routingNumber || '222222226', // Sandbox test routing number
      accountNumber: accountNumber || '123456789', // Sandbox test account number
      bankAccountType: accountType || 'checking',
      name: name
    };

    // DWOLLA API CALL: Create funding source
    // POST https://api-sandbox.dwolla.com/customers/{id}/funding-sources
    const response = await dwollaRequest(
      'post',
      `${localCustomer.url}/funding-sources`,
      fundingSourceBody
    );

    // Get the created funding source URL from Location header
    const fundingSourceUrl = response.headers.get('location');

    console.log('[Funding] Funding source created:', fundingSourceUrl);

    // DWOLLA API CALL: Fetch funding source details
    const fsResponse = await dwollaRequest('get', fundingSourceUrl);
    const fundingSource = fsResponse.body;

    res.status(201).json({
      success: true,
      fundingSource: {
        id: fundingSourceUrl.split('/').pop(),
        url: fundingSourceUrl,
        name: fundingSource.name,
        type: fundingSource.type,
        bankAccountType: fundingSource.bankAccountType,
        status: fundingSource.status, // verified, unverified
        bankName: fundingSource.bankName
      }
    });
  } catch (error) {
    console.error('[Funding] Error adding funding source:', error.message);

    let errorMessage = 'Failed to add funding source';
    if (error.body && error.body._embedded && error.body._embedded.errors) {
      errorMessage = error.body._embedded.errors.map(e => e.message).join('. ');
    }

    res.status(400).json({ error: errorMessage });
  }
});

/**
 * GET /api/customers/:id/funding-sources
 * List funding sources for a customer
 */
app.get('/api/customers/:id/funding-sources', async (req, res) => {
  try {
    const { id } = req.params;

    // Find customer in local store
    const localCustomer = customersStore.find(c => c.id === id);
    if (!localCustomer) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    // DWOLLA API CALL: List funding sources
    // GET https://api-sandbox.dwolla.com/customers/{id}/funding-sources
    const response = await dwollaRequest('get', `${localCustomer.url}/funding-sources`);

    const fundingSources = response.body._embedded['funding-sources']
      .filter(fs => !fs.removed) // Filter out removed funding sources
      .map(fs => ({
        id: fs._links.self.href.split('/').pop(),
        url: fs._links.self.href,
        name: fs.name,
        type: fs.type,
        bankAccountType: fs.bankAccountType,
        status: fs.status,
        bankName: fs.bankName,
        created: fs.created
      }));

    res.json({ fundingSources });
  } catch (error) {
    console.error('[Funding] Error listing funding sources:', error.message);
    res.status(500).json({ error: 'Failed to list funding sources' });
  }
});

/**
 * POST /api/customers/:id/iav-token
 * Generate an IAV token for Instant Account Verification
 * Used when you want to use Dwolla's IAV drop-in component
 */
app.post('/api/customers/:id/iav-token', async (req, res) => {
  try {
    const { id } = req.params;

    const localCustomer = customersStore.find(c => c.id === id);
    if (!localCustomer) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    // DWOLLA API CALL: Create IAV token
    // POST https://api-sandbox.dwolla.com/customers/{id}/iav-token
    const response = await dwollaRequest('post', `${localCustomer.url}/iav-token`);

    res.json({
      token: response.body.token
    });
  } catch (error) {
    console.error('[Funding] Error creating IAV token:', error.message);
    res.status(500).json({ error: 'Failed to create IAV token' });
  }
});

// ----------------------------------------------------------------------------
// MASTER ACCOUNT (YOUR ACCOUNT) ENDPOINTS
// ----------------------------------------------------------------------------

/**
 * GET /api/me
 * Get the master account (your Dwolla account) details
 */
app.get('/api/me', async (req, res) => {
  try {
    // DWOLLA API CALL: Get root/account info
    // GET https://api-sandbox.dwolla.com/
    const rootResponse = await dwollaRequest('get', '/');
    const accountUrl = rootResponse.body._links.account.href;

    // DWOLLA API CALL: Get account details
    const accountResponse = await dwollaRequest('get', accountUrl);
    const account = accountResponse.body;

    res.json({
      account: {
        id: accountUrl.split('/').pop(),
        url: accountUrl,
        name: account.name,
        type: account.type
      }
    });
  } catch (error) {
    console.error('[Account] Error getting account:', error.message);
    res.status(500).json({ error: 'Failed to get account details' });
  }
});

/**
 * GET /api/me/funding-sources
 * Get the master account's funding sources
 */
app.get('/api/me/funding-sources', async (req, res) => {
  try {
    // Get account URL first
    const rootResponse = await dwollaRequest('get', '/');
    const accountUrl = rootResponse.body._links.account.href;

    // DWOLLA API CALL: List account funding sources
    // GET https://api-sandbox.dwolla.com/accounts/{id}/funding-sources
    const response = await dwollaRequest('get', `${accountUrl}/funding-sources`);

    const fundingSources = response.body._embedded['funding-sources']
      .filter(fs => !fs.removed)
      .map(fs => ({
        id: fs._links.self.href.split('/').pop(),
        url: fs._links.self.href,
        name: fs.name,
        type: fs.type,
        bankAccountType: fs.bankAccountType,
        status: fs.status,
        bankName: fs.bankName
      }));

    res.json({ fundingSources });
  } catch (error) {
    console.error('[Account] Error listing funding sources:', error.message);
    res.status(500).json({ error: 'Failed to list funding sources' });
  }
});

/**
 * GET /api/me/balance
 * Get the master account's balance (if available)
 */
app.get('/api/me/balance', async (req, res) => {
  try {
    // Get account URL
    const rootResponse = await dwollaRequest('get', '/');
    const accountUrl = rootResponse.body._links.account.href;

    // Get funding sources to find balance
    const fsResponse = await dwollaRequest('get', `${accountUrl}/funding-sources`);

    // Find the balance funding source
    const balanceSource = fsResponse.body._embedded['funding-sources']
      .find(fs => fs.type === 'balance');

    if (balanceSource) {
      // DWOLLA API CALL: Get balance
      const balanceUrl = balanceSource._links.balance?.href;
      if (balanceUrl) {
        const balanceResponse = await dwollaRequest('get', balanceUrl);
        res.json({
          balance: balanceResponse.body.balance,
          total: balanceResponse.body.total
        });
        return;
      }
    }

    res.json({ balance: null, message: 'Balance not available for this account type' });
  } catch (error) {
    console.error('[Account] Error getting balance:', error.message);
    res.status(500).json({ error: 'Failed to get balance' });
  }
});

// ----------------------------------------------------------------------------
// TRANSFER ENDPOINTS
// ----------------------------------------------------------------------------

/**
 * POST /api/transfers
 * Create a transfer (payout) from master account to a customer
 *
 * Validates that both source and destination are eligible for transfers
 */
app.post('/api/transfers', async (req, res) => {
  try {
    const { sourceFundingSourceUrl, destinationFundingSourceUrl, amount, currency } = req.body;

    // Validation
    if (!sourceFundingSourceUrl || !destinationFundingSourceUrl || !amount) {
      return res.status(400).json({
        error: 'Source funding source, destination funding source, and amount are required'
      });
    }

    if (amount <= 0) {
      return res.status(400).json({ error: 'Amount must be greater than 0' });
    }

    console.log('[Transfers] Creating transfer:', amount, currency || 'USD');

    // Validate source funding source
    try {
      const sourceFs = await dwollaRequest('get', sourceFundingSourceUrl);
      if (sourceFs.body.status !== 'verified') {
        return res.status(400).json({
          error: 'Source funding source is not verified. Only verified funding sources can send transfers.'
        });
      }
    } catch (err) {
      return res.status(400).json({ error: 'Invalid source funding source' });
    }

    // Validate destination funding source
    try {
      const destFs = await dwollaRequest('get', destinationFundingSourceUrl);
      if (destFs.body.status !== 'verified') {
        return res.status(400).json({
          error: 'Destination funding source is not verified. Only verified funding sources can receive transfers.'
        });
      }
    } catch (err) {
      return res.status(400).json({ error: 'Invalid destination funding source' });
    }

    // Build transfer body
    const transferBody = {
      _links: {
        source: { href: sourceFundingSourceUrl },
        destination: { href: destinationFundingSourceUrl }
      },
      amount: {
        currency: currency || 'USD',
        value: amount.toString()
      }
    };

    // DWOLLA API CALL: Create transfer
    // POST https://api-sandbox.dwolla.com/transfers
    const response = await dwollaRequest('post', 'transfers', transferBody);

    // Get transfer URL from Location header
    const transferUrl = response.headers.get('location');

    console.log('[Transfers] Transfer created:', transferUrl);

    // DWOLLA API CALL: Get transfer details
    const transferResponse = await dwollaRequest('get', transferUrl);
    const transfer = transferResponse.body;

    // Store transfer locally
    const transferRecord = {
      id: transferUrl.split('/').pop(),
      url: transferUrl,
      status: transfer.status, // pending, processed, cancelled, failed
      amount: transfer.amount,
      created: transfer.created,
      sourceFundingSourceUrl,
      destinationFundingSourceUrl
    };

    transfersStore.push(transferRecord);

    res.status(201).json({
      success: true,
      transfer: transferRecord
    });
  } catch (error) {
    console.error('[Transfers] Error creating transfer:', error.message);

    // Parse Dwolla error for user-friendly message
    let errorMessage = 'Failed to create transfer';
    if (error.body && error.body._embedded && error.body._embedded.errors) {
      const errors = error.body._embedded.errors;
      errorMessage = errors.map(e => {
        // Translate common errors to friendly messages
        if (e.code === 'InsufficientFunds') {
          return 'Insufficient funds in source account.';
        }
        if (e.code === 'Invalid' && e.path === '/_links/source/href') {
          return 'Source funding source is not verified.';
        }
        if (e.code === 'Invalid' && e.path === '/_links/destination/href') {
          return 'Destination funding source is not verified.';
        }
        return e.message;
      }).join('. ');
    }

    res.status(400).json({ error: errorMessage });
  }
});

/**
 * GET /api/transfers
 * List all transfers with current status
 */
app.get('/api/transfers', async (req, res) => {
  try {
    // Refresh status for all transfers from Dwolla
    for (let i = 0; i < transfersStore.length; i++) {
      try {
        const response = await dwollaRequest('get', transfersStore[i].url);
        transfersStore[i].status = response.body.status;
      } catch (err) {
        console.warn('[Transfers] Failed to refresh status for:', transfersStore[i].id);
      }
    }

    res.json({ transfers: transfersStore });
  } catch (error) {
    console.error('[Transfers] Error listing transfers:', error.message);
    res.status(500).json({ error: 'Failed to list transfers' });
  }
});

/**
 * GET /api/transfers/:id
 * Get a specific transfer's details
 */
app.get('/api/transfers/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const localTransfer = transfersStore.find(t => t.id === id);
    if (!localTransfer) {
      return res.status(404).json({ error: 'Transfer not found' });
    }

    // DWOLLA API CALL: Get transfer details
    const response = await dwollaRequest('get', localTransfer.url);
    const transfer = response.body;

    // Update local store
    localTransfer.status = transfer.status;

    res.json({ transfer: { ...localTransfer, dwollaData: transfer } });
  } catch (error) {
    console.error('[Transfers] Error getting transfer:', error.message);
    res.status(500).json({ error: 'Failed to get transfer details' });
  }
});

// ----------------------------------------------------------------------------
// WEBHOOK ENDPOINTS
// ----------------------------------------------------------------------------

/**
 * POST /api/webhooks
 * Receive webhook events from Dwolla
 *
 * Dwolla sends webhook notifications for various events like:
 * - customer_created, customer_verified
 * - transfer_created, transfer_completed, transfer_failed
 * - funding_source_added, funding_source_verified
 */
app.post('/api/webhooks', (req, res) => {
  try {
    const event = req.body;

    console.log('[Webhooks] Received event:', event.topic);

    // In production, you would verify the webhook signature here
    // using the X-Request-Signature-SHA-256 header
    // const signature = req.headers['x-request-signature-sha-256'];
    // const isValid = verifyWebhookSignature(signature, req.body, webhookSecret);

    // Store the webhook event
    const webhookRecord = {
      id: event.id || `local-${Date.now()}`,
      topic: event.topic,
      resourceId: event.resourceId,
      timestamp: event.timestamp || new Date().toISOString(),
      _links: event._links,
      created: event.created || new Date().toISOString()
    };

    webhooksStore.unshift(webhookRecord); // Add to beginning of array

    // Keep only last 100 webhooks
    if (webhooksStore.length > 100) {
      webhooksStore = webhooksStore.slice(0, 100);
    }

    // Update local stores based on webhook topic
    if (event.topic && event._links) {
      updateLocalStoresFromWebhook(event);
    }

    // Dwolla expects a 200 response to acknowledge receipt
    res.status(200).json({ received: true });
  } catch (error) {
    console.error('[Webhooks] Error processing webhook:', error.message);
    res.status(500).json({ error: 'Failed to process webhook' });
  }
});

/**
 * Update local stores when relevant webhooks arrive
 */
function updateLocalStoresFromWebhook(event) {
  const topic = event.topic;

  // Customer-related webhooks
  if (topic.startsWith('customer_')) {
    const customerUrl = event._links?.customer?.href;
    if (customerUrl) {
      const customer = customersStore.find(c => c.url === customerUrl);
      if (customer) {
        // Update status based on topic
        if (topic === 'customer_verified') customer.status = 'verified';
        if (topic === 'customer_suspended') customer.status = 'suspended';
        if (topic === 'customer_verification_document_needed') customer.status = 'document';
        if (topic === 'customer_reverification_needed') customer.status = 'retry';
      }
    }
  }

  // Transfer-related webhooks
  if (topic.startsWith('transfer_')) {
    const transferUrl = event._links?.resource?.href;
    if (transferUrl) {
      const transfer = transfersStore.find(t => t.url === transferUrl);
      if (transfer) {
        // Update status based on topic
        if (topic === 'transfer_completed') transfer.status = 'processed';
        if (topic === 'transfer_failed') transfer.status = 'failed';
        if (topic === 'transfer_cancelled') transfer.status = 'cancelled';
      }
    }
  }
}

/**
 * GET /api/webhooks
 * List all received webhook events
 */
app.get('/api/webhooks', (req, res) => {
  res.json({ webhooks: webhooksStore });
});

/**
 * DELETE /api/webhooks
 * Clear all webhook events (for testing)
 */
app.delete('/api/webhooks', (req, res) => {
  webhooksStore = [];
  res.json({ success: true, message: 'Webhooks cleared' });
});

// ----------------------------------------------------------------------------
// ELIGIBLE CUSTOMERS FOR PAYOUTS
// ----------------------------------------------------------------------------

/**
 * GET /api/customers/eligible
 * Get customers eligible for payouts (verified + has verified funding source)
 */
app.get('/api/customers/eligible', async (req, res) => {
  try {
    const eligibleCustomers = [];

    for (const customer of customersStore) {
      // Skip if customer not verified
      if (customer.status !== 'verified') {
        continue;
      }

      // Check for verified funding sources
      try {
        const fsResponse = await dwollaRequest('get', `${customer.url}/funding-sources`);
        const verifiedSources = fsResponse.body._embedded['funding-sources']
          .filter(fs => !fs.removed && fs.status === 'verified');

        if (verifiedSources.length > 0) {
          eligibleCustomers.push({
            ...customer,
            fundingSources: verifiedSources.map(fs => ({
              id: fs._links.self.href.split('/').pop(),
              url: fs._links.self.href,
              name: fs.name,
              status: fs.status
            }))
          });
        }
      } catch (err) {
        console.warn('[Eligible] Failed to check funding sources for:', customer.id);
      }
    }

    res.json({ customers: eligibleCustomers });
  } catch (error) {
    console.error('[Eligible] Error:', error.message);
    res.status(500).json({ error: 'Failed to get eligible customers' });
  }
});

// ============================================================================
// SERVER START
// ============================================================================

app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════════╗
║         Dwolla Sandbox Practice Dashboard - Backend           ║
╠═══════════════════════════════════════════════════════════════╣
║  Server running on: http://localhost:${PORT}                    ║
║                                                               ║
║  This is a LEARNING tool for understanding Dwolla's API.      ║
║  All data is stored in memory and cleared on restart.         ║
║                                                               ║
║  To get started:                                              ║
║  1. POST /api/config with your Dwolla sandbox credentials     ║
║  2. Create customers, add funding sources, make transfers     ║
║  3. Watch webhook events come in                              ║
╚═══════════════════════════════════════════════════════════════╝
  `);
});
