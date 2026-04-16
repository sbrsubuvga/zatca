import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart';

class SignatureUtil {
  /// Parses a Base64-encoded private key in PKCS#8 or SEC1 format and returns an ECPrivateKey object.
  ///
  /// [base64Key] - The Base64-encoded private key string.
  ///
  /// Throws [ArgumentError] if the private key format is invalid.
  static ECPrivateKey parsePrivateKey(String base64Key) {
    String cleanedBase64Key = base64Key
        .replaceAll('-----BEGIN EC PRIVATE KEY-----', '')
        .replaceAll('-----END EC PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(' ', '');

    /// Decode the Base64 key
    final keyBytes = base64.decode(cleanedBase64Key);

    /// Parse the ASN.1 structure
    final asn1Parser = ASN1Parser(keyBytes);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    if (topLevelSeq.elements.length == 3) {
      /// PKCS#8 format
      final privateKeyOctets =
          (topLevelSeq.elements[2] as ASN1OctetString).octets;
      final privateKeyParser = ASN1Parser(privateKeyOctets);
      final pkSeq = privateKeyParser.nextObject() as ASN1Sequence;

      final privateKeyInt =
          (pkSeq.elements[1] as ASN1Integer).valueAsBigInteger;
      final curve = ECCurve_secp256k1();
      return ECPrivateKey(privateKeyInt, curve);
    } else if (topLevelSeq.elements.length == 4) {
      /// SEC1 format
      final privateKeyBytes =
          (topLevelSeq.elements[1] as ASN1OctetString).octets;
      final privateKeyInt = BigInt.parse(
        privateKeyBytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16,
      );
      final curve = ECCurve_secp256k1();
      return ECPrivateKey(privateKeyInt, curve);
    } else {
      throw ArgumentError('Invalid private key format');
    }
  }

  /// Creates a digital signature for the given invoice hash using the provided private key.
  ///
  /// [invoiceHashBase64] - The Base64-encoded hash of the invoice.
  /// [privateKeyPem] - The PEM-encoded EC private key.
  ///
  /// Returns the Base64-encoded digital signature.
  static String createInvoiceDigitalSignature(
    String invoiceHashBase64,
    String privateKeyPem,
  ) {
    final invoiceHashBytes = base64.decode(invoiceHashBase64);

    // Parse the EC private key from PEM format
    final privateKey = _parseECPrivateKeyFromPem(privateKeyPem);

    // Sign using SHA-256 with ECDSA
    final signer = Signer('SHA-256/ECDSA');
    signer.init(
      true, // true = signing
      ParametersWithRandom(
        PrivateKeyParameter<ECPrivateKey>(privateKey),
        _getSecureRandom(),
      ),
    );

    ECSignature sig =
        signer.generateSignature(Uint8List.fromList(invoiceHashBytes))
            as ECSignature;

    // ASN.1 encode (DER format)
    final asn1Seq =
        ASN1Sequence()
          ..add(ASN1Integer(sig.r))
          ..add(ASN1Integer(sig.s));
    final derEncoded = asn1Seq.encodedBytes;

    return base64.encode(derEncoded);
  }

  /// Helper method to parse an EC private key from PEM format and return an ECPrivateKey object.
  ///
  /// [pem] - The PEM-encoded EC private key.
  ///
  /// Returns an [ECPrivateKey] object.
  static ECPrivateKey _parseECPrivateKeyFromPem(String pem) {
    final lines = pem
        .replaceAll('-----BEGIN EC PRIVATE KEY-----', '')
        .replaceAll('-----END EC PRIVATE KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '');
    final keyBytes = base64.decode(lines);

    final asn1Parser = ASN1Parser(Uint8List.fromList(keyBytes));
    final sequence = asn1Parser.nextObject() as ASN1Sequence;

    final privateKeyInt =
        (sequence.elements[1] as ASN1OctetString).valueBytes();
    final privateKeyNum = BigInt.parse(hex.encode(privateKeyInt), radix: 16);

    final domainParams = ECDomainParameters('secp256k1');

    return ECPrivateKey(privateKeyNum, domainParams);
  }

  /// Generates a secure random number generator using FortunaRandom.
  ///
  /// Returns a [SecureRandom] instance seeded with a cryptographically secure random value.
  static SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seed = Uint8List(32);
    for (int i = 0; i < seed.length; i++) {
      seed[i] = seedSource.nextInt(256);
    }
    secureRandom.seed(KeyParameter(seed));
    return secureRandom;
  }
}
