// import 'package:flutter_zatca/qr/qr.dart';
// import 'package:intl/intl.dart';
// import 'package:xml/xml.dart';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:crypto/crypto.dart';
// import 'package:pointycastle/export.dart';
// import 'package:asn1lib/asn1lib.dart';
// import 'package:x509/x509.dart' as x509;

// import '../parse/canonical.dart';
// import 'package:pointycastle/src/utils.dart' as utils;
// import 'package:basic_utils/basic_utils.dart' as bUtis;

// import '../templates/ubl_extension_signed_properties_template.dart';
// import '../templates/ubl_sign_extension_template.dart';
// import '../zatca_sign.dart';

// String getPureInvoiceString(XmlDocument invoiceXml) {
//   XmlDocument invoice_copy = XmlDocument.parse(invoiceXml.toXmlString(pretty: true));

//   // Remove the specified elements
//   invoice_copy.findAllElements('ext:UBLExtensions').forEach((e) => e.parent?.children.remove(e));
//   invoice_copy.findAllElements('cac:Signature').forEach((e) => e.parent?.children.remove(e));
//   invoice_copy.findAllElements('cac:AdditionalDocumentReference')
//       .where((e) => e.findElements('cbc:ID').any((id) => id.innerText == 'QR'))
//       .forEach((e) => e.parent?.children.remove(e));
//   final canonicalizedXmlStr = invoice_copy.toXmlString(pretty: true, indent: '    ');
//   final xmlWithoutDeclaration = canonicalizedXmlStr.replaceFirst(RegExp(r'<\?xml[^>]*\?>'), '').trim();

//   return xmlWithoutDeclaration;
// }

// String getInvoiceHash(XmlDocument invoiceXml) {
//   String pureInvoiceString = getPureInvoiceString(invoiceXml);

//   // Fix formatting issues
//   pureInvoiceString = pureInvoiceString.replaceAll('<cbc:ProfileID>', '\n    <cbc:ProfileID>');
//   pureInvoiceString = pureInvoiceString.replaceAll('<cac:AccountingSupplierParty>', '\n    \n    <cac:AccountingSupplierParty>');

//   final bytes = utf8.encode(pureInvoiceString);
//   final digest = sha256.convert(bytes);

//   return base64.encode(digest.bytes);
// }

// String getCertificateHash(String certificateString) {
//   List<int> hashBytes = sha256.convert(utf8.encode(certificateString)).bytes;
//   String hexString = hashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
//   String certificateHash = base64.encode(utf8.encode(hexString));
//   return certificateHash;
// }

// ECSignature signData(ECPrivateKey privateKey, Uint8List dataToSign) {
//   var signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64))
//     ..init(true, PrivateKeyParameter<ECPrivateKey>(privateKey));

//   return signer.generateSignature(dataToSign) as ECSignature;
// }

// String createInvoiceDigitalSignature(String invoiceHash, String privateKeyString) {
//   Uint8List invoiceHashBytes = base64Decode(invoiceHash);
//   ECPrivateKey privateKey = bUtis.CryptoUtils.ecPrivateKeyFromPem(privateKeyString);
//   ECSignature signature = bUtis.CryptoUtils.ecSign(privateKey, invoiceHashBytes);

//   return bUtis.CryptoUtils.ecSignatureToBase64(signature);
// }

// Map<String, dynamic> getCertificateInfo(String certificateString) {
//   var cleanedCertificateString = cleanUpCertificateString(certificateString);
//   final wrappedCertificateString = '-----BEGIN CERTIFICATE-----\n$cleanedCertificateString\n-----END CERTIFICATE-----';
//   final pemString = wrappedCertificateString.replaceAll('-----BEGIN CERTIFICATE-----', '').replaceAll('-----END CERTIFICATE-----', '').replaceAll(RegExp(r'\s+'), '');
// final pemBytes = base64.decode(pemString);

// final hash = getCertificateHash(cleanedCertificateString);
// String fixPem = bUtis.X509Utils.fixPem(wrappedCertificateString);
// final bUtis.X509CertificateData certificate = bUtis.X509Utils.x509CertificateFromPem(fixPem);


// final publicKeyBytes = base64.encode(utf8.encode(certificate.tbsCertificate!.subjectPublicKeyInfo.bytes!));
// final signatureBytes = base64.encode(utf8.encode(certificate.signature!));

// final serialNumber = certificate.tbsCertificate!.serialNumber;
// final String serialNumberString = BigInt.parse(serialNumber!.toRadixString(16), radix: 16).toString();

// return {
//   'hash': hash,
//   'issuer': 'CN=PRZEINVOICESCA4-CA, DC=extgazt, DC=gov, DC=local',
//   'serial_number': serialNumberString,
//   'public_key': publicKeyBytes,
//   'signature': signatureBytes,
// };
// }

// String cleanUpCertificateString(String certificateString) {
//   return certificateString.replaceAll(RegExp(r'-----BEGIN CERTIFICATE-----\n|-----END CERTIFICATE-----'), '').trim();
// }

// Map<String, String> generateSignedXMLString(XmlDocument invoiceXml, String certificateString, String privateKeyString) {
//   final invoice_copy = XmlDocument.parse(invoiceXml.toXmlString(pretty: false));
//   final invoiceHash = getInvoiceHash(invoiceXml);

//   final certInfo = getCertificateInfo(certificateString);
//   final digitalSignature = createInvoiceDigitalSignature(invoiceHash, privateKeyString);

//   final qr = generateQR(QRParams(
//     invoice_xml: invoiceXml,
//     digital_signature: digitalSignature,
//     public_key: base64.decode(certInfo['public_key']),
//     certificate_signature: base64.decode(certInfo['signature'])
//   ));

//   String signTimestamp = "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now().toUtc())}Z";
//   SignedPropertiesProps signedPropertiesProps = SignedPropertiesProps(
//     signTimestamp: signTimestamp,
//     certificateHash: certInfo['hash'],
//     certificateIssuer: certInfo['issuer'].toString(),
//     certificateSerialNumber: certInfo['serial_number']
//   );

//   String ubl_signature_signed_properties_xml_string_for_signing = defaultUBLExtensionsSignedPropertiesForSigning(signedPropertiesProps);
//   String ubl_signature_signed_properties_xml_string = defaultUBLExtensionsSignedProperties(signedPropertiesProps);

//   Uint8List signedPropertiesBytes = utf8.encode(ubl_signature_signed_properties_xml_string_for_signing);
//   final signedPropertiesHash = sha256.convert(signedPropertiesBytes);
//   String signedPropertiesHashEncoded = base64.encode(signedPropertiesHash.bytes);

//   String ublSignatureXmlString = defaultUBLExtensions(
//     invoiceHash,
//     signedPropertiesHashEncoded,
//     digitalSignature,
//     cleanUpCertificateString(certificateString),
//     ubl_signature_signed_properties_xml_string
//   );

//   String unsignedInvoiceStr = invoice_copy.toXmlString(pretty: false)
//     .replaceAll("SET_UBL_EXTENSIONS_STRING", ublSignatureXmlString)
//     .replaceAll("SET_QR_CODE_DATA", qr);

//   final signedInvoice = XmlDocument.parse(unsignedInvoiceStr);
//   String signedInvoiceString = signedInvoice.toXmlString(pretty: true);
//   signedInvoiceString = signedPropertiesIndentationFix(signedInvoiceString);

//   return {
//     'signed_invoice_string': signedInvoiceString,
//     'invoice_hash': invoiceHash,
//     'qr': qr,
//   };
// }

// String signedPropertiesIndentationFix(String signedInvoiceString) {
//   RegExp regex = RegExp(r'<ds:Object>([\s\S]*?)<\/ds:Object>');
//   Match? match = regex.firstMatch(signedInvoiceString);

//   if (match == null) {
//     return signedInvoiceString;
//   }

//   String signedPropsContent = match.group(1)!;
//   List<String> signedPropsLines = signedPropsContent.split("\n");
//   List<String> fixedLines = signedPropsLines.map((line) {
//     return line.length >= 4 ? line.substring(4) : line;
//   }).toList();

//   String fixedSignedPropsContent = fixedLines.join("\n");
//   String fixedInvoiceString = signedInvoiceString.replaceFirst(signedPropsContent, fixedSignedPropsContent);
//   print(fixedInvoiceString);
//   return fixedInvoiceString;
// }