import 'package:intl/intl.dart';
import 'package:zatca/models/invoice.dart';
import 'package:zatca/resources/qr_generator.dart';

/// Manager for **ZATCA Phase-1 (Generation)** invoicing.
///
/// Use this for merchants that have **not** been onboarded to FATOORA
/// integration yet. It produces a compliant basic TLV QR code (tags 1–5)
/// for both simplified (B2C) and standard (B2B) invoices — the QR
/// format is identical for both.
///
/// Phase-1 has no certificates, no signing, no UBL XML, and no ZATCA
/// API calls. If you need any of those, use [ZatcaManager] (Phase-2)
/// instead.
///
/// ```dart
/// SimpleZatcaManager.instance.initialize(
///   sellerName: 'My Shop',
///   sellerTRN: '300000000000003',
/// );
///
/// final qr = SimpleZatcaManager.instance.generateQrString(
///   issueDateTime: DateTime.now(),
///   totalWithVat: 115.00,
///   vatTotal: 15.00,
/// );
/// ```
class SimpleZatcaManager {
  SimpleZatcaManager._();

  /// The single instance of [SimpleZatcaManager].
  static final SimpleZatcaManager instance = SimpleZatcaManager._();

  String? _sellerName;
  String? _sellerTRN;

  /// Whether [initialize] has been called successfully.
  bool get isInitialized => _sellerName != null && _sellerTRN != null;

  /// Initializes the manager with the merchant's identity.
  ///
  /// [sellerName] - Merchant / taxpayer name as registered with ZATCA.
  /// [sellerTRN] - 15-digit VAT registration number; must start and
  /// end with `3`.
  void initialize({
    required String sellerName,
    required String sellerTRN,
  }) {
    _validateSellerName(sellerName);
    _validateSellerTRN(sellerTRN);
    _sellerName = sellerName.trim();
    _sellerTRN = sellerTRN;
  }

  /// Generates a Phase-1 QR string (base64 of TLV tags 1–5).
  ///
  /// Works for both simplified (B2C) and standard (B2B) Phase-1
  /// invoices — the format is identical. Call [initialize] first.
  ///
  /// [issueDateTime] - Invoice issue timestamp (emitted as ISO 8601
  ///   `yyyy-MM-ddTHH:mm:ss`).
  /// [totalWithVat] - Invoice total including VAT.
  /// [vatTotal] - Total VAT amount.
  String generateQrString({
    required DateTime issueDateTime,
    required double totalWithVat,
    required double vatTotal,
  }) {
    _requireInitialized();
    _validateAmounts(totalWithVat, vatTotal);

    final tlv = generateTlv({
      1: _sellerName!,
      2: _sellerTRN!,
      3: DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(issueDateTime),
      4: totalWithVat.toStringAsFixed(2),
      5: vatTotal.toStringAsFixed(2),
    });
    return tlvToBase64(tlv);
  }

  /// Convenience wrapper around [generateQrString] that pulls the
  /// date, total, and VAT out of a [BaseInvoice].
  String generateQrStringFromInvoice(BaseInvoice invoice) {
    return generateQrString(
      issueDateTime: DateTime.parse(
        '${invoice.issueDate} ${invoice.issueTime}',
      ),
      totalWithVat: invoice.totalAmount,
      vatTotal: invoice.taxAmount,
    );
  }

  void _requireInitialized() {
    if (!isInitialized) {
      throw StateError(
        'SimpleZatcaManager is not initialized. Call '
        'SimpleZatcaManager.instance.initialize(...) before generating '
        'a QR code.',
      );
    }
  }

  void _validateSellerName(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(
        name,
        'sellerName',
        'Seller name must not be empty.',
      );
    }
  }

  void _validateSellerTRN(String trn) {
    // ZATCA VAT number: exactly 15 digits, starts and ends with '3'.
    if (!RegExp(r'^3\d{13}3$').hasMatch(trn)) {
      throw ArgumentError.value(
        trn,
        'sellerTRN',
        'Invalid VAT registration number. Must be 15 digits, starting '
            'and ending with 3.',
      );
    }
  }

  void _validateAmounts(double total, double vat) {
    if (total.isNaN || total.isInfinite || total < 0) {
      throw ArgumentError.value(
        total,
        'totalWithVat',
        'Invoice total must be a finite value >= 0.',
      );
    }
    if (vat.isNaN || vat.isInfinite || vat < 0) {
      throw ArgumentError.value(
        vat,
        'vatTotal',
        'VAT total must be a finite value >= 0.',
      );
    }
    if (vat > total) {
      throw ArgumentError(
        'VAT total ($vat) cannot exceed invoice total ($total).',
      );
    }
  }
}
