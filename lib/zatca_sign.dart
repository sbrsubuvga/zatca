import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';

String getPureInvoiceString(String invoiceXml) {
  var document = xml.XmlDocument.parse(invoiceXml);
  document.findAllElements('ext:UBLExtensions').forEach((element) => element.parent?.children.remove(element));
  document.findAllElements('cac:Signature').forEach((element) => element.parent?.children.remove(element));
  document.findAllElements('cac:AdditionalDocumentReference')
      .where((element) => element.findElements('cbc:ID').any((id) => id.text == 'QR'))
      .forEach((element) => element.parent?.children.remove(element));

  return document.toXmlString();
}

String getInvoiceHash(String invoiceXml) {
  String pureInvoiceString = getPureInvoiceString(invoiceXml);
  pureInvoiceString = pureInvoiceString.replaceAll('<cbc:ProfileID>', '\n    <cbc:ProfileID>');
  pureInvoiceString = pureInvoiceString.replaceAll('<cac:AccountingSupplierParty>', '\n    \n    <cac:AccountingSupplierParty>');

  return base64Encode(sha256.convert(utf8.encode(pureInvoiceString)).bytes);
}

String getCertificateHash(String certificateString) {
  return base64Encode(sha256.convert(utf8.encode(certificateString)).bytes);
}

String createInvoiceDigitalSignature(String invoiceHash, String privateKey) {
  var invoiceHashBytes = base64Decode(invoiceHash);
  var signature = sha256.convert(invoiceHashBytes);
  return base64Encode(signature.bytes);
}

String cleanUpCertificateString(String certificateString) {
  return certificateString.replaceAll('-----BEGIN CERTIFICATE-----\n', '').replaceAll('-----END CERTIFICATE-----', '').trim();
}

String cleanUpPrivateKeyString(String privateKeyString) {
  return privateKeyString.replaceAll('-----BEGIN EC PRIVATE KEY-----\n', '').replaceAll('-----END EC PRIVATE KEY-----', '').trim();
}

class GenerateSignatureXMLParams {
  final String invoiceXml;
  final String certificateString;
  final String privateKeyString;

  GenerateSignatureXMLParams({
    required this.invoiceXml,
    required this.certificateString,
    required this.privateKeyString,
  });
}

Map<String, String> generateSignedXMLString(GenerateSignatureXMLParams params) {
  String invoiceHash = getInvoiceHash(params.invoiceXml);
  String certHash = getCertificateHash(params.certificateString);
  String digitalSignature = createInvoiceDigitalSignature(invoiceHash, params.privateKeyString);

  String signedXml = params.invoiceXml.replaceAll("SET_UBL_EXTENSIONS_STRING", "<DigitalSignature>$digitalSignature</DigitalSignature>")
      .replaceAll("SET_QR_CODE_DATA", "<QR>$invoiceHash</QR>");

  return {
    'signed_invoice_string': signedXml,
    'invoice_hash': invoiceHash,
    'qr': invoiceHash,
  };
}
