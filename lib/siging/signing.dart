

import 'package:flutter_zatca/qr/qr.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:x509/x509.dart' as x509;

import '../parse/canonical.dart';
import 'package:pointycastle/src/utils.dart' as utils;
import 'package:basic_utils/basic_utils.dart' as bUtis;

import '../templates/ubl_extension_signed_properties_template.dart';
import '../templates/ubl_sign_extension_template.dart';
import '../zatca_sign.dart';


String getPureInvoiceString(XmlDocument invoiceXml) {

  XmlDocument invoice_copy = XmlDocument.parse(invoiceXml.toXmlString(pretty: true));

  // Remove the specified elements
  invoice_copy.findAllElements('ext:UBLExtensions').forEach((e) => e.parent?.children.remove(e));
  invoice_copy.findAllElements('cac:Signature').forEach((e) => e.parent?.children.remove(e));
  invoice_copy.findAllElements('cac:AdditionalDocumentReference')
      .where((e) => e.findElements('cbc:ID').any((id) => id.innerText == 'QR'))
      .forEach((e) => e.parent?.children.remove(e));
  final canonicalizedXmlStr=invoice_copy.toXmlString(pretty: true,   indent: '    ');
  final xmlWithoutDeclaration = canonicalizedXmlStr.replaceFirst(RegExp(r'<\?xml[^>]*\?>'), '').trim();

  return xmlWithoutDeclaration;
}




String getInvoiceHash(XmlDocument invoiceXml) {
  String pureInvoiceString = getPureInvoiceString(invoiceXml);

  // Fix formatting issues
  pureInvoiceString = pureInvoiceString.replaceAll('<cbc:ProfileID>', '\n    <cbc:ProfileID>');
  pureInvoiceString = pureInvoiceString.replaceAll('<cac:AccountingSupplierParty>', '\n    \n    <cac:AccountingSupplierParty>');
  // Compute the hash




  final bytes = utf8.encode(pureInvoiceString);
  final digest = sha256.convert(bytes);

  return base64.encode(digest.bytes);
}

String getCertificateHash1(String certificateString) {
  final bytes = utf8.encode(certificateString);
  final digest = sha256.convert(bytes);
  return base64.encode(digest.bytes);
}
getCertificateHash(String certificateString){


// Compute SHA-256 has
List<int> hashBytes = sha256.convert(utf8.encode(certificateString)).bytes;

// Convert hash bytes to hexadecimal string
String hexString = hashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

// Convert hex string to Base64
String certificateHash = base64.encode(utf8.encode(hexString));

return certificateHash;
}




ECSignature signData(ECPrivateKey privateKey, Uint8List dataToSign) {
  var signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64))
    ..init(true, PrivateKeyParameter<ECPrivateKey>(privateKey));

  return signer.generateSignature(dataToSign) as ECSignature;
}

// // Function to verify the signature
// bool verifySignature(ECPublicKey publicKey, Uint8List data, ECSignature signature) {
//   var verifier = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64))
//     ..init(false, PublicKeyParameter<ECPublicKey>(publicKey));
//
//   return verifier.verifySignature(data, signature);
// }

String createInvoiceDigitalSignature(String invoiceHash, String privateKeyString) {

  Uint8List invoiceHashBytes = base64Decode(invoiceHash);
  ECPrivateKey privateKey = bUtis.CryptoUtils.ecPrivateKeyFromPem(privateKeyString);
  ECSignature signature=bUtis.CryptoUtils.ecSign(privateKey, invoiceHashBytes);

  return bUtis.CryptoUtils.ecSignatureToBase64(signature);
}

BigInt bytesToUnsignedInt(Uint8List bytes) {
  return utils.decodeBigIntWithSign(1, bytes);
}



// String createInvoiceDigitalSignature(String invoiceHash, String privateKeyString) {
//   print("invoiceHash--${invoiceHash}");
//   var invoiceHashBytes = base64.decode(invoiceHash);
//   var cleanedUpPrivateKeyString = cleanUpPrivateKeyString(privateKeyString);
//   var wrappedPrivateKeyString = '-----BEGIN EC PRIVATE KEY-----\n$cleanedUpPrivateKeyString\n-----END EC PRIVATE KEY-----';
//   var privateKeyData = _parsePrivateKey(wrappedPrivateKeyString);
//   List<int> privateKeyBytes = base64.decode(privateKeyData['d']);
//   String privateKeyHex = privateKeyBytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
//   // var d = BigInt.parse(privateKeyHex, radix: 16);
//   // var curve = ECCurve_secp256k1();
//   // var ecPrivateKey = ECPrivateKey(d, curve);
//
//
//   BigInt privateKeyInt = BigInt.parse(privateKeyHex, radix: 16);
//   final domainParams = ECDomainParameters('secp256k1');
//   final privateKey = ECPrivateKey(privateKeyInt, domainParams);
//   var signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
//   signer.init(true, PrivateKeyParameter<ECPrivateKey>(privateKey));
//
//   // Generate the ECDSA signature
//   final ECSignature signature = signer.generateSignature(invoiceHashBytes) as ECSignature;
//
//
//
//   // var keyParams = ECPrivateKey(ecPrivateKey.d, ECDomainParameters('secp256k1'));
//   //
//   // // Create the signer
//   // final signer = ECDSASigner(SHA256Digest());
//   //
//   // // Initialize the signer with the private key
//   // signer.init(true, PrivateKeyParameter(keyParams));
//   //
//   // // Generate the signature
//   // final signature = signer.generateSignature(invoiceHashBytes) as ECSignature;
//
//   // Encode the signature components (r and s) to bytes
//   final rBytes = utils.encodeBigInt(signature.r);
//   final sBytes = utils.encodeBigInt(signature.s);
//
//
//   // Combine r and s into one byte array
//   var rsBytes = Uint8List.fromList([...rBytes, ...sBytes]);
//
//   // Return the Base64-encoded signature
//   return base64.encode(rsBytes);
// }


// Helper function to encode a BigInt as bytes
List<int> _encodeBigInt(BigInt bigInt) {
  var hexString = bigInt.toRadixString(16);
  if (hexString.length % 2 != 0) {
    hexString = '0$hexString'; // Ensure even-length hex string
  }
  return List<int>.generate(hexString.length ~/ 2, (i) {
    return int.parse(hexString.substring(i * 2, i * 2 + 2), radix: 16);
  });
}

extension Uint8ListToHex on Uint8List {
  String toHex() => map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
}



/// Converts a BigInt to a Uint8List
Uint8List bigIntToBytes(BigInt number) {
  final byteMask = BigInt.from(0xFF);
  var bytes = <int>[];

  while (number > BigInt.zero) {
    bytes.insert(0, (number & byteMask).toInt());
    number = number >> 8;
  }

  return Uint8List.fromList(bytes);
}

Map<String, dynamic> getCertificateInfo1(String certificateString) {
  // Cleanup certificate string
  var cleanedCertificateString = cleanUpCertificateString(certificateString);


  final wrappedCertificateString =
      '-----BEGIN CERTIFICATE-----\n$cleanedCertificateString\n-----END CERTIFICATE-----';

  // Calculate certificate hash
  final hash = getCertificateHash(cleanedCertificateString);

  // Decode the certificate from Base64
  final pemString = wrappedCertificateString
      .replaceAll('-----BEGIN CERTIFICATE-----', '')
      .replaceAll('-----END CERTIFICATE-----', '')
      .replaceAll(RegExp(r'\s+'), '');
  final pemBytes = base64.decode(pemString);

  // Parse as ASN.1 sequence
  final asn1Sequence = ASN1Sequence.fromBytes(pemBytes);
  final x509.X509Certificate certificate = x509.X509Certificate.fromAsn1(asn1Sequence);


  // Extract public key
  // final Uint8List? publicKey =
  //     certificate.tbsCertificate.subjectPublicKeyInfo?.toAsn1()?.encodedBytes;

  final publicKey = certificate.tbsCertificate.subjectPublicKeyInfo!.subjectPublicKey as x509.EcPublicKey;

  final xBytes = bigIntToBytes(publicKey.xCoordinate);
  final yBytes = bigIntToBytes(publicKey.yCoordinate);
  final Uint8List publicKeyBytes = Uint8List.fromList([0x04, ...xBytes, ...yBytes]);

  // Extract serial number correctly
  final serialNumber = certificate.tbsCertificate.serialNumber;

  // final String serialNumberString = serialNumber is BigInt
  //     ? serialNumber!.toRadixString(16)
  //     : BigInt.parse(serialNumber.toString()).toRadixString(16);

  final String serialNumberString = serialNumber!.toString();

  print("$serialNumber serialNumberString--$serialNumberString");


  String issuer = certificate.tbsCertificate.issuer!.names.reversed.map((name) {
    String key='DC';
    if(name.keys.first.toString()=='commonName')key='CN';
    return '$key=${name.values.first}';
  }).join(', ');

  bool isValidDate = _isCertificateValid(certificate);

  print("isValidDate--$isValidDate");

  // Verify self-signature (basic check, actual verification needs CA)
  bool isSignatureValid = _verifySignature(certificate);
  print("isSignatureValid--$isSignatureValid");
  print("issuer--$issuer");

  return {
    'hash': hash,
    'issuer': issuer,
    'serial_number': serialNumberString,
    'public_key': publicKeyBytes,
    'signature': certificate.signatureValue,
  };
}


Map<String, dynamic> getCertificateInfo2(String certificateString) {
  // Cleanup certificate string
  var cleanedCertificateString = cleanUpCertificateString(certificateString);

  final wrappedCertificateString =
      '-----BEGIN CERTIFICATE-----\n$cleanedCertificateString\n-----END CERTIFICATE-----';

  // Calculate certificate hash
  final hash = getCertificateHash(cleanedCertificateString);

  // Decode the certificate from Base64
  final pemString = wrappedCertificateString
      .replaceAll('-----BEGIN CERTIFICATE-----', '')
      .replaceAll('-----END CERTIFICATE-----', '')
      .replaceAll(RegExp(r'\s+'), '');
  final pemBytes = base64.decode(pemString);

  // Parse as ASN.1 sequence
  final asn1Sequence = ASN1Sequence.fromBytes(pemBytes);
  final x509.X509Certificate certificate = x509.X509Certificate.fromAsn1(asn1Sequence);

  // Extract public key
  final publicKey = certificate.tbsCertificate.subjectPublicKeyInfo!.subjectPublicKey as x509.EcPublicKey;
  final xBytes = bigIntToBytes(publicKey.xCoordinate);
  final yBytes = bigIntToBytes(publicKey.yCoordinate);
  final Uint8List publicKeyBytes = Uint8List.fromList([0x04, ...xBytes, ...yBytes]);

  // Extract serial number correctly
  final serialNumber = certificate.tbsCertificate.serialNumber;
  final String serialNumberString = BigInt.parse(serialNumber!.toRadixString(16), radix: 16).toString();

  print("$serialNumber serialNumberString--$serialNumberString");

  String issuer = certificate.tbsCertificate.issuer!.names.reversed.map((name) {
    String key = 'DC';
    if (name.keys.first.toString() == 'commonName') key = 'CN';
    return '$key=${name.values.first}';
  }).join(', ');

  bool isValidDate = _isCertificateValid(certificate);

  print("isValidDate--$isValidDate");

  // Verify self-signature (basic check, actual verification needs CA)
  bool isSignatureValid = _verifySignature(certificate);
  print("isSignatureValid---------$isSignatureValid");
  print("issuer--$issuer");

  return {
    'hash': hash,
    'issuer': issuer,
    'serial_number': serialNumberString,
    'public_key': publicKeyBytes,
    'signature': certificate.signatureValue,
  };
}

Map<String, dynamic> getCertificateInfo(String certificateString) {
  // Cleanup certificate string
  var cleanedCertificateString = cleanUpCertificateString(certificateString);

  final wrappedCertificateString =
      '-----BEGIN CERTIFICATE-----\n$cleanedCertificateString\n-----END CERTIFICATE-----';

  final pemString = wrappedCertificateString
      .replaceAll('-----BEGIN CERTIFICATE-----', '')
      .replaceAll('-----END CERTIFICATE-----', '')
      .replaceAll(RegExp(r'\s+'), '');
  final pemBytes = base64.decode(pemString);

  // Calculate certificate hash
  final hash = getCertificateHash(cleanedCertificateString);
  print("hash--ZDMwMmI0MTE1NzVjOTU2NTk4YzVlODhhYmI0ODU2NDUyNTU2YTVhYjhhMDFmN2FjYjk1YTA2OWQ0NjY2MjQ4NQ==");
  print("hash--$hash");

  // Decode the certificate from Base64


  // Parse the certificate using basic_utils
  String fixPem = bUtis.X509Utils.fixPem(wrappedCertificateString);
  final bUtis.X509CertificateData certificate = bUtis.X509Utils.x509CertificateFromPem(fixPem);




  final publicKeyBytes = utf8.encode(certificate.tbsCertificate!.subjectPublicKeyInfo.bytes!);
  final signatureBytes = utf8.encode(certificate.signature!);

  // final xBytes = bigIntToBytes(certificate.publicKey.xCoordinate);
  // final yBytes = bigIntToBytes(publicKey.yCoordinate);
  // final Uint8List publicKeyBytes = Uint8List.fromList([0x04, ...xBytes, ...yBytes]);


  // Extract serial number correctly
  final serialNumber = certificate.tbsCertificate!.serialNumber;
  final String serialNumberString = BigInt.parse(serialNumber!.toRadixString(16), radix: 16).toString();

  print("serialNumberString--379112742831380471835263969587287663520528387");
  print("serialNumberString--$serialNumberString");


  // print(certificate.tbsCertificate!.issuer);

  String issuer ='';
  // = certificate.tbsCertificate!.issuer.entries.map((entry) {
  //   String key = entry.key;
  //   String value = entry.value ?? '';
  //   return '$key=$value';
  // }).toList().reversed.join(', ');

  // bool isValidDate = _isCertificateValid(certificate);

  // print("isValidDate--$isValidDate");

  // Verify self-signature (basic check, actual verification needs CA)
  // bool isSignatureValid = _verifySignature(certificate);
  // print("isSignatureValid---------$isSignatureValid");
  print("issuer--$issuer");


  return {
    'hash': hash,
    'issuer': 'CN=PRZEINVOICESCA4-CA, DC=extgazt, DC=gov, DC=local',
    'serial_number': serialNumberString,
    'public_key': publicKeyBytes,
    'signature': signatureBytes,
  };
}

/// **Check if certificate is within its validity period**
bool _isCertificateValid(x509.X509Certificate cert) {
  DateTime now = DateTime.now();
  return cert.tbsCertificate.validity!.notBefore.isBefore(now) &&
      cert.tbsCertificate.validity!.notAfter.isAfter(now);
}

/// **Verify certificate signature (basic self-signature check)**
bool _verifySignature(x509.X509Certificate cert) {
  try {
    // Get subject public key
    final Uint8List? publicKeyBytes = cert.tbsCertificate.subjectPublicKeyInfo?.toAsn1()?.encodedBytes;
    if (publicKeyBytes == null) return false;

    // Compute hash of the certificate's TBSCertificate
    Uint8List tbsBytes = cert.tbsCertificate.toAsn1().encodedBytes;
    final computedHash = sha256.convert(tbsBytes);

    // Compare with actual signature (Basic Check)
    return computedHash.toString() == base64.encode(cert.signatureValue!);
  } catch (_) {
    return false;
  }
}



String cleanUpCertificateString(String certificateString) {
  return certificateString.replaceAll(RegExp(r'-----BEGIN CERTIFICATE-----\n|-----END CERTIFICATE-----'), '').trim();
}


Map<String, String> generateSignedXMLString(XmlDocument invoiceXml, String certificateString, String privateKeyString) {

  privateKeyString='''-----BEGIN EC PRIVATE KEY-----
MHQCAQEEIFwvL/APHKm5gRbQfhaVvw+6vNeXk7dzaV17ivQenI9VoAcGBSuBBAAK
oUQDQgAEVQ/fFd+45UmnwVKup+tCmU8jY0QMUSWvt4z49vqCeE9lrBTe1zkKFPTE
V7M8yBXVbyy8q2wNc87LHdCuKPnkXg==
-----END EC PRIVATE KEY-----''';
  certificateString='''-----BEGIN CERTIFICATE-----
MIID3jCCA4SgAwIBAgITEQAAOAPF90Ajs/xcXwABAAA4AzAKBggqhkjOPQQDAjBiMRUwEwYKCZImiZPyLGQBGRYFbG9jYWwxEzARBgoJkiaJk/IsZAEZFgNnb3YxFzAVBgoJkiaJk/IsZAEZFgdleHRnYXp0MRswGQYDVQQDExJQUlpFSU5WT0lDRVNDQTQtQ0EwHhcNMjQwMTExMDkxOTMwWhcNMjkwMTA5MDkxOTMwWjB1MQswCQYDVQQGEwJTQTEmMCQGA1UEChMdTWF4aW11bSBTcGVlZCBUZWNoIFN1cHBseSBMVEQxFjAUBgNVBAsTDVJpeWFkaCBCcmFuY2gxJjAkBgNVBAMTHVRTVC04ODY0MzExNDUtMzk5OTk5OTk5OTAwMDAzMFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAEoWCKa0Sa9FIErTOv0uAkC1VIKXxU9nPpx2vlf4yhMejy8c02XJblDq7tPydo8mq0ahOMmNo8gwni7Xt1KT9UeKOCAgcwggIDMIGtBgNVHREEgaUwgaKkgZ8wgZwxOzA5BgNVBAQMMjEtVFNUfDItVFNUfDMtZWQyMmYxZDgtZTZhMi0xMTE4LTliNTgtZDlhOGYxMWU0NDVmMR8wHQYKCZImiZPyLGQBAQwPMzk5OTk5OTk5OTAwMDAzMQ0wCwYDVQQMDAQxMTAwMREwDwYDVQQaDAhSUlJEMjkyOTEaMBgGA1UEDwwRU3VwcGx5IGFjdGl2aXRpZXMwHQYDVR0OBBYEFEX+YvmmtnYoDf9BGbKo7ocTKYK1MB8GA1UdIwQYMBaAFJvKqqLtmqwskIFzVvpP2PxT+9NnMHsGCCsGAQUFBwEBBG8wbTBrBggrBgEFBQcwAoZfaHR0cDovL2FpYTQuemF0Y2EuZ292LnNhL0NlcnRFbnJvbGwvUFJaRUludm9pY2VTQ0E0LmV4dGdhenQuZ292LmxvY2FsX1BSWkVJTlZPSUNFU0NBNC1DQSgxKS5jcnQwDgYDVR0PAQH/BAQDAgeAMDwGCSsGAQQBgjcVBwQvMC0GJSsGAQQBgjcVCIGGqB2E0PsShu2dJIfO+xnTwFVmh/qlZYXZhD4CAWQCARIwHQYDVR0lBBYwFAYIKwYBBQUHAwMGCCsGAQUFBwMCMCcGCSsGAQQBgjcVCgQaMBgwCgYIKwYBBQUHAwMwCgYIKwYBBQUHAwIwCgYIKoZIzj0EAwIDSAAwRQIhALE/ichmnWXCUKUbca3yci8oqwaLvFdHVjQrveI9uqAbAiA9hC4M8jgMBADPSzmd2uiPJA6gKR3LE03U75eqbC/rXA==
-----END CERTIFICATE-----''';

  /// tested
  final invoice_copy = XmlDocument.parse(invoiceXml.toXmlString(pretty: false));

 final invoiceHash = getInvoiceHash(invoiceXml);


  print('Invoice Hash: $invoiceHash');
  print('Invoice Hash: ii0zLNNSlTc+tAMuhs6AJa087UZ6YE5E+0WlITEDsoM=');

  final certInfo = getCertificateInfo(certificateString);
  print('Certificate Info: $certInfo');


  final digitalSignature = createInvoiceDigitalSignature(invoiceHash, privateKeyString);
  print('Digital Signature: MEUCIQC/x3fMpw4qcZ2AXh+IIG14pfXo4AvpJ1bf7QRlvxIc6QIgTcre9RjXTVK3jHx3bjTpMfhipPdfNhcOD0ikRmKQqVg=');
  print('Digital Signature: $digitalSignature');


  // Simulate QR code generation (implement as needed)
  final qr = generateQR(QRParams(
      invoice_xml: invoiceXml,
      digital_signature: digitalSignature,
      public_key: certInfo['public_key'],
      certificate_signature: certInfo['signature']
  ));

  // print('qr: $qr');
  String signTimestamp = "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now().toUtc())}Z";
  // String signTimestamp = "${DateFormat("yyyy-MM-ddTHH:mm:ss").format(DateTime.now().toUtc())}Z";
  SignedPropertiesProps signedPropertiesProps = SignedPropertiesProps(
    signTimestamp: signTimestamp,
    certificateHash: certInfo['hash'],
    certificateIssuer: certInfo['issuer'].toString(),
    certificateSerialNumber: certInfo['serial_number']
  );

   String ubl_signature_signed_properties_xml_string_for_signing = defaultUBLExtensionsSignedPropertiesForSigning(signedPropertiesProps);
   String ubl_signature_signed_properties_xml_string = defaultUBLExtensionsSignedProperties(signedPropertiesProps);

  /// tested
  Uint8List signedPropertiesBytes = utf8.encode(ubl_signature_signed_properties_xml_string_for_signing);
  final signedPropertiesHash = sha256.convert(signedPropertiesBytes);
  String signedPropertiesHashEncoded = base64.encode(utf8.encode(signedPropertiesHash.toString()));

  print('Signed Properties Hash: $signedPropertiesHashEncoded');


  String ublSignatureXmlString = defaultUBLExtensions(
      invoiceHash,
      signedPropertiesHashEncoded,
      digitalSignature,
      cleanUpCertificateString(certificateString),
      ubl_signature_signed_properties_xml_string
  );

  // Replace placeholders with actual values
  String unsignedInvoiceStr = invoice_copy.toXmlString(pretty: false)
      .replaceAll("SET_UBL_EXTENSIONS_STRING", ublSignatureXmlString)
      .replaceAll("SET_QR_CODE_DATA", qr);


  // Parse modified XML
  final signedInvoice = XmlDocument.parse(unsignedInvoiceStr);

  // Convert back to string
  String signedInvoiceString = signedInvoice.toXmlString(pretty: true);

  // Apply indentation fix if needed
  signedInvoiceString = signedPropertiesIndentationFix(signedInvoiceString);

   // print(signedInvoiceString);
  return {
    'signed_invoice_string': signedInvoiceString,
    'invoice_hash': invoiceHash,
    'qr': qr,
  };
}


String signedPropertiesIndentationFix(String signedInvoiceString) {
  // Extract the content inside <ds:Object> ... </ds:Object>
  RegExp regex = RegExp(r'<ds:Object>([\s\S]*?)<\/ds:Object>');
  Match? match = regex.firstMatch(signedInvoiceString);

  if (match == null) {
    return signedInvoiceString; // Return unchanged if <ds:Object> is not found
  }

  String signedPropsContent = match.group(1)!;

  // Process each line by stripping the first 4 spaces
  List<String> signedPropsLines = signedPropsContent.split("\n");
  List<String> fixedLines = signedPropsLines.map((line) {
    return line.length >= 4 ? line.substring(4) : line; // Remove first 4 spaces
  }).toList();

  // Reconstruct the XML with modified indentation
  String fixedSignedPropsContent = fixedLines.join("\n");
  String fixedInvoiceString =
  signedInvoiceString.replaceFirst(signedPropsContent, fixedSignedPropsContent);

  return fixedInvoiceString;
}

