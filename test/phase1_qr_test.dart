import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zatca/models/address.dart';
import 'package:zatca/models/customer.dart';
import 'package:zatca/models/invoice.dart';
import 'package:zatca/simple_zatca_manager.dart';

/// Walks a TLV byte stream and returns a map of tag -> value bytes.
Map<int, List<int>> _decodeTlv(List<int> bytes) {
  final Map<int, List<int>> out = {};
  int i = 0;
  while (i < bytes.length) {
    final tag = bytes[i++];
    final len = bytes[i++];
    out[tag] = bytes.sublist(i, i + len);
    i += len;
  }
  return out;
}

void main() {
  // SimpleZatcaManager is a singleton. Each `group` initializes it
  // explicitly so test ordering is irrelevant.

  group('SimpleZatcaManager — happy path', () {
    test('emits tags 1-5 in order, with correct lengths and UTF-8 values', () {
      SimpleZatcaManager.instance.initialize(
        sellerName: 'Test Seller',
        sellerTRN: '300000000000003',
      );

      final base64Qr = SimpleZatcaManager.instance.generateQrString(
        issueDateTime: DateTime(2024, 1, 15, 10, 30, 0),
        totalWithVat: 115.0,
        vatTotal: 15.0,
      );

      final bytes = base64.decode(base64Qr);
      final tlv = _decodeTlv(bytes);

      expect(tlv.keys.toList(), [1, 2, 3, 4, 5]);
      expect(utf8.decode(tlv[1]!), 'Test Seller');
      expect(utf8.decode(tlv[2]!), '300000000000003');
      expect(utf8.decode(tlv[3]!), '2024-01-15T10:30:00');
      expect(utf8.decode(tlv[4]!), '115.00');
      expect(utf8.decode(tlv[5]!), '15.00');
    });

    test('formats amounts with exactly two decimals', () {
      SimpleZatcaManager.instance.initialize(
        sellerName: 'Shop',
        sellerTRN: '300000000000003',
      );

      final base64Qr = SimpleZatcaManager.instance.generateQrString(
        issueDateTime: DateTime(2024, 1, 1, 0, 0, 0),
        totalWithVat: 1000,
        vatTotal: 0.1,
      );

      final tlv = _decodeTlv(base64.decode(base64Qr));
      expect(utf8.decode(tlv[4]!), '1000.00');
      expect(utf8.decode(tlv[5]!), '0.10');
    });

    test('handles UTF-8 (Arabic) seller name correctly', () {
      const arabicName = 'متجر الاختبار';
      SimpleZatcaManager.instance.initialize(
        sellerName: arabicName,
        sellerTRN: '399999999900003',
      );

      final base64Qr = SimpleZatcaManager.instance.generateQrString(
        issueDateTime: DateTime(2024, 6, 10, 14, 45, 30),
        totalWithVat: 250.5,
        vatTotal: 32.67,
      );

      final tlv = _decodeTlv(base64.decode(base64Qr));
      expect(utf8.decode(tlv[1]!), arabicName);
      // Arabic name is multi-byte in UTF-8; length byte must reflect byte
      // count, not character count.
      expect(tlv[1]!.length, utf8.encode(arabicName).length);
    });

    test('generateQrStringFromInvoice derives date/totals from invoice', () {
      SimpleZatcaManager.instance.initialize(
        sellerName: 'Test Seller',
        sellerTRN: '300000000000003',
      );

      final invoice = SimplifiedInvoice(
        invoiceNumber: 'INV-1',
        uuid: 'uuid-1',
        issueDate: '2024-03-02',
        issueTime: '09:15:45',
        actualDeliveryDate: '2024-03-02',
        currencyCode: 'SAR',
        taxCurrencyCode: 'SAR',
        invoiceLines: const [],
        taxAmount: 5.25,
        totalAmount: 40.25,
        previousInvoiceHash: '',
      );

      final fromInvoice =
          SimpleZatcaManager.instance.generateQrStringFromInvoice(invoice);
      final tlv = _decodeTlv(base64.decode(fromInvoice));

      expect(utf8.decode(tlv[3]!), '2024-03-02T09:15:45');
      expect(utf8.decode(tlv[4]!), '40.25');
      expect(utf8.decode(tlv[5]!), '5.25');
    });

    test('B2B (Standard) invoice produces the same 5-tag QR as B2C', () {
      SimpleZatcaManager.instance.initialize(
        sellerName: 'Test Seller',
        sellerTRN: '300000000000003',
      );

      final b2c = SimplifiedInvoice(
        invoiceNumber: 'INV-1',
        uuid: 'u1',
        issueDate: '2024-03-02',
        issueTime: '09:15:45',
        actualDeliveryDate: '2024-03-02',
        currencyCode: 'SAR',
        taxCurrencyCode: 'SAR',
        invoiceLines: const [],
        taxAmount: 5.25,
        totalAmount: 40.25,
        previousInvoiceHash: '',
      );

      final b2b = StandardInvoice(
        invoiceNumber: 'INV-2',
        uuid: 'u2',
        issueDate: '2024-03-02',
        issueTime: '09:15:45',
        actualDeliveryDate: '2024-03-02',
        currencyCode: 'SAR',
        taxCurrencyCode: 'SAR',
        customer: Customer(
          companyID: '300000000000003',
          registrationName: 'Buyer',
          address: Address(
            street: 's',
            building: '1',
            citySubdivision: 'd',
            city: 'Riyadh',
            postalZone: '11111',
          ),
        ),
        invoiceLines: const [],
        taxAmount: 5.25,
        totalAmount: 40.25,
        previousInvoiceHash: '',
      );

      final qrB2c =
          SimpleZatcaManager.instance.generateQrStringFromInvoice(b2c);
      final qrB2b =
          SimpleZatcaManager.instance.generateQrStringFromInvoice(b2b);

      expect(qrB2c, qrB2b);
    });
  });

  group('SimpleZatcaManager — initialization validation', () {
    test('rejects empty seller name', () {
      expect(
        () => SimpleZatcaManager.instance.initialize(
          sellerName: '   ',
          sellerTRN: '300000000000003',
        ),
        throwsArgumentError,
      );
    });

    test('rejects VAT number not matching ZATCA format', () {
      // Not 15 digits
      expect(
        () => SimpleZatcaManager.instance.initialize(
          sellerName: 'Shop',
          sellerTRN: '3000000003',
        ),
        throwsArgumentError,
      );
      // Does not start with 3
      expect(
        () => SimpleZatcaManager.instance.initialize(
          sellerName: 'Shop',
          sellerTRN: '100000000000003',
        ),
        throwsArgumentError,
      );
      // Does not end with 3
      expect(
        () => SimpleZatcaManager.instance.initialize(
          sellerName: 'Shop',
          sellerTRN: '300000000000009',
        ),
        throwsArgumentError,
      );
      // Non-digit characters
      expect(
        () => SimpleZatcaManager.instance.initialize(
          sellerName: 'Shop',
          sellerTRN: '3000000000000X3',
        ),
        throwsArgumentError,
      );
    });
  });

  group('SimpleZatcaManager — amount validation', () {
    setUp(() {
      SimpleZatcaManager.instance.initialize(
        sellerName: 'Shop',
        sellerTRN: '300000000000003',
      );
    });

    test('rejects negative total', () {
      expect(
        () => SimpleZatcaManager.instance.generateQrString(
          issueDateTime: DateTime(2024),
          totalWithVat: -1,
          vatTotal: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative VAT', () {
      expect(
        () => SimpleZatcaManager.instance.generateQrString(
          issueDateTime: DateTime(2024),
          totalWithVat: 10,
          vatTotal: -1,
        ),
        throwsArgumentError,
      );
    });

    test('rejects VAT greater than total', () {
      expect(
        () => SimpleZatcaManager.instance.generateQrString(
          issueDateTime: DateTime(2024),
          totalWithVat: 10,
          vatTotal: 20,
        ),
        throwsArgumentError,
      );
    });
  });
}
