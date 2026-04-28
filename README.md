# ZATCA — Saudi Arabia E-Invoicing for Flutter

> Generate ZATCA-compliant e-invoices, QR codes, and signed UBL XML
> for both **Phase-1 (Generation)** and **Phase-2 (FATOORA Integration)**.

<p align="center">
  <img alt="ZATCA package — Phase-1 and Phase-2 e-invoicing for Flutter"
       src="https://raw.githubusercontent.com/sbrsubuvga/zatca/main/assets/example_app_1.png"
       width="900" />
</p>

<p align="center">
  <a href="https://pub.dev/packages/zatca"><img alt="pub.dev" src="https://img.shields.io/pub/v/zatca?label=pub.dev&color=0175C2"></a>
  <a href="https://github.com/sbrsubuvga/zatca/blob/main/LICENSE"><img alt="license" src="https://img.shields.io/github/license/sbrsubuvga/zatca"></a>
  <a href="https://github.com/sponsors/sbrsubuvga"><img alt="sponsor" src="https://img.shields.io/badge/Sponsor-%E2%9D%A4-ff69b4?logo=github-sponsors"></a>
</p>

The ZATCA package provides tools for generating and managing e-invoices
compliant with the ZATCA (Zakat, Tax, and Customs Authority)
regulations in Saudi Arabia. It includes features for creating QR
codes, signing invoices, and handling invoice data models.

For background, visit the [official ZATCA website](https://zatca.gov.sa/en/E-Invoicing/SystemsDevelopers/Pages/default.aspx).
Two Medium write-ups: [overview](https://medium.com/@sbrsubuvga/simplifying-zatca-e-invoicing-in-flutter-with-the-zatca-package-9d181243c2a0)
· [in-Flutter walkthrough](https://medium.com/@sbrsubuvga/simplifying-zatca-e-invoicing-in-flutter-899b99df3511).

---

## What's new in 0.8.0

- ➕ **ZATCA Phase-1 (Generation) support** via a new dedicated class,
  `SimpleZatcaManager`. Merchants not yet onboarded to FATOORA can now
  produce a compliant basic TLV QR (tags 1–5) for both simplified
  (B2C) and standard (B2B) invoices — no certificates, no signing,
  no ZATCA API calls required.
- 🧭 **Two purpose-built classes:** `ZatcaManager` for Phase-2
  (FATOORA Integration, unchanged) and `SimpleZatcaManager` for
  Phase-1 (Generation). Pick the one that matches the merchant.
  No phase enums, no runtime guards — the type system enforces it.
- ♻️ **Zero breaking changes** for existing Phase-2 consumers — the
  `ZatcaManager` API is identical to 0.7.0.
- 🧪 New unit tests covering TLV encoding, amount formatting, UTF-8
  (Arabic) seller names, VAT validation, and B2B/B2C QR equivalence.
- 🎨 Example app now has a dedicated "Phase-1 QR" screen.

See [Choosing your phase](#choosing-your-phase) below.

---

## Choosing your phase

ZATCA e-invoicing has two phases. **One terminal / merchant account
runs in exactly one phase at a time.** Pick the manager that matches
the tenant you are integrating for:

| | Phase-1 (Generation) | Phase-2 (Integration) |
|---|---|---|
| When | Merchant **not yet onboarded** to FATOORA | Merchant **onboarded** with compliance + production CSID |
| Manager class | `SimpleZatcaManager` | `ZatcaManager` |
| QR code | Basic TLV, tags 1–5 | Full TLV, tags 1–9 |
| Signing | ❌ None | ✅ ECDSA secp256k1 |
| Certificates | ❌ Not required | ✅ Compliance + production CSID |
| ZATCA API | ❌ None | ✅ Reporting / clearance |
| B2B vs B2C | Same basic QR for both | UBL XML differs; QR structure shared |

### Phase-1 example (`SimpleZatcaManager`)

```dart
import 'package:zatca/simple_zatca_manager.dart';

SimpleZatcaManager.instance.initialize(
  sellerName: 'My Shop',
  sellerTRN: '300000000000003',
);

final qr = SimpleZatcaManager.instance.generateQrString(
  issueDateTime: DateTime.now(),
  totalWithVat: 115.00,
  vatTotal: 15.00,
);
// Render `qr` with any QR widget (e.g. `qr_flutter`'s QrImageView).
```

That's it for Phase-1 — no onboarding, no keys, no network calls.
Same call works for both simplified (B2C) and standard (B2B) invoices.

### Phase-2 example (`ZatcaManager`)

```dart
import 'package:zatca/zatca_manager.dart';

ZatcaManager.instance.initializeZatca(
  privateKeyPem: privateKeyPem,
  certificatePem: certificatePem,
  supplier: supplier,
  sellerName: 'My Shop',
  sellerTRN: '300000000000003',
);

final qrData = ZatcaManager.instance.generateZatcaQrInit(
  invoice: invoice,
  icv: icv,
);
final qr = ZatcaManager.instance.getQrString(qrData);
final signedXml = ZatcaManager.instance.generateUBLXml(
  invoiceHash: qrData.invoiceHash,
  signingTime: signingTime,
  digitalSignature: qrData.digitalSignature,
  invoiceXmlString: qrData.xmlString,
  qrString: qr,
);
```

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
  zatca: ^0.8.0
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
It demonstrates **both phases side by side** and is the fastest way
to see the package in action.

```bash
cd example
flutter run -d macos    # or -d linux / -d windows — Phase-2 CSR
                        # generation needs a desktop target
                        # (OpenSSL dependency). Phase-1 runs anywhere.
```

The app's side menu mirrors the package's structure: **PHASE-1
(Generation)** has one screen (`SimpleZatcaManager`), **PHASE-2
(Integration)** has two ordered steps (`ZatcaManager` onboarding +
invoice). A landing screen explains the difference and links to the
right flow.

<table>
  <tr>
    <td align="center" width="50%">
      <img alt="Phase-1 QR generator"
           src="https://raw.githubusercontent.com/sbrsubuvga/zatca/main/assets/example_app_2.png" width="420" />
      <br/><sub><b>Phase-1</b> · <code>SimpleZatcaManager</code> — basic TLV QR (tags 1–5)</sub>
    </td>
    <td align="center" width="50%">
      <img alt="Phase-2 signed invoice result"
           src="https://raw.githubusercontent.com/sbrsubuvga/zatca/main/assets/example_app_3.png" width="420" />
      <br/><sub><b>Phase-2</b> · <code>ZatcaManager</code> — signed UBL + 9-tag QR</sub>
    </td>
  </tr>
</table>

What it demonstrates:

- **Phase-1 QR Generator** — `SimpleZatcaManager` end-to-end: form →
  TLV QR → tag-by-tag breakdown. Same QR works for B2C and B2B.
- **Phase-2 Onboarding** — generate a keypair, build a CSR, request
  a compliance certificate, and optionally upgrade to a production
  certificate. Pre-loaded with known-good sandbox values (OTP
  `123456`, a valid test VAT number) via a single button.
- **Phase-2 Invoice composition** — all six invoice variants
  (simplified & standard, invoice / credit note / debit note),
  dynamic line items with inline discounts, live totals, and
  ICV/PIH auto-chaining. Locked in the side menu until onboarding
  completes.
- **Phase-2 Result screen** — scannable QR, TLV tag-by-tag breakdown,
  copyable invoice hash, digital signature, and full signed UBL XML.

State is managed with `flutter_bloc` and persisted via
`shared_preferences` (swap for `flutter_secure_storage` in production
— there's a note in `example/lib/data/storage.dart` explaining why).

---

## ❤️ Support this package

`zatca` is maintained as a free, open-source library. ZATCA's spec
changes regularly and keeping the package compliant takes ongoing
work — if it's saving your team time on a paid project, please
consider sponsoring its maintenance.

<p>
  <a href="https://github.com/sponsors/sbrsubuvga">
    <img alt="Sponsor on GitHub Sponsors"
         src="https://img.shields.io/badge/Sponsor%20on-GitHub%20Sponsors-ea4aaa?style=for-the-badge&logo=github-sponsors&logoColor=white" />
  </a>
</p>

Other ways to help, even without money:

- ⭐ **Star** the [GitHub repo](https://github.com/sbrsubuvga/zatca) —
  visibility is what brings new contributors.
- 🐛 **File issues** when ZATCA rejects an invoice — paste the error,
  the redacted XML, and the package version.
- 📝 **Share** the Medium articles or write your own — every "I shipped
  ZATCA in Flutter using this package" post helps another team start.
- 🔌 **Submit PRs** — the [`example/`](example/) app is a good way to
  contribute new flows without touching the core library.