import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:zatca/models/address.dart';
import 'package:zatca/models/customer.dart';
import 'package:zatca/models/invoice.dart';
import 'package:zatca/models/invoice_line.dart';
import 'package:zatca/models/supplier.dart';
import 'package:zatca/resources/certificate/certificate_util.dart';
import 'package:zatca/zatca_manager.dart';

/// Pins the encoding of the three XAdES digests ZATCA validates.
///
/// ZATCA is not consistent about how digests are encoded, and getting it wrong
/// is invisible locally - the XML is well formed and the signature verifies -
/// but the gateway rejects every single invoice:
///
///   certificate-hashing:       Invalid certificate hashing
///   signed-properties-hashing: Invalid signed properties hashing
///
/// The rules:
///   * invoice hash (`ds:Reference Id="invoiceSignedData"`)
///       -> Base64 of the RAW SHA-256 digest        -> 44 characters
///   * certificate hash (`xades:CertDigest`)
///       -> Base64 of the SHA-256 HEX STRING        -> 88 characters
///         (and the hash is over the certificate's Base64 TEXT, not its DER)
///   * signed properties (`ds:Reference URI="#xadesSignedProperties"`)
///       -> Base64 of the SHA-256 HEX STRING        -> 88 characters
///
/// These tests are fully offline - no ZATCA sandbox call - so they can guard
/// every change to the signing path.
///
/// Regression: 0.7.0-0.8.0 emitted the 44-character form for the certificate
/// and signed-properties digests.
void main() {
  // Self-signed secp256k1 certificate, generated only as a test fixture.
  const certificatePem = '''-----BEGIN CERTIFICATE-----
MIIBtDCCAVqgAwIBAgIUXQWYzbCjqKToDpGg1BEn64BMmJ0wCgYIKoZIzj0EAwIw
MTERMA8GA1UEAwwIVEVTVC1FR1MxDzANBgNVBAoMBkxpdGhvczELMAkGA1UEBhMC
U0EwHhcNMjYwODMxMDkwMzM2WhcNMzYwODI4MDkwMzM2WjAxMREwDwYDVQQDDAhU
RVNULUVHUzEPMA0GA1UECgwGTGl0aG9zMQswCQYDVQQGEwJTQTBWMBAGByqGSM49
AgEGBSuBBAAKA0IABD/mu9/IimEQhFj6/HiEdwEGy88tYVY/A5LyeCAlY5paAWIc
A/yQFdsWR/PuZfIC0GP5MnoUlnNqyRjuVyo3ul6jUzBRMB0GA1UdDgQWBBRp8p/P
aV5l/jdjmM/vG7BTXnpMgjAfBgNVHSMEGDAWgBRp8p/PaV5l/jdjmM/vG7BTXnpM
gjAPBgNVHRMBAf8EBTADAQH/MAoGCCqGSM49BAMCA0gAMEUCIGreBp3H0Zhxexq6
Rig350ZDOCAjcVrHN7XYzUNLXA/1AiEAsUs7OQK9nLHLDxpNgpE+S4i369ZyLuxA
s60S2nXLfKs=
-----END CERTIFICATE-----''';

  const privateKeyPem = '''-----BEGIN EC PRIVATE KEY-----
MHQCAQEEIMIAg+ytamt7D2btHt+Hkoo+zDifSsqZidW7AuxjSgt8oAcGBSuBBAAK
oUQDQgAEP+a738iKYRCEWPr8eIR3AQbLzy1hVj8DkvJ4ICVjmloBYhwD/JAV2xZH
8+5l8gLQY/kyehSWc2rJGO5XKje6Xg==
-----END EC PRIVATE KEY-----''';

  /// The certificate hash ZATCA expects for the fixture above, computed
  /// independently of the package:
  ///   base64( hex( sha256( <certificate base64 text> ) ) )
  const expectedCertificateHash =
      'ODFkYTc1YjVjNjJkNDdlYmM4NjA1ZGJlMWEzNzc3OTc3MzgwZTNjNDU3MDEwNWQ1YmM2ZjY2NDFiY2FjZmY5Zg==';

  String? digestOfReference(String ublXml, String reference) {
    final match = RegExp(
      '<ds:Reference[^>]*$reference[^>]*>[\\s\\S]*?<ds:DigestValue>([^<]*)</ds:DigestValue>',
    ).firstMatch(ublXml);
    return match?.group(1);
  }

  String? certDigest(String ublXml) {
    final match = RegExp(
      '<xades:CertDigest>[\\s\\S]*?<ds:DigestValue[^>]*>([^<]*)</ds:DigestValue>',
    ).firstMatch(ublXml);
    return match?.group(1);
  }

  group('certificate hash', () {
    test('is Base64 of the SHA-256 hex of the certificate Base64 text', () {
      final info = CertificateUtil.getCertificateInfo(certificatePem);

      expect(info.hash, expectedCertificateHash);
      expect(info.hash.length, 88);
    });

    test('is not Base64 of the raw digest of the DER bytes', () {
      final info = CertificateUtil.getCertificateInfo(certificatePem);
      final body = CertificateUtil.cleanCertificatePem(certificatePem);

      // The 0.7.0-0.8.0 regression, spelled out so it can never come back.
      final rawDigestOfDer = base64.encode(
        sha256.convert(base64.decode(body)).bytes,
      );
      expect(rawDigestOfDer.length, 44);
      expect(info.hash, isNot(rawDigestOfDer));
    });
  });

  group('signed UBL digests', () {
    late String ublXml;

    setUpAll(() {
      final zatcaManager = ZatcaManager.instance;
      const vatNumber = '399999999900003';
      final location = Location(
        city: 'Khobar',
        citySubdivision: 'West',
        street: 'King Fahahd st',
        plotIdentification: '0000',
        building: '0000',
        postalZone: '31952',
      );

      zatcaManager.initializeZatca(
        sellerName: 'Test Seller',
        sellerTRN: vatNumber,
        supplier: Supplier(
          companyID: vatNumber,
          companyCRN: '454634645645654',
          registrationName: 'Test Seller',
          location: location,
        ),
        privateKeyPem: privateKeyPem,
        certificatePem: certificatePem,
      );

      final invoice = SimplifiedInvoice(
        invoiceNumber: 'EGS1-886431145-101',
        uuid: '6f4d20e0-6bfe-4a80-9389-7dabe6620f14',
        issueDate: '2025-05-09',
        issueTime: '13:40:40',
        actualDeliveryDate: '2025-05-09',
        currencyCode: 'SAR',
        taxCurrencyCode: 'SAR',
        customer: Customer(
          companyID: '300000000000003',
          registrationName: 'Test Customer',
          address: Address(
            street: '__',
            building: '00',
            citySubdivision: 'ssss',
            city: 'jeddah',
            postalZone: '00000',
          ),
        ),
        invoiceLines: [
          InvoiceLine(
            id: '1',
            quantity: 2,
            unitCode: 'PCE',
            lineExtensionAmount: 10,
            itemName: 'TEST NAME',
            taxPercent: 15,
          ),
        ],
        taxAmount: 1.50,
        totalAmount: 11.50,
        previousInvoiceHash: 'zDnQnE05P6rFMqF1ai21V5hIRlUq/EXvrpsaoPkWRVI=',
      );

      final qrData = zatcaManager.generateZatcaQrInit(invoice: invoice, icv: 1);
      ublXml = zatcaManager.generateUBLXml(
        invoiceHash: qrData.invoiceHash,
        signingTime:
            "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.utc(2025, 5, 9, 13, 40, 40))}Z",
        digitalSignature: qrData.digitalSignature,
        invoiceXmlString: qrData.xmlString,
        qrString: zatcaManager.getQrString(qrData),
      );
    });

    test('invoice hash stays Base64 of the raw digest (44 chars)', () {
      final digest = digestOfReference(ublXml, 'invoiceSignedData');

      expect(digest, isNotNull);
      expect(digest!.length, 44);
    });

    test('signed properties digest is Base64 of the hex (88 chars)', () {
      final digest = digestOfReference(ublXml, '#xadesSignedProperties');

      expect(digest, isNotNull);
      expect(digest!.length, 88);
      // Base64 of a 64-character lowercase hex string, and nothing else.
      expect(utf8.decode(base64.decode(digest)), matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('embedded certificate digest matches the certificate', () {
      final digest = certDigest(ublXml);

      expect(digest, isNotNull);
      expect(digest, expectedCertificateHash);
      expect(digest!.length, 88);
    });
  });
}
