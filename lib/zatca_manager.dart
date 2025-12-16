import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import 'package:zatca/models/invoice.dart';
import 'package:zatca/models/qr_data.dart';
import 'package:zatca/resources/cirtificate/certficate_util.dart';
import 'package:zatca/resources/qr_generator.dart';
import 'package:zatca/resources/signature/signature_util.dart';
import 'package:zatca/resources/xml/xml_util.dart';

import 'models/supplier.dart';

/// A singleton class that manages the generation of ZATCA-compliant invoices and QR codes.
class ZatcaManager {
  ZatcaManager._();

  /// The single instance of the `ZatcaManager` class.
  static ZatcaManager instance = ZatcaManager._();

  String? _privateKeyPem;
  String? _certificatePem;
  Supplier? _supplier;
  String? _sellerName;
  String? _sellerTRN;

  /// Initializes the ZATCA manager with the required supplier and cryptographic details.

  /// [supplier] - The supplier information.
  /// [privateKeyPem] - The private key in Base64 format.
  /// [certificatePem] - (CSR) The certificate request in Base64 format.
  /// [sellerName] - The name of the seller.
  /// [sellerTRN] - The Tax Registration Number (TRN) of the seller.
  /// [issuedCertificateBase64] - The issued certificate from zatca compliance.  only required for generating UBL standard XML

  initializeZacta({
    required String privateKeyPem,
    required String certificatePem,
    required Supplier supplier,
    required String sellerName,
    required String sellerTRN,
  }) {
    _privateKeyPem = privateKeyPem;
    _certificatePem = certificatePem;
    _sellerName = sellerName;
    _sellerTRN = sellerTRN;
    _supplier = supplier;
  }

  /// /// Generates a ZATCA-compliant QR code and invoice data.
  ///   /// [invoiceLines] - The list of invoice lines.
  ///   /// [invoiceType] - The type of the invoice.
  ///   /// [invoiceRelationType] - The relation type of the invoice (default is `b2c`).
  ///   /// [customer] - The customer information (required for `b2b` invoices).
  ///   /// [issueDate] - The issue date of the invoice.
  ///   /// [invoiceUUid] - The unique identifier for the invoice.
  ///   /// [invoiceNumber] - The invoice number.
  ///   /// [issueTime] - The issue time of the invoice.
  ///   /// [totalWithVat] - The total amount including VAT.
  ///   /// [totalVat] - The total VAT amount.
  ///   /// [previousInvoiceHash] - The hash of the previous invoice.

  ///   /// Returns a `ZatcaQr` object containing the QR code and invoice data.
  ZatcaQr generateZatcaQrInit({
    required BaseInvoice invoice,
    required int icv,
  }) {
    if (_supplier == null ||
        _privateKeyPem == null ||
        _certificatePem == null ||
        _sellerName == null ||
        _sellerTRN == null) {
      throw Exception(
        'Supplier, private key, certificate, seller name, and seller TRN must be initialized before generating the QR code.',
      );
    }

    // if (invoice.invoiceType.invoiceRelationType == InvoiceRelationType.b2b && invoice.customer == null) {
    //   throw Exception(
    //     'customer must be initialized before generating the QR code.',
    //   );
    // }
    // final zatinvoice = ZatcaInvoice(
    //   profileID: 'reporting:1.0',
    //   invoiceNumber: invoice.invoiceNumber,
    //   uuid: invoice.uuid,
    //   issueDate: invoice.issueDate,
    //   issueTime: invoice.issueTime,
    //   invoiceType: invoice.invoiceType,
    //   currencyCode: 'SAR',
    //   taxCurrencyCode: 'SAR',
    //   supplier: _supplier!,
    //   customer:invoice.customer??
    //       Customer(
    //         companyID: ' ',
    //         registrationName: ' ',
    //         address: Address(
    //           street: ' ',
    //           building: ' ',
    //           citySubdivision: ' ',
    //           city: ' ',
    //           postalZone: ' ',
    //         ),
    //       ),
    //   invoiceLines: invoice.invoiceLines,
    //   taxAmount: invoice.taxAmount,
    //   totalAmount: invoice.totalAmount,
    //   previousInvoiceHash: invoice.previousInvoiceHash,
    //   cancellation: invoice.cancellation,
    //
    // );

    final xml = XmlUtil.generateZATCAXml(invoice, _supplier!, icv: icv);
    final xmlString = xml.toXmlString(pretty: true, indent: '    ');
    String hashableXml = xml.rootElement.toXmlString(
      pretty: true,
      indent: '    ',
    );

    hashableXml = normalizeXml(hashableXml);
    hashableXml = hashableXml.replaceFirst(
      '<cbc:ProfileID>reporting:1.0</cbc:ProfileID>',
      '\n    <cbc:ProfileID>reporting:1.0</cbc:ProfileID>',
    );
    hashableXml = hashableXml.replaceFirst(
      '<cac:AccountingSupplierParty>',
      '\n    \n    <cac:AccountingSupplierParty>',
    );

    final xmlHash = XmlUtil.generateHash(hashableXml);

    // Generate the ECDSA signature
    final signature = SignatureUtil.createInvoiceDigitalSignature(
      xmlHash,
      _privateKeyPem!,
    );
    final certificateInfo = CertificateUtil.getCertificateInfo(
      _certificatePem!,
    );
    final issueDateTime = DateTime.parse(
      '${invoice.issueDate} ${invoice.issueTime}',
    );

    return ZatcaQr(
      sellerName: _sellerName!,
      sellerTRN: _sellerTRN!,
      issueDateTime: DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(issueDateTime),
      invoiceHash: xmlHash,
      digitalSignature: signature,
      publicKey: certificateInfo.publicKey,
      certificateSignature: certificateInfo.signature,
      invoiceData: invoice,
      xmlString: xmlString,
    );
  }

  /// Generates a QR code string from the given `ZatcaQr` data model.
  ///
  /// [qrDataModel] - The data model containing the QR code information.
  ///
  /// Returns the QR code string.
  String getQrString(ZatcaQr qrDataModel) {
    Map<int, dynamic> invoiceData = {
      1: qrDataModel.sellerName,
      2: qrDataModel.sellerTRN,
      3: qrDataModel.issueDateTime,
      4: qrDataModel.invoiceData.totalAmount.toStringAsFixed(2),
      5: qrDataModel.invoiceData.taxAmount.toStringAsFixed(2),
      6: qrDataModel.invoiceHash,
      7: utf8.encode(qrDataModel.digitalSignature),
      8: base64.decode(qrDataModel.publicKey),
      9: base64.decode(qrDataModel.certificateSignature),
    };
    String tlvString = generateTlv(invoiceData);
    final qrContent = utf8.encode(tlvToBase64(tlvString));
    return String.fromCharCodes(qrContent);
  }

  String toHex(Uint8List data) =>
      data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

  String generateUBLXml({
    required String invoiceHash,
    required String signingTime,
    required String digitalSignature,
    required String invoiceXmlString,
    required String qrString,
  }) {
    final cleanedCertificate = CertificateUtil.cleanCertificatePem(
      _certificatePem!,
    );
    final certificateInfo = CertificateUtil.getCertificateInfo(
      _certificatePem!,
    );
    final defaultUBLExtensionsSignedPropertiesForSigningXML =
        XmlUtil.defaultUBLExtensionsSignedPropertiesForSigning(
          signingTime: signingTime,
          certificateHash: certificateInfo.hash,
          certificateIssuer: certificateInfo.issuer,
          certificateSerialNumber: certificateInfo.serialNumber,
        );

    // 5: Get SignedProperties hash
    String defaultUBLExtensionsSignedPropertiesForSigningXMLString =
        defaultUBLExtensionsSignedPropertiesForSigningXML.toXmlString(
          pretty: true,
          indent: '    ',
        );
    defaultUBLExtensionsSignedPropertiesForSigningXMLString =
        defaultUBLExtensionsSignedPropertiesForSigningXMLString
            .split('\n')
            .map((e) {
              return e.padLeft(e.length + 32);
            })
            .join('\n');
    defaultUBLExtensionsSignedPropertiesForSigningXMLString =
        defaultUBLExtensionsSignedPropertiesForSigningXMLString.replaceFirst(
          '                                <xades:SignedProperties xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" Id="xadesSignedProperties">',
          '<xades:SignedProperties xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" Id="xadesSignedProperties">',
        );

    final signedPropertiesBytes = utf8.encode(
      defaultUBLExtensionsSignedPropertiesForSigningXMLString,
    );
    final signedPropertiesHash =
        sha256.convert(signedPropertiesBytes).toString();
    final signedPropertiesHashBase64 = base64.encode(
      utf8.encode(signedPropertiesHash),
    );

    final defaultUBLExtensionsSignedPropertiesXML =
        XmlUtil.defaultUBLExtensionsSignedProperties(
          signingTime: signingTime,
          certificateHash: certificateInfo.hash,
          certificateIssuer: certificateInfo.issuer,
          certificateSerialNumber: certificateInfo.serialNumber,
        );
    final ublStandardXML = XmlUtil.generateUBLSignExtensionsXml(
      invoiceHash: invoiceHash,
      signedPropertiesHash: signedPropertiesHashBase64,
      digitalSignature: digitalSignature,
      certificateString: cleanedCertificate,
      ublSignatureSignedPropertiesXML: defaultUBLExtensionsSignedPropertiesXML,
    );

    final xmlDocument = XmlDocument.parse(invoiceXmlString);
    xmlDocument.rootElement.children.insert(
      0,
      ublStandardXML.rootElement.copy(),
    );

    final qrXml = XmlUtil.generateQrAndSignatureXMl(qrString: qrString);

    final supplierPartyIndex = xmlDocument.rootElement.children.indexWhere(
      (node) =>
          node is XmlElement && node.name.local == 'AccountingSupplierParty',
    );
    xmlDocument.rootElement.children.insertAll(
      supplierPartyIndex,
      qrXml.children.map((node) => node.copy()).toList(),
    );

    String xml = xmlDocument.toXmlString(pretty: true, indent: '    ');
    String defaultUBLExtensionsSignedPropertiesXMLString =
        defaultUBLExtensionsSignedPropertiesXML.rootElement.toXmlString(
          pretty: true,
          indent: '    ',
        );
    defaultUBLExtensionsSignedPropertiesXMLString =
        defaultUBLExtensionsSignedPropertiesXMLString
            .split('\n')
            .map((e) {
              return e.padLeft(e.length + 28);
            })
            .join('\n');
    defaultUBLExtensionsSignedPropertiesXMLString =
        defaultUBLExtensionsSignedPropertiesXMLString.replaceFirst(
          '                            <xades:QualifyingProperties Target="signature" xmlns:xades="http://uri.etsi.org/01903/v1.3.2#">',
          '<xades:QualifyingProperties Target="signature" xmlns:xades="http://uri.etsi.org/01903/v1.3.2#">',
        );
    String replacable = """<ds:Object>
                            $defaultUBLExtensionsSignedPropertiesXMLString
                            </ds:Object>""";
    xml = xml.replaceFirst('<ds:Object-1/>', replacable);

    return xml;
  }
}

String normalizeXml(String hashableXml) {
  return hashableXml
      .replaceAll('\r\n', '\n') // Normalize all line endings to \n
      .replaceAll(
        RegExp(r'\s+$', multiLine: true),
        '',
      ) // Remove trailing spaces per line
      .trim(); // Trim leading/trailing whitespace
}
