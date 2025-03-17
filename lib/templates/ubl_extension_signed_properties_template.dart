class SignedPropertiesProps {
  final String signTimestamp;
  final String certificateHash;
  final String certificateIssuer;
  final String certificateSerialNumber;

  SignedPropertiesProps({
    required this.signTimestamp,
    required this.certificateHash,
    required this.certificateIssuer,
    required this.certificateSerialNumber,
  });
}

String defaultUBLExtensionsSignedPropertiesForSigning(SignedPropertiesProps props) {
  const template = '''<xades:SignedProperties xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" Id="xadesSignedProperties">
                                    <xades:SignedSignatureProperties>
                                        <xades:SigningTime>SET_SIGN_TIMESTAMP</xades:SigningTime>
                                        <xades:SigningCertificate>
                                            <xades:Cert>
                                                <xades:CertDigest>
                                                    <ds:DigestMethod xmlns:ds="http://www.w3.org/2000/09/xmldsig#" Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
                                                    <ds:DigestValue xmlns:ds="http://www.w3.org/2000/09/xmldsig#">SET_CERTIFICATE_HASH</ds:DigestValue>
                                                </xades:CertDigest>
                                                <xades:IssuerSerial>
                                                    <ds:X509IssuerName xmlns:ds="http://www.w3.org/2000/09/xmldsig#">SET_CERTIFICATE_ISSUER</ds:X509IssuerName>
                                                    <ds:X509SerialNumber xmlns:ds="http://www.w3.org/2000/09/xmldsig#">SET_CERTIFICATE_SERIAL_NUMBER</ds:X509SerialNumber>
                                                </xades:IssuerSerial>
                                            </xades:Cert>
                                        </xades:SigningCertificate>
                                    </xades:SignedSignatureProperties>
                                </xades:SignedProperties>''';

  return template
      .replaceAll("SET_SIGN_TIMESTAMP", props.signTimestamp)
      .replaceAll("SET_CERTIFICATE_HASH", props.certificateHash)
      .replaceAll("SET_CERTIFICATE_ISSUER", props.certificateIssuer)
      .replaceAll("SET_CERTIFICATE_SERIAL_NUMBER", props.certificateSerialNumber);
}


String defaultUBLExtensionsSignedProperties(SignedPropertiesProps props) {
  const templateAfterSigning = '''<xades:SignedProperties xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" Id="xadesSignedProperties">
                                <xades:SignedSignatureProperties>
                                    <xades:SigningTime>SET_SIGN_TIMESTAMP</xades:SigningTime>
                                    <xades:SigningCertificate>
                                        <xades:Cert>
                                            <xades:CertDigest>
                                                <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"></ds:DigestMethod>
                                                <ds:DigestValue>SET_CERTIFICATE_HASH</ds:DigestValue>
                                            </xades:CertDigest>
                                            <xades:IssuerSerial>
                                                <ds:X509IssuerName>SET_CERTIFICATE_ISSUER</ds:X509IssuerName>
                                                <ds:X509SerialNumber>SET_CERTIFICATE_SERIAL_NUMBER</ds:X509SerialNumber>
                                            </xades:IssuerSerial>
                                        </xades:Cert>
                                    </xades:SigningCertificate>
                                </xades:SignedSignatureProperties>
                            </xades:SignedProperties>''';

  return templateAfterSigning
      .replaceAll("SET_SIGN_TIMESTAMP", props.signTimestamp)
      .replaceAll("SET_CERTIFICATE_HASH", props.certificateHash)
      .replaceAll("SET_CERTIFICATE_ISSUER", props.certificateIssuer)
      .replaceAll("SET_CERTIFICATE_SERIAL_NUMBER", props.certificateSerialNumber);
}
