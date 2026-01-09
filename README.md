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
  zatca: ^0.6.4
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
zatcaManager.initializeZacta(
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

## Example App Screenshot

<img alt="Example App Screenshot" src="https://raw.githubusercontent.com/sbrsubuvga/zatca/refs/heads/main/assets/example_app.png" width="821" height="798" />