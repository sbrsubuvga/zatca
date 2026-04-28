# Changelog

## 0.8.0

Adds ZATCA **Phase-1 (Generation)** support via a new dedicated class,
so a single integration of this package can serve both onboarded
(Phase-2) and not-yet-onboarded (Phase-1) merchants. **Fully backward
compatible** — existing `ZatcaManager` Phase-2 code is unchanged.

### Added

* **`SimpleZatcaManager`** — a new singleton for ZATCA Phase-1
  (Generation). Takes only `sellerName` and `sellerTRN` — no private
  key, no certificate, no supplier info, no ZATCA API. Produces a
  compliant basic TLV QR (tags 1–5) that is identical for both
  simplified (B2C) and standard (B2B) invoices.

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
  ```

  A convenience wrapper `generateQrStringFromInvoice(BaseInvoice)`
  is also provided for integrators who already have a `BaseInvoice`.
* **Input validation.** `sellerTRN` must be 15 digits starting and
  ending with `3`. Amounts must be finite and non-negative, and VAT
  cannot exceed the invoice total.
* **Example app** has a dedicated **Phase-1 QR** screen that
  demonstrates `SimpleZatcaManager` end-to-end (form → TLV QR →
  tag-by-tag breakdown).
* **Unit tests** (`test/phase1_qr_test.dart`) covering TLV tag order
  and lengths, two-decimal amount formatting, UTF-8 (Arabic) seller
  names, VAT-format validation, negative-amount rejection, and
  B2B/B2C QR equivalence.

### Architecture

Phase-1 and Phase-2 are now exposed as **two purpose-built singletons**
rather than one manager with a runtime phase flag. Pick the class that
matches the merchant — the type system enforces phase separation.

| Phase | Class | Use when |
|---|---|---|
| Phase-1 (Generation) | `SimpleZatcaManager` | Merchant not yet onboarded to FATOORA |
| Phase-2 (Integration) | `ZatcaManager` | Merchant onboarded with compliance + production CSID |

### Unchanged

* `ZatcaManager` — public API and behavior identical to 0.7.0.
* `CertificateManager` — public API and behavior identical to 0.7.0
  (it remains a Phase-2 helper; Phase-1 callers simply don't use it).

## 0.7.0

A major correctness release that fixes several bugs that were silently
producing invoices ZATCA would reject. Also ships a rewritten example
app and cleans up a number of typos in public identifiers. Minor
breaking changes are listed below — most users only need to rename
one method call.

### Fixed (critical — these affected signature & QR validation)

* **ECDSA curve mismatch.** Signing used `secp256r1` while keys were
  generated on `secp256k1`. Every signature produced before this
  release was invalid and would be rejected by ZATCA. Now both
  paths use `secp256k1` as required by the ZATCA specification.
* **SignedProperties hash double-encoding.** The `xades:SignedProperties`
  digest was hex-stringified, then UTF-8-encoded, then Base64'd —
  producing a garbage value. Now correctly Base64-encodes the raw
  SHA-256 bytes.
* **Certificate digest double-encoding.** The `xades:CertDigest` value
  was hashed from the PEM text rather than the DER bytes, with the
  same hex→UTF-8→Base64 problem. Now hashes the DER-encoded
  certificate and Base64-encodes the raw digest.
* **Missing `xmlns:ds` on signed-properties children.** The post-signing
  `<ds:DigestMethod>`, `<ds:DigestValue>`, `<ds:X509IssuerName>`, and
  `<ds:X509SerialNumber>` elements are now correctly namespaced.

### Fixed (moderate)

* **Inconsistent decimal formatting.** `NumberFormat("#.##")` was
  dropping trailing zeros (`"100.00"` became `"100"`) on some
  monetary elements while others correctly used `toStringAsFixed(2)`.
  All amounts now use 2 fixed decimals.
* **Per-line `PriceAmount` overflow.** `toStringAsFixed(14)` has been
  reduced to `toStringAsFixed(2)` for both line unit prices and
  discount amounts.
* **Customer `PlotIdentification` field.** Was using
  `address.building` as a stand-in. `Address` now exposes a dedicated
  `plotIdentification` field which falls back to the building number
  when not provided.
* **Fragile `<ds:Object-1/>` placeholder.** Replaced with a normal
  `<ds:Object>` element whose content is substituted after signing.
* **Missing `Content-Type: application/json`** header in
  `reportInvoice` and `clearanceInvoice`.

### Added

* **`paymentMethod` on regular invoices.** `Invoice`, `SimplifiedInvoice`
  and `StandardInvoice` now accept an optional `paymentMethod` of type
  `ZATCAPaymentMethods`, which emits a `cac:PaymentMeans` block in
  the generated XML. Previously only credit/debit notes emitted
  payment means.
* **Dedicated `Address.plotIdentification`.** Optional; defaults to
  the `building` value for backwards compatibility.
* **Rewritten example app** (`example/`) demonstrating the full
  ZATCA lifecycle: onboarding (keypair → CSR → compliance cert →
  optional production cert), invoice composition (all 6 invoice
  variants, dynamic line items, live totals), and a result screen
  (scannable QR, TLV breakdown, signed UBL XML, copyable hashes
  and signatures). Uses `flutter_bloc` for state, adapts to
  desktop/tablet/mobile via `NavigationRail` / `NavigationBar`,
  and persists onboarding state across launches.

### Changed

* **BREAKING:** `ZatcaManager.initializeZacta` renamed to
  `ZatcaManager.initializeZatca`. Rename the single call at the
  start of your integration.
* **BREAKING (internal paths):** directory and file typos corrected.
  If you were importing internal paths directly, update them:
  * `package:zatca/resources/cirtificate/…`
    → `package:zatca/resources/certificate/…`
  * `…/cirtificate/certficate_util.dart`
    → `…/certificate/certificate_util.dart`
  * `package:zatca/models/cirtificate_info.dart`
    → `package:zatca/models/certificate_info.dart`
  * `package:zatca/extesions/discount_list_extesions.dart`
    → `package:zatca/extensions/discount_list_extensions.dart`

  Most integrators only import the top-level APIs (`ZatcaManager`,
  `CertificateManager`, models) and are unaffected.

## 0.6.6

* Updates and improvements.

## 0.6.5

* Updates and improvements.

## 0.6.4

* Fixed missing type annotations in functions.

## 0.6.2

* Bug fixes.

## 0.6.0

* Added simulation environment.
* Bug fixes.

## 0.5.0

* Added support for item discounts.

## 0.4.0+3

* Updated documentation for better clarity and consistency.

## 0.4.0

* Bug fixed: OpenSSL certificate generation now supported on Linux, Windows, and macOS.

## 0.3.2

* Adding a custom path for the certificate.

## 0.3.0

* Resolved an issue with certificate generation.

## 0.2.4

* Updated dependencies to the latest package versions for improved functionality and compatibility.
