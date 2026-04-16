# ZATCA Package

The ZATCA package provides tools for generating and managing e-invoices compliant with the ZATCA (Zakat, Tax, and Customs Authority) regulations in Saudi Arabia. It includes features for creating QR codes, signing invoices, and handling invoice data models.

For more information about ZATCA e-invoicing regulations, visit the [official ZATCA website](https://zatca.gov.sa/en/E-Invoicing/SystemsDevelopers/Pages/default.aspx).
![ZATCA Fatoora Logo](https://zatca.gov.sa/ar/E-Invoicing/PublishingImages/header_logo.svg)

For more details, check out our Medium story: [Simplifying ZATCA E-Invoicing in Flutter with the ZATCA Package](https://medium.com/@sbrsubuvga/simplifying-zatca-e-invoicing-in-flutter-with-the-zatca-package-9d181243c2a0).

For more insights, you can also read our Medium article: [Simplifying ZATCA E-Invoicing in Flutter with the ZATCA Package (in Flutter)](https://medium.com/@sbrsubuvga/simplifying-zatca-e-invoicing-in-flutter-899b99df3511).


---

<a href="https://github.com/sponsors/sbrsubuvga" target="_blank">
  <img src="https://img.shields.io/badge/💖%20Sponsor%20on-GitHub%20Sponsors-blueviolet?style=for-the-badge&logo=github-sponsors" alt="Sponsor me on GitHub" />
</a>

> ☕ If you find this package helpful, consider sponsoring me to support continued development and maintenance.

---

## What's new in 0.7.0

- 🛠 **Correctness fix (critical):** ECDSA signing now uses `secp256k1`
  (the curve ZATCA requires). Previous releases silently signed with
  the wrong curve, producing signatures ZATCA would reject.
- 🛠 **Correctness fix:** `SignedProperties` digest, certificate digest,
  and decimal formatting in monetary fields all now match the ZATCA
  specification.
- ➕ Optional `paymentMethod` on regular invoices (not just credit/debit
  notes) — emits `cac:PaymentMeans` in the XML.
- 🧹 Breaking rename: `initializeZacta` → `initializeZatca`. A few
  internal directory typos were fixed too (see the full
  [CHANGELOG](CHANGELOG.md)).
- 🎨 Rewritten example app (`example/`) with `flutter_bloc`, a guided
  onboarding flow (keypair → CSR → compliance cert, with a one-tap
  sandbox prefill and inline OTP/VAT guidance), and a result screen
  that decodes the QR TLV tags for inspection. Responsive layout for
  mobile, tablet, and desktop.

---

## Features

- ✅ Generate certificates for signing invoices (desktop only).
- ✅ Manage certificates for signing invoices.
- ✅ Generate ZATCA-compliant QR codes for invoices.
- ✅ Generate ZATCA-compliant XML codes for invoices.
- ✅ Create and manage invoice data models.
- ✅ Sign invoices with private keys and certificates.
- ✅ Easy integration with Flutter and Dart projects.
- ✅ Generate ZATCA-compliant UBL standard XML for reporting purposes.

---

## Getting Started

To use this package, add it to your `pubspec.yaml`:

```yaml
dependencies:
  zatca: ^0.7.0
```

## Platform Requirements

### Certificate Generation Workflow

There are two ways to work with certificates in this package:

#### Option 1: Using Pre-generated Certificates (No OpenSSL Required)

If you already have a certificate and private key generated elsewhere, you can **skip the certificate generation step** and start directly by initializing ZATCA with your existing certificate. This is useful in the following scenarios:

- **Server-generated certificates**: Certificates generated on your backend server system
- **External system certificates**: Certificates generated using other tools or platforms (e.g., OpenSSL CLI, other certificate management systems)
- **Pre-existing certificates**: Certificates that were generated previously and stored securely
- **Mobile/Cloud deployment**: When deploying on mobile platforms or cloud environments where OpenSSL is not available

**Usage Example:**

```dart
final zatcaManager = ZatcaManager.instance;
zatcaManager.initializeZatca(
  sellerName: "Your Seller Name",
  sellerTRN: "Your TRN",
  supplier: supplier,
  privateKeyPem: yourExistingPrivateKeyPem,  // From server or other source
  certificatePem: yourExistingCertificatePem,  // From server or other source
);
```

**Benefits:**
- ✅ **No OpenSSL required** - Works on any platform (including mobile)
- ✅ **Flexible deployment** - Certificates can be managed separately from your Flutter app
- ✅ **Security** - Certificates can be generated and stored securely on your server

#### Option 2: Generating Certificates with This Package (OpenSSL Required)

If you want to generate certificates using this package's `generateCSR` method, you need:

1. **Desktop Platform**: Certificate generation is only supported on **desktop platforms** (Windows, Linux, and macOS). Mobile platforms (iOS and Android) are not supported for CSR generation.

2. **OpenSSL Installation**: The `generateCSR` method requires OpenSSL to be installed on your system.

#### Installing OpenSSL

**macOS:**
```bash
# Using Homebrew (recommended)
brew install openssl

# Verify installation
openssl version
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install openssl

# Verify installation
openssl version
```

**Linux (Fedora/RHEL/CentOS):**
```bash
sudo dnf install openssl
# or
sudo yum install openssl

# Verify installation
openssl version
```

**Windows:**
- OpenSSL will be automatically downloaded and installed if not found (requires internet connection)
- Alternatively, you can manually install OpenSSL from [Win64OpenSSL](https://slproweb.com/products/Win32OpenSSL.html)
- Ensure OpenSSL is added to your system PATH

## Enabling App Sandbox for macOS

To disable the App Sandbox entitlement for macOS, ensure the following lines in your `.entitlements` file are commented:

```entitlements
<!-- <key>com.apple.security.app-sandbox</key>
<true/> -->
```

## Example App

A full reference integration lives in the [`example/`](example/) folder.
It walks through the complete ZATCA lifecycle and is the fastest way to
see the package in action.

```bash
cd example
flutter run -d macos    # or -d linux / -d windows — CSR generation
                        # needs a desktop target (OpenSSL dependency)
```

What it demonstrates:

- **Onboarding flow** — generate a keypair, build a CSR, request a
  compliance certificate, and optionally upgrade to a production
  certificate. The form comes pre-loaded with known-good sandbox
  values (OTP `123456`, a valid test VAT number) via a single button
  so you can go from "installed" to "compliant" in a few taps.
- **Invoice composition** — all six invoice variants (simplified &
  standard, invoice / credit note / debit note), dynamic line items
  with inline discounts, live totals, and ICV/PIH auto-chaining.
- **Result screen** — scannable QR, TLV tag-by-tag breakdown,
  copyable invoice hash, digital signature, and full signed UBL XML.

State is managed with `flutter_bloc` and persisted via
`shared_preferences` (swap for `flutter_secure_storage` in production
— there's a note in `example/lib/data/storage.dart` explaining why).

<img alt="Example App Screenshot" src="https://raw.githubusercontent.com/sbrsubuvga/zatca/refs/heads/main/assets/example_app.png" width="821" height="798" />