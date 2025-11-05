# PassOut 🔐

**PassOut** is an innovative, secure, hash-based password manager built with Flutter that uses **military-grade cryptography** (SHA-512, AES-256-GCM, PBKDF2). It generates deterministic passwords from your master seed and website/username combinations, eliminating the need to store actual passwords. Your passwords are computed on-demand using industry-leading cryptographic methods, making it virtually impossible for attackers to access your credentials even if they compromise your device.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-blue)](https://flutter.dev)

## ✨ Key Features

### 🔒 **Hash-Based Password Generation**
- **100% OFFLINE**: Passwords are NEVER stored anywhere, not even encrypted
- Generates unique, deterministic passwords using SHA-512 hashing
- Passwords are computed on-demand from: `subdomain + username + nonce + master_seed`
- Each password is regenerated fresh every time you need it
- Base85 encoding produces strong, URL-safe passwords up to 32 characters
- **Internet connection only needed for syncing metadata and browser extension communication**

### 🌱 **Mnemonic Seed Protection**
- Uses BIP39 mnemonic phrases (12 words) for master seed generation
- HD Wallet Kit integration for secure seed derivation
- Seed stored securely using Flutter Secure Storage with encrypted SharedPreferences
- Recovery support through mnemonic phrase

### ☁️ **Google Drive Sync**
- Encrypted account metadata backup to Google Drive
- Automatic sync across devices
- AES-256-GCM encryption with PBKDF2 key derivation (10,000 iterations)
- Only encrypted metadata (URL, username) is stored—never actual passwords

### 🌐 **Browser Extension Integration**
- Chrome/Edge extension for seamless web autofill
- WebRTC-based secure communication between app and extension
- Real-time password generation and autofill
- Detects login and registration forms automatically
- QR code pairing for secure connection setup

### 🔄 **Password Regeneration**
- Increment nonce to generate new passwords for the same account
- Useful for password rotation without changing your master seed
- Maintains password history through nonce versioning

### 🎨 **Cross-Platform Support**
- Built with Flutter for Android, iOS, Web, Windows, Linux, and macOS
- Responsive Material Design UI
- Dark/Light theme support

## 🏗️ Architecture

### Core Components

1. **Account Model** (`lib/models/account.dart`)
   - Hash-based password generation using SHA-512
   - AES-256-GCM encryption for metadata
   - PBKDF2 key derivation (HMAC-SHA256, 10K iterations)
   - Base85 encoding for compact, strong passwords

2. **Secure Storage** (`lib/helpers/secure_storage.dart`)
   - Flutter Secure Storage for master seed
   - Encrypted SharedPreferences on Android
   - Keychain/Keystore integration

3. **Google Drive API** (`lib/api/google/`)
   - OAuth2 authentication
   - Encrypted file upload/download
   - Automatic file versioning

4. **WebRTC Signaling** (`lib/api/webrtc/signaling.dart`)
   - Peer-to-peer connection with browser extension
   - AES-GCM encrypted data channel
   - WebSocket signaling server integration

5. **Chrome Extension** (`chrome_extension/web/`)
   - Content script for form detection
   - Background service worker for message routing
   - Offscreen document for WebRTC connection
   - Auto-fill and auto-update capabilities

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.3 <4.0.0)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Chrome/Edge browser (for extension)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/devminm/PassOut.git
   cd PassOut
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For Android/iOS
   flutter run

   # For Web
   flutter run -d chrome

   # For Desktop
   flutter run -d windows  # or macos, linux
   ```

### Setting Up the Chrome Extension

**⚠️ IMPORTANT**: Before using the browser extension, you must set up your own WebRTC signaling server (see Configuration Required section below).

1. **Update signaling server URLs**
   - Edit `lib/api/webrtc/signaling.dart` and replace the WebSocket URL with your server
   - Edit `chrome_extension/web/offscreen.js` and update the WebSocket connection URL

2. **Build the extension**
   ```bash
   cd chrome_extension
   flutter pub get
   flutter build web --web-renderer html --csp
   ```

3. **Load in Chrome**
   - Open Chrome and navigate to `chrome://extensions/`
   - Enable "Developer mode"
   - Click "Load unpacked"
   - Select the `chrome_extension/build/web` directory

4. **Pair with Mobile App**
   - Open the PassOut app
   - Tap the QR code scanner button
   - Scan the QR code displayed in the extension
   - Connection established via WebRTC

## 📖 How It Works

### Password Generation Flow (100% OFFLINE)

```
Master Seed (from mnemonic)
    ↓
SHA-512(subdomain + username + nonce + seed)
    ↓
Base85 Encode
    ↓
Truncate to 32 characters
    ↓
Generated Password (exists only in memory, never saved)
    ↓
Used immediately, then discarded
```

**NOTE**: This entire process happens offline on your device. No passwords are ever transmitted, stored, or saved anywhere.

### Data Flow

1. **First Time Setup**
   - Generate or import 12-word mnemonic
   - Derive master seed from mnemonic
   - Store seed in secure storage

2. **Adding an Account**
   - Enter website URL and username
   - Password generated automatically (OFFLINE, never saved)
   - Only encrypted metadata (URL, username, nonce) saved to Google Drive—NOT the password

3. **Password Retrieval**
   - App fetches encrypted metadata from Google Drive (internet needed)
   - Decrypts using local master seed
   - Regenerates password from account data + seed (OFFLINE process)
   - Password exists only in memory, then discarded after use

4. **Browser Extension Usage**
   - Extension detects login form
   - Sends request to mobile app via WebRTC (internet needed for communication)
   - App generates password OFFLINE and sends encrypted via WebRTC
   - Extension auto-fills credentials
   - Password never saved on browser or anywhere else

## 🔐 Security Features

### 🛡️ Military-Grade Cryptography

PassOut implements **industry-leading cryptographic standards** that are among the most secure and trusted methods currently available:

- **SHA-512**: One of the most secure cryptographic hash functions from the SHA-2 family, providing 512-bit hash values
- **AES-256-GCM**: Advanced Encryption Standard with 256-bit keys in Galois/Counter Mode—the gold standard for symmetric encryption used by governments and financial institutions worldwide
- **PBKDF2 (Password-Based Key Derivation Function 2)**: Industry-standard key derivation with HMAC-SHA256 and 10,000 iterations, recommended by NIST and used by major tech companies
- **BIP39 Mnemonic**: Bitcoin Improvement Proposal 39 standard for deterministic key generation, battle-tested in cryptocurrency applications managing billions of dollars

### 🔒 Core Security Architecture

- **100% OFFLINE PASSWORD GENERATION**: Passwords are NEVER saved anywhere—not locally, not in the cloud, not encrypted, NOWHERE
- **Zero-Knowledge Architecture**: Passwords only exist in memory when generated, then immediately discarded
- **Deterministic Generation**: Same inputs always produce the same password—no storage needed
- **End-to-End Encryption**: Only account metadata (URL, username) is encrypted and synced, never passwords
- **Cryptographically Secure Random Number Generation**: Uses platform-native secure random generators for nonce and IV generation
- **Isolated Seed Storage**: Master seed never leaves secure storage (iOS Keychain/Android Keystore)
- **WebRTC Security**: AES-GCM encrypted peer-to-peer connection with browser
- **Base85 Encoding**: Produces high-entropy, URL-safe passwords with maximum character diversity
- **Internet Only for Sync**: Connection needed only for metadata sync and extension communication, not password generation

### 🏆 Why These Methods Are Superior

- **Proven Security**: All cryptographic methods used are standardized, peer-reviewed, and have withstood decades of cryptanalysis
- **Government & Enterprise Grade**: Same encryption standards used by military, banks, and Fortune 500 companies
- **Future-Proof**: 256-bit encryption is considered quantum-resistant for the foreseeable future
- **No Proprietary Crypto**: Uses only well-established, open-source cryptographic libraries—no "security through obscurity"

## 🛠️ Technologies Used

- **Flutter & Dart**: Cross-platform development
- **Cryptography Package**: SHA-512, AES-GCM, PBKDF2
- **HD Wallet Kit**: BIP39 mnemonic generation
- **Flutter Secure Storage**: Encrypted local storage
- **Google Sign-In & APIs**: OAuth2 and Drive integration
- **Flutter WebRTC**: P2P communication
- **WebSocket**: Signaling server connection
- **QR Code Scanner**: Secure pairing mechanism
- **Base85 Encoding**: Compact password representation

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ✅ Chrome/Edge Extension

## 🗂️ Project Structure

```
PassOut/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app_router.dart           # Navigation routing
│   ├── models/
│   │   └── account.dart          # Core account & crypto logic
│   ├── screens/
│   │   ├── splash/               # Splash screen & permissions
│   │   ├── mnemonic/             # Mnemonic setup/recovery
│   │   └── home/                 # Main account management
│   ├── api/
│   │   ├── google/               # Google Drive integration
│   │   └── webrtc/               # WebRTC signaling
│   ├── helpers/
│   │   └── secure_storage.dart   # Secure storage wrapper
│   └── widgets/
│       └── account_card.dart     # Account display widget
├── chrome_extension/
│   └── web/
│       ├── manifest.json         # Extension manifest
│       ├── background.js         # Service worker
│       ├── content.js            # Form detection & autofill
│       └── offscreen.js          # WebRTC handler
├── assets/
│   └── logos/                    # Service logos
└── test/                         # Unit tests
```

##  Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## ⚙️ Configuration Required

### WebRTC Signaling Server Setup

The browser extension feature requires a WebRTC signaling server for communication between the mobile app and browser extension. The code currently references `wss://der1.ezas.org:8080`, which is the developer's private server and is **NOT publicly available**.

**To use the browser extension feature, you must:**

1. **Deploy your own WebRTC signaling server**
   - You can use Node.js with Socket.io or similar WebSocket server
   - The signaling server only facilitates the initial WebRTC handshake
   - Once connected, all data flows peer-to-peer (encrypted)

2. **Update the server URL in the code:**
   - `lib/api/webrtc/signaling.dart` - Line with WebSocket connection
   - `chrome_extension/web/offscreen.js` - WebSocket connection URL

3. **Simple signaling server example:**
   ```javascript
   // Node.js WebSocket signaling server example
   const WebSocket = require('ws');
   const wss = new WebSocket.Server({ port: 8080 });
   
   wss.on('connection', (ws) => {
     ws.on('message', (message) => {
       // Broadcast to all other clients
       wss.clients.forEach((client) => {
         if (client !== ws && client.readyState === WebSocket.OPEN) {
           client.send(message);
         }
       });
     });
   });
   ```

**Note**: The mobile app works perfectly fine without the extension for password generation and management. The signaling server is only needed if you want to use the browser auto-fill feature.

## 🐛 Known Issues

- Extension currently supports Chrome only
- Some forms may not be detected automatically
- Users must deploy their own WebRTC signaling server for extension functionality

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## � Team

- **[@devminm](https://github.com/devminm)**
- **[@pedramktb](https://github.com/pedramktb)**

## 📞 Contact

- **Developers**: 
  - [@devminm](https://github.com/devminm)
  - [@pedramktb](https://github.com/pedramktb)
- **Repository**: [github.com/devminm/PassOut](https://github.com/devminm/PassOut)
- **Issues**: [GitHub Issues](https://github.com/devminm/PassOut/issues)

## ⚠️ Disclaimer

This password manager is provided as-is. While it uses industry-standard cryptographic practices, users should understand the security implications and use at their own risk. Always keep secure backups of your mnemonic phrase. Loss of your mnemonic phrase means permanent loss of access to your accounts.

**IMPORTANT**: Your passwords are NEVER stored anywhere. They are generated on-demand using your master seed. Internet connection is only required for:
- Syncing account metadata (URL, username, nonce) to Google Drive
- Communication between mobile app and browser extension via WebRTC
- Password generation itself is 100% offline and happens locally on your device

---

**Made with ❤️ and Flutter**
