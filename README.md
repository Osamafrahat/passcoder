# PassCoder

A secure cross-platform password manager built with Flutter and Supabase.

## Features

- **Password Management**: Store and manage passwords with AES-256 encryption
- **Secure Notes**: Keep sensitive notes encrypted in the cloud
- **Credit Card Storage**: Safely store payment information
- **Password Generator**: Create strong, customizable passwords
- **Biometric Authentication**: Use Face ID, Touch ID, or fingerprint to unlock
- **Cloud Sync**: Access your data across all devices via Supabase
- **Minimalist Design**: Clean, intuitive interface

## Security

- **AES-256 Encryption**: All sensitive data encrypted before storage
- **Zero-Knowledge Architecture**: Master password never stored or transmitted
- **Biometric Protection**: Local device authentication required
- **Row Level Security**: Database-level access control in Supabase
- **Auto-Lock**: Configurable inactivity timeout

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Supabase account and project
- Android Studio / Xcode for mobile development

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/passcoder.git
   cd passcoder
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up environment variables:
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your Supabase credentials.

4. Run the database migration:
   - Go to your Supabase dashboard
   - Navigate to SQL Editor
   - Run the contents of `supabase/migrations/001_initial_schema.sql`

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app/
│   ├── app.dart                 # Main app configuration
│   └── routes.dart              # Route definitions
├── core/
│   ├── encryption/
│   │   └── encryption_service.dart  # AES-256 encryption
│   ├── auth/
│   │   └── auth_service.dart    # Authentication logic
│   └── config/
│       └── supabase_config.dart # Supabase configuration
├── features/
│   ├── auth/                    # Login/Register screens
│   ├── passwords/               # Password management
│   ├── notes/                   # Secure notes
│   ├── cards/                   # Credit card storage
│   └── generator/               # Password generator
├── models/                      # Data models
└── widgets/                     # Reusable widgets
```

## Database Schema

The app uses Supabase PostgreSQL with Row Level Security:

- `passwords`: Encrypted password storage
- `secure_notes`: Encrypted notes
- `credit_cards`: Encrypted payment information

All tables include:
- UUID primary keys
- User ID foreign keys
- Timestamps (created_at, updated_at)
- RLS policies for data isolation

## Built With

- [Flutter](https://flutter.dev/) - Cross-platform UI toolkit
- [Supabase](https://supabase.com/) - Backend as a Service
- [Provider](https://pub.dev/packages/provider) - State management
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) - Secure key storage
- [local_auth](https://pub.dev/packages/local_auth) - Biometric authentication
- [encrypt](https://pub.dev/packages/encrypt) - AES encryption

## License

This project is licensed under the MIT License - see the LICENSE file for details.
