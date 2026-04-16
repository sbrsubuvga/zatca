/// This class represents the information of a certificate.
class CertificateInfo {
  final String hash;
  final String issuer;
  final String serialNumber;
  final String publicKey;
  final String signature;
  CertificateInfo({
    required this.hash,
    required this.issuer,
    required this.serialNumber,
    required this.publicKey,
    required this.signature,
  });
}
