# PassCoder - App Flow & UI

## App Screens Overview

### 1. Login Screen
```
┌─────────────────────────────────────┐
│                                     │
│         🔒 (Lock Icon)              │
│                                     │
│           PassCoder                 │
│     Secure Password Manager         │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📧 Email                    │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔑 Password            👁️  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │         Sign In             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔐 Sign in with Biometrics  │   │
│  └─────────────────────────────┘   │
│                                     │
│     Don't have an account? Sign Up  │
│                                     │
└─────────────────────────────────────┘
```

### 2. Home Screen (Bottom Navigation)
```
┌─────────────────────────────────────┐
│  Passwords                    🔄   │
├─────────────────────────────────────┤
│  🔍 Search passwords...            │
├─────────────────────────────────────┤
│  [All] [General] [Social] [Email]  │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │ 🔒 Netflix                  │   │
│  │    user@email.com           │   │
│  │                        ⋮   │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 🔒 GitHub                   │   │
│  │    developer@gmail.com      │   │
│  │                        ⋮   │   │
│  └─────────────────────────────┘   │
│                                     │
│                    [+ Add]          │
├─────────────────────────────────────┤
│  🔒     📝     💳     🔑           │
│ Passwords Notes  Cards  Generator  │
└─────────────────────────────────────┘
```

### 3. Password Form Screen
```
┌─────────────────────────────────────┐
│  ← Add Password               ⭐   │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │ 📝 Title *                  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 👤 Username                 │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔑 Password *      🎲 👁️  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🌐 Website URL             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📁 Category                │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📝 Notes                   │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │       Save Password         │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### 4. Password Generator Screen
```
┌─────────────────────────────────────┐
│  Password Generator                 │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │    Generated Password       │   │
│  │                             │   │
│  │   Kj#9mP$2xL@nQ!5w         │   │
│  │                             │   │
│  │    Strength: ████████░░     │   │
│  │              Strong         │   │
│  │                             │   │
│  │  [🔄 Generate] [📋 Copy]   │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Settings                    │   │
│  │                             │   │
│  │ Password Length: 16         │   │
│  │ ◄────────●─────────►       │   │
│  │                             │   │
│  │ ─────────────────────────── │   │
│  │ Letters (a-z)        [ON]  │   │
│  │ Uppercase (A-Z)      [ON]  │   │
│  │ Numbers (0-9)        [ON]  │   │
│  │ Special Characters   [ON]  │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## App Features Summary

### Security Features
- ✅ AES-256 encryption for all data
- ✅ Biometric authentication (Face ID/Touch ID)
- ✅ Secure key storage
- ✅ Row Level Security in database
- ✅ Auto-lock after inactivity

### Data Management
- ✅ Passwords with categories
- ✅ Secure notes
- ✅ Credit card storage
- ✅ Favorite items
- ✅ Search & filter

### UI/UX
- ✅ Minimalist design
- ✅ Material Design 3
- ✅ Dark/Light theme support
- ✅ Smooth animations
- ✅ Responsive layout

## Setup Instructions

1. **Install Flutter SDK**
   ```bash
   # Download from https://flutter.dev
   flutter --version
   ```

2. **Configure Supabase**
   - Create project at supabase.com
   - Run SQL migration
   - Get URL and anon key

3. **Set Environment Variables**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

4. **Run App**
   ```bash
   cd C:\Users\Mega Store\OneDrive\Documents\PassCoder
   flutter pub get
   flutter run
   ```

## Database Tables

### passwords
- id (UUID)
- user_id (UUID → auth.users)
- title (TEXT)
- username (TEXT)
- password_encrypted (TEXT)
- url (TEXT)
- notes (TEXT)
- category (TEXT)
- is_favorite (BOOLEAN)
- created_at (TIMESTAMPTZ)
- updated_at (TIMESTAMPTZ)

### secure_notes
- id (UUID)
- user_id (UUID → auth.users)
- title (TEXT)
- content_encrypted (TEXT)
- category (TEXT)
- created_at (TIMESTAMPTZ)
- updated_at (TIMESTAMPTZ)

### credit_cards
- id (UUID)
- user_id (UUID → auth.users)
- cardholder_name (TEXT)
- card_number_encrypted (TEXT)
- expiry_date_encrypted (TEXT)
- cvv_encrypted (TEXT)
- card_type (TEXT)
- is_favorite (BOOLEAN)
- created_at (TIMESTAMPTZ)
- updated_at (TIMESTAMPTZ)
