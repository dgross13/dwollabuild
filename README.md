# Dwolla Sandbox Practice Dashboard

A full-stack learning tool to understand the Dwolla payment system end-to-end.

## Overview

This project provides a visual dashboard to learn and experiment with Dwolla's payment API in their sandbox environment. It includes:

- **Backend**: Node.js + Express server that handles all Dwolla API communication
- **Frontend**: Flutter app with a clean UI for managing customers, payments, and transfers

## Architecture

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│                 │      │                 │      │                 │
│  Flutter App    │ ───► │  Express API    │ ───► │   Dwolla API    │
│  (Frontend)     │      │  (Backend)      │      │   (Sandbox)     │
│                 │ ◄─── │                 │ ◄─── │                 │
└─────────────────┘      └─────────────────┘      └─────────────────┘
        │                        │
        │                        ▼
        │              ┌─────────────────┐
        │              │  In-Memory      │
        │              │  Storage        │
        │              │  - Customers    │
        │              │  - Transfers    │
        │              │  - Webhooks     │
        └──────────────┴─────────────────┘
                 localStorage
                 (API credentials)
```

## Prerequisites

- Node.js 18+ and npm
- Flutter SDK 3.10+
- Dwolla Sandbox Account (free at https://www.dwolla.com/sign-up)

## Quick Start

### 1. Start the Backend

```bash
cd backend
npm install
npm start
```

The server will run on `http://localhost:3000`

### 2. Start the Frontend

```bash
cd frontend
flutter pub get
flutter run
```

For web: `flutter run -d chrome`
For macOS: `flutter run -d macos`

### 3. Configure Dwolla Credentials

1. Open the app and go to **Settings**
2. Enter your Dwolla Sandbox **API Key** and **Secret**
3. Click "Save & Connect"

## Features

### Settings Page
- Enter and save Dwolla API credentials
- Credentials stored in localStorage (frontend) and memory (backend)
- Automatic OAuth token refresh before every API call

### Customers Page
- Create personal or business customers
- Duplicate email/phone validation
- View customer verification status (unverified, verified, document, retry, suspended)
- Verify customers with KYC information (SSN, DOB, address)
- Add bank accounts (funding sources)
- View customer's funding sources

### Payments Page
- Create transfers from your master account to customers
- Validation: only shows eligible recipients (verified customer + verified funding source)
- Select source funding source from your account
- Clear error messages for failed transfers

### Transfers Page
- View all transfers with real-time status updates
- Auto-refreshes every 3 seconds
- Status tracking: pending, processed, failed, cancelled

### Webhooks Page
- View all webhook events received from Dwolla
- Auto-refreshes every 3 seconds
- Event explanations for common webhook types
- Clear all webhooks option

### My Account Page
- View master account information
- View account balance (if applicable)
- View linked funding sources

### Visualizer Page
- Flow diagrams explaining the Dwolla payment flow
- Customer payment lifecycle
- Master account to worker payment flow
- API request architecture
- Webhook event types

## Dwolla Learning Flow

### Step 1: Understand the Setup
1. You have a **Master Account** (your Dwolla business account)
2. You create **Customers** (people or businesses you want to pay)
3. Both you and your customers need **Funding Sources** (bank accounts)

### Step 2: Customer Lifecycle
```
Create Customer → Verify (KYC) → Add Bank → Ready for Payment
```

### Step 3: Payment Lifecycle
```
Select Source → Select Recipient → Enter Amount → Create Transfer → Monitor Status
```

### Step 4: Status Tracking
- Use the **Transfers** page to monitor transfer status
- Use the **Webhooks** page to see real-time event notifications

## Sandbox Testing Tips

### Customer Verification (SSN Patterns)
In sandbox, different SSN last-4 digits trigger different statuses:
- `0000` - Customer will be verified
- `0001` - Customer will need to retry verification
- `0002` - Customer will need to upload documents
- `0003` - Customer will be suspended

### Test Bank Account
Use these sandbox bank credentials:
- Routing Number: `222222226`
- Account Number: Any 9+ digit number

### Transfer Status
In sandbox, transfers process immediately. In production, ACH transfers take 1-5 business days.

## API Endpoints

### Configuration
- `POST /api/config` - Set API credentials and get OAuth token
- `GET /api/config/status` - Check configuration status

### Customers
- `POST /api/customers` - Create a customer
- `GET /api/customers` - List all customers
- `GET /api/customers/:id` - Get customer details
- `POST /api/customers/:id/verify` - Submit KYC verification
- `POST /api/customers/:id/funding-sources` - Add funding source
- `GET /api/customers/:id/funding-sources` - List funding sources
- `GET /api/customers/eligible` - List customers eligible for payouts

### Master Account
- `GET /api/me` - Get account info
- `GET /api/me/funding-sources` - List account funding sources
- `GET /api/me/balance` - Get account balance

### Transfers
- `POST /api/transfers` - Create a transfer
- `GET /api/transfers` - List all transfers
- `GET /api/transfers/:id` - Get transfer details

### Webhooks
- `POST /api/webhooks` - Receive webhook events (from Dwolla)
- `GET /api/webhooks` - List received webhooks
- `DELETE /api/webhooks` - Clear webhooks

## Project Structure

```
dwollabuild/
├── backend/
│   ├── package.json
│   └── server.js          # Express server with all API endpoints
│
├── frontend/
│   ├── lib/
│   │   ├── main.dart      # App entry point and navigation
│   │   ├── services/
│   │   │   └── api_service.dart    # HTTP client for backend
│   │   ├── providers/
│   │   │   └── dwolla_provider.dart # State management
│   │   └── pages/
│   │       ├── settings_page.dart   # API credentials
│   │       ├── customers_page.dart  # Customer management
│   │       ├── payments_page.dart   # Create transfers
│   │       ├── transfers_page.dart  # Monitor transfers
│   │       ├── webhooks_page.dart   # View webhooks
│   │       ├── account_page.dart    # Master account
│   │       └── visualizer_page.dart # Flow diagrams
│   └── pubspec.yaml
│
└── README.md
```

## Security Notes

This is a **learning tool** for sandbox only. For production:

1. Never store API credentials in frontend localStorage
2. Implement proper webhook signature verification
3. Use environment variables for credentials
4. Add proper authentication/authorization
5. Use a persistent database instead of in-memory storage
6. Implement rate limiting and error handling

## Troubleshooting

### "Failed to connect to backend"
- Make sure the backend is running on port 3000
- Check CORS is enabled (it is by default)
- For mobile/emulator, you may need to use your computer's IP instead of localhost

### "Token expired" errors
- The backend automatically refreshes tokens
- If issues persist, try disconnecting and reconnecting

### "Customer not eligible for payout"
- Customer must have status "verified"
- Customer must have at least one "verified" funding source

## Learn More

- [Dwolla API Documentation](https://docs.dwolla.com/)
- [Dwolla Sandbox Guide](https://docs.dwolla.com/docs/sandbox)
- [Dwolla Webhook Events](https://docs.dwolla.com/docs/webhooks)

---

Built for learning Dwolla's payment system. Not for production use.
