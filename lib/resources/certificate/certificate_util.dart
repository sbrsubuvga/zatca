import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:crypto/crypto.dart';
import '../../models/certificate_info.dart';

class CertificateUtil {
  /// Cleans the PEM certificate by removing header, footer, and line breaks.
  static String cleanCertificatePem(String pem) {
    return pem
        .replaceAll("-----BEGIN CERTIFICATE-----", "")
        .replaceAll("-----END CERTIFICATE-----", "")
        .replaceAll("\n", "")
        .replaceAll("\r", ""); // Handle potential carriage returns
  }

  /// Extracts certificate information such as hash, issuer, serial number, public key, and signature.
  static CertificateInfo getCertificateInfo(String pem) {
    /// Generate hash of the DER-encoded certificate
    final pemContent = cleanCertificatePem(pem);
    final certDerBytes = base64.decode(pemContent);
    final hashBytes = sha256.convert(certDerBytes).bytes;
    final hashBase64Encoded = base64.encode(hashBytes);

    /// Decode the PEM content into bytes
    final bytes = _decodePem(pem);
    final asn1Parser = ASN1Parser(bytes);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    /// Extract tbsCertificate (to-be-signed certificate) from the sequence
    final tbsCertificate = topLevelSeq.elements[0] as ASN1Sequence;

    /// Extract serial number from tbsCertificate
    final serialNumberASN1 = tbsCertificate.elements[1] as ASN1Integer;
    final serialNumber = serialNumberASN1.valueAsBigInteger;

    /// Extract issuer information from tbsCertificate
    final issuerSeq = tbsCertificate.elements[3] as ASN1Sequence;
    final issuer = _parseName(issuerSeq);

    /// Extract signature from the top-level sequence
    final signature = topLevelSeq.elements[2] as ASN1BitString;
    final signatureBytes = signature.valueBytes().sublist(1);

    /// Construct the public key in DER format
    final publicKeyDER = [
      ...[0x30, 0x56], // SEQUENCE header
      ...[0x30, 0x10], // OID for EC public key
      ...[0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01],
      ...[0x06, 0x05, 0x2B, 0x81, 0x04, 0x00, 0x0A],
      ...[0x03, 0x42, 0x00],
      ..._extractPublicKey(tbsCertificate),
    ];

    /// Return the parsed certificate information
    return CertificateInfo(
      hash: hashBase64Encoded,
      issuer: issuer,
      serialNumber: serialNumber.toString(),
      publicKey: base64.encode(publicKeyDER),
      signature: base64.encode(signatureBytes),
    );
  }

  /// Extracts the public key bytes from the tbsCertificate.
  static Uint8List _extractPublicKey(ASN1Sequence tbsCertificate) {
    final subjectPublicKeyInfo = tbsCertificate.elements[6] as ASN1Sequence;
    final publicKeyBitString =
        subjectPublicKeyInfo.elements[1] as ASN1BitString;
    return publicKeyBitString.contentBytes();
  }

  /// Decodes a PEM string into a Uint8List of bytes.
  static Uint8List _decodePem(String pem) {
    final lines =
        pem.split('\n').where((line) => !line.startsWith('-----')).toList();
    final base64Str = lines.join('');
    return base64Decode(base64Str);
  }

  /// Parses an ASN1 sequence to extract and format the issuer or subject name.
  static String _parseName(ASN1Sequence seq) {
    final parts = <String>[];
    for (final rdnSet in seq.elements) {
      final rdnSeq = (rdnSet as ASN1Set).elements.first as ASN1Sequence;
      final oid = rdnSeq.elements[0] as ASN1ObjectIdentifier;
      final value = rdnSeq.elements[1];
      final decodedValue = _decodeASN1String(value);
      parts.add('${_oidToName(oid.identifier!)}=$decodedValue');
    }
    return parts.reversed.join(', ');
  }

  /// Maps OID (Object Identifier) to a human-readable name.
  static String _oidToName(String oid) {
    switch (oid) {
      case '2.5.4.6':
        return 'C';

      /// Country
      case '2.5.4.10':
        return 'O';

      /// Organization
      case '2.5.4.11':
        return 'OU';

      /// Organizational Unit
      case '2.5.4.3':
        return 'CN';

      /// Common Name
      case '0.9.2342.19200300.100.1.25':
        return 'DC';

      /// Domain Component
      default:
        return oid;
    }
  }

  /// Decodes an ASN1 object into a UTF-8 string.
  static String _decodeASN1String(ASN1Object obj) {
    return utf8.decode(obj.valueBytes());
  }
}
