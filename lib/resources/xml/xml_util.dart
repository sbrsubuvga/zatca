import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import 'package:zatca/models/invoice.dart';
import 'package:zatca/models/supplier.dart';

class XmlUtil {
  ///     Generate a ZATCA-compliant XML string for the invoice data.
  static XmlDocument generateZATCAXml(
    BaseInvoice invoice,
    Supplier supplier, {
    required int icv,
  }) {
    final builder = XmlBuilder();
    final formatter = NumberFormat("#.##");
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'Invoice',
      nest: () {
        builder.attribute(
          'xmlns',
          'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2',
        );
        builder.attribute(
          'xmlns:cac',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
        );
        builder.attribute(
          'xmlns:cbc',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
        );
        builder.attribute(
          'xmlns:ext',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2',
        );
        builder.element('cbc:ProfileID', nest: invoice.profileID);
        builder.element('cbc:ID', nest: invoice.invoiceNumber);
        builder.element('cbc:UUID', nest: invoice.uuid);
        builder.element('cbc:IssueDate', nest: invoice.issueDate);
        builder.element('cbc:IssueTime', nest: invoice.issueTime);

        builder.element(
          'cbc:InvoiceTypeCode',
          nest: () {
            builder.attribute(
              'name',
              invoice.invoiceType.invoiceRelationType.value,
            );
            builder.text(invoice.invoiceType.code);
          },
        );

        // builder.element(
        //   'cbc:Note',
        //   nest: () {
        //     builder.attribute('languageID', 'ar');
        //     builder.text(data.note);
        //   },
        // );
        builder.element('cbc:DocumentCurrencyCode', nest: invoice.currencyCode);
        builder.element('cbc:TaxCurrencyCode', nest: invoice.taxCurrencyCode);

        if (invoice is DBInvoice) {
          builder.element(
            'cac:BillingReference',
            nest: () {
              builder.element(
                'cac:InvoiceDocumentReference',
                nest: () {
                  builder.element(
                    'cbc:ID',
                    nest: () {
                      builder.text(
                        invoice.cancellation.canceledSerialInvoiceNumber,
                      );
                    },
                  );
                },
              );
            },
          );
        }

        builder.element(
          'cac:AdditionalDocumentReference',
          nest: () {
            builder.element('cbc:ID', nest: 'ICV');
            builder.element('cbc:UUID', nest: icv.toString());
          },
        );
        builder.element(
          'cac:AdditionalDocumentReference',
          nest: () {
            builder.element('cbc:ID', nest: 'PIH');
            builder.element(
              'cac:Attachment',
              nest: () {
                builder.element(
                  'cbc:EmbeddedDocumentBinaryObject',
                  nest: invoice.previousInvoiceHash,
                  attributes: {'mimeCode': 'text/plain'},
                );
              },
            );
          },
        );

        // Supplier
        builder.element(
          'cac:AccountingSupplierParty',
          nest: () {
            builder.element(
              'cac:Party',
              nest: () {
                builder.element(
                  'cac:PartyIdentification',
                  nest: () {
                    builder.element(
                      'cbc:ID',
                      nest: () {
                        builder.attribute('schemeID', 'CRN');
                        builder.text(supplier.companyCRN);
                      },
                    );
                  },
                );
                builder.element(
                  'cac:PostalAddress',
                  nest: () {
                    builder.element(
                      'cbc:StreetName',
                      nest: supplier.location.street,
                    );
                    builder.element(
                      'cbc:BuildingNumber',
                      nest: supplier.location.building,
                    );
                    builder.element(
                      'cbc:PlotIdentification',
                      nest: supplier.location.plotIdentification,
                    );
                    builder.element(
                      'cbc:CitySubdivisionName',
                      nest: supplier.location.citySubdivision,
                    );
                    builder.element(
                      'cbc:CityName',
                      nest: supplier.location.city,
                    );
                    builder.element(
                      'cbc:PostalZone',
                      nest: supplier.location.postalZone,
                    );
                    builder.element(
                      'cac:Country',
                      nest: () {
                        builder.element(
                          'cbc:IdentificationCode',
                          nest: supplier.location.countryCode,
                        );
                      },
                    );
                  },
                );
                builder.element(
                  'cac:PartyTaxScheme',
                  nest: () {
                    builder.element('cbc:CompanyID', nest: supplier.companyID);
                    builder.element(
                      'cac:TaxScheme',
                      nest: () {
                        builder.element('cbc:ID', nest: 'VAT');
                      },
                    );
                  },
                );
                builder.element(
                  'cac:PartyLegalEntity',
                  nest: () {
                    builder.element(
                      'cbc:RegistrationName',
                      nest: supplier.registrationName,
                    );
                  },
                );
              },
            );
          },
        );

        // Customer
        builder.element(
          'cac:AccountingCustomerParty',
          nest: () {
            builder.element(
              'cac:Party',
              nest: () {
                // Check invoice type
                bool isStandardInvoice =
                    invoice is StandardInvoice ||
                    invoice is StandardCreditNoteInvoice ||
                    invoice is StandardDebitNoteInvoice;

                if (isStandardInvoice && invoice.customer != null) {
                  // ✅ STANDARD INVOICE - Full customer details

                  // PartyIdentification - CR Number (Commercial Registration)
                  if (invoice.customer!.businessID != null &&
                      invoice.customer!.businessID!.isNotEmpty) {
                    builder.element(
                      'cac:PartyIdentification',
                      nest: () {
                        builder.element(
                          'cbc:ID',
                          nest: () {
                            builder.attribute('schemeID', 'CRN');
                            builder.text(invoice.customer!.businessID!);
                          },
                        );
                      },
                    );
                  }

                  // PostalAddress - Full customer address
                  builder.element(
                    'cac:PostalAddress',
                    nest: () {
                      builder.element(
                        'cbc:StreetName',
                        nest: invoice.customer!.address.street,
                      );
                      builder.element(
                        'cbc:BuildingNumber',
                        nest: invoice.customer!.address.building,
                      );
                      builder.element(
                        'cbc:PlotIdentification',
                        nest: invoice.customer!.address.building,
                      );
                      builder.element(
                        'cbc:CitySubdivisionName',
                        nest: invoice.customer!.address.citySubdivision,
                      );
                      builder.element(
                        'cbc:CityName',
                        nest: invoice.customer!.address.city,
                      );
                      builder.element(
                        'cbc:PostalZone',
                        nest: invoice.customer!.address.postalZone,
                      );
                      builder.element(
                        'cac:Country',
                        nest: () {
                          builder.element(
                            'cbc:IdentificationCode',
                            nest: invoice.customer!.address.countryCode,
                          );
                        },
                      );
                    },
                  );

                  // PartyTaxScheme - VAT Number
                  builder.element(
                    'cac:PartyTaxScheme',
                    nest: () {
                      builder.element(
                        'cbc:CompanyID',
                        nest: invoice.customer!.companyID,
                      );
                      builder.element(
                        'cac:TaxScheme',
                        nest: () {
                          builder.element('cbc:ID', nest: 'VAT');
                        },
                      );
                    },
                  );

                  // PartyLegalEntity - Customer Name
                  builder.element(
                    'cac:PartyLegalEntity',
                    nest: () {
                      builder.element(
                        'cbc:RegistrationName',
                        nest: invoice.customer!.registrationName,
                      );
                    },
                  );
                } else {
                  // ✅ SIMPLIFIED INVOICE - Empty customer fields (B2C)
                  builder.element(
                    'cac:PostalAddress',
                    nest: () {
                      builder.element('cbc:StreetName', nest: '');
                    },
                  );
                  builder.element(
                    'cac:PartyTaxScheme',
                    nest: () {
                      builder.element('cbc:CompanyID', nest: '');
                      builder.element(
                        'cac:TaxScheme',
                        nest: () {
                          builder.element('cbc:ID', nest: 'VAT');
                        },
                      );
                    },
                  );
                  builder.element(
                    'cac:PartyLegalEntity',
                    nest: () {
                      builder.element('cbc:RegistrationName', nest: '');
                    },
                  );
                }
              },
            );
          },
        );

        if (invoice is Invoice) {
          builder.element(
            'cac:Delivery',
            nest: () {
              builder.element(
                'cbc:ActualDeliveryDate',
                nest: invoice.actualDeliveryDate,
              );
            },
          );
        }
        if (invoice is DBInvoice) {
          builder.element(
            'cac:PaymentMeans',
            nest: () {
              builder.element(
                'cbc:PaymentMeansCode',
                nest: invoice.cancellation.paymentMethod.value,
              );
              builder.element(
                'cbc:InstructionNote',
                nest: invoice.cancellation.reason,
              );
            },
          );
        }

        // Totals
        builder.element(
          'cac:TaxTotal',
          nest: () {
            builder.element(
              'cbc:TaxAmount',
              nest: () {
                builder.attribute('currencyID', 'SAR');
                builder.text(invoice.taxAmount.toStringAsFixed(2));
              },
            );
            builder.element(
              'cac:TaxSubtotal',
              nest: () {
                builder.element(
                  'cbc:TaxableAmount',
                  nest: () {
                    builder.attribute('currencyID', 'SAR');
                    builder.text(
                      formatter.format(invoice.totalAmount - invoice.taxAmount),
                    );
                  },
                );
                builder.element(
                  'cbc:TaxAmount',
                  nest: () {
                    builder.attribute('currencyID', 'SAR');
                    builder.text(formatter.format(invoice.taxAmount));
                  },
                );
                builder.element(
                  'cac:TaxCategory',
                  nest: () {
                    builder.element(
                      'cbc:ID',
                      nest: () {
                        builder.attribute('schemeAgencyID', '6');
                        builder.attribute('schemeID', 'UN/ECE 5305');
                        builder.text('S');
                      },
                    );
                    builder.element('cbc:Percent', nest: '15');
                    builder.element(
                      'cac:TaxScheme',
                      nest: () {
                        builder.element(
                          'cbc:ID',
                          nest: () {
                            builder.attribute('schemeAgencyID', '6');
                            builder.attribute('schemeID', 'UN/ECE 5153');
                            builder.text('VAT');
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
        builder.element(
          'cac:TaxTotal',
          nest: () {
            builder.element(
              'cbc:TaxAmount',
              nest: () {
                builder.attribute('currencyID', 'SAR');
                builder.text(invoice.taxAmount.toStringAsFixed(2));
              },
            );
          },
        );

        builder.element(
          'cac:LegalMonetaryTotal',
          nest: () {
            double taxableAmount = invoice.totalAmount - invoice.taxAmount;
            builder.element(
              'cbc:LineExtensionAmount',
              nest: () {
                builder.attribute('currencyID', 'SAR');
                builder.text(taxableAmount.toStringAsFixed(2));
              },
            );
            builder.element(
              'cbc:TaxExclusiveAmount',
              nest: () {
                builder.attribute('currencyID', 'SAR');
                builder.text(formatter.format(taxableAmount));
              },
            );
            builder.element(
              'cbc:TaxInclusiveAmount',
              nest: () {
                builder.attribute('currencyID', 'SAR');
                builder.text(invoice.totalAmount.toStringAsFixed(2));
              },
            );
            builder.element(
              'cbc:PrepaidAmount',
              nest: () {
                builder.attribute('currencyID', 'SAR');
                builder.text('0');
              },
            );
            builder.element(
              'cbc:PayableAmount',
              nest: () {
                builder.attribute('currencyID', 'SAR');
                builder.text(invoice.totalAmount.toStringAsFixed(2));
              },
            );
          },
        );

        // Invoice Lines
        for (var line in invoice.invoiceLines) {
          builder.element(
            'cac:InvoiceLine',
            nest: () {
              builder.element('cbc:ID', nest: line.id);
              builder.element(
                'cbc:InvoicedQuantity',
                nest: () {
                  builder.attribute('unitCode', line.unitCode);
                  builder.text(line.quantity);
                },
              );
              builder.element(
                'cbc:LineExtensionAmount',
                nest: () {
                  builder.attribute('currencyID', 'SAR');
                  builder.text(line.lineExtensionAmount.toStringAsFixed(2));
                },
              );
              builder.element(
                'cac:TaxTotal',
                nest: () {
                  builder.element(
                    'cbc:TaxAmount',
                    nest: () {
                      builder.attribute('currencyID', 'SAR');
                      builder.text(line.taxAmount.toStringAsFixed(2));
                    },
                  );
                  double roundingAmount = line.roundingAmount;
                  builder.element(
                    'cbc:RoundingAmount',
                    nest: () {
                      builder.attribute('currencyID', 'SAR');
                      builder.text(roundingAmount.toStringAsFixed(2));
                    },
                  );
                },
              );
              builder.element(
                'cac:Item',
                nest: () {
                  builder.element('cbc:Name', nest: line.itemName);
                  builder.element(
                    'cac:ClassifiedTaxCategory',
                    nest: () {
                      builder.element('cbc:ID', nest: 'S');
                      builder.element(
                        'cbc:Percent',
                        nest: formatter.format(line.taxPercent),
                      );
                      builder.element(
                        'cac:TaxScheme',
                        nest: () {
                          builder.element('cbc:ID', nest: 'VAT');
                        },
                      );
                    },
                  );
                },
              );
              builder.element(
                'cac:Price',
                nest: () {
                  builder.element(
                    'cbc:PriceAmount',
                    nest: () {
                      builder.attribute('currencyID', 'SAR');
                      builder.text(
                        line.taxExclusiveDiscountAppliedPrice.toStringAsFixed(
                          14,
                        ),
                      );
                    },
                  );
                  if (line.discounts.isNotEmpty) {
                    builder.element(
                      'cac:AllowanceCharge',
                      nest: () {
                        for (var discount in line.discounts) {
                          builder.element('cbc:ChargeIndicator', nest: 'false');
                          builder.element(
                            'cbc:AllowanceChargeReason',
                            nest: discount.reason,
                          );
                          builder.element(
                            'cbc:Amount',
                            nest: () {
                              builder.attribute('currencyID', 'SAR');
                              builder.text(discount.amount.toStringAsFixed(14));
                            },
                          );

                          /// Required when the discount is a percentage.
                          // builder.element(
                          //   'cbc:BaseAmount',
                          //   nest: () {
                          //     builder.attribute('currencyID', 'SAR');
                          //     builder.text(line.taxExclusivePrice.toString());
                          //   },
                          // );
                        }
                      },
                    );
                  }
                },
              );
            },
          );
        }
      },
    );

    /// Build the XML document
    final document = builder.buildDocument();

    return document;
  }

  ///     Generate a ZATCA-compliant UBLExtensions XML string for the invoice data.
  static XmlDocument generateUBLSignExtensionsXml({
    required String invoiceHash,
    required String signedPropertiesHash,
    required String digitalSignature,
    required String certificateString,
    required XmlDocument ublSignatureSignedPropertiesXML,
  }) {
    final builder = XmlBuilder();
    builder.element(
      'ext:UBLExtensions',
      nest: () {
        builder.element(
          'ext:UBLExtension',
          nest: () {
            builder.element(
              'ext:ExtensionURI',
              nest: 'urn:oasis:names:specification:ubl:dsig:enveloped:xades',
            );
            builder.element(
              'ext:ExtensionContent',
              nest: () {
                builder.element(
                  'sig:UBLDocumentSignatures',
                  nest: () {
                    builder.attribute(
                      'xmlns:sac',
                      'urn:oasis:names:specification:ubl:schema:xsd:SignatureAggregateComponents-2',
                    );
                    builder.attribute(
                      'xmlns:sbc',
                      'urn:oasis:names:specification:ubl:schema:xsd:SignatureBasicComponents-2',
                    );
                    builder.attribute(
                      'xmlns:sig',
                      'urn:oasis:names:specification:ubl:schema:xsd:CommonSignatureComponents-2',
                    );
                    builder.element(
                      'sac:SignatureInformation',
                      nest: () {
                        builder.element(
                          'cbc:ID',
                          nest: 'urn:oasis:names:specification:ubl:signature:1',
                        );
                        builder.element(
                          'sbc:ReferencedSignatureID',
                          nest:
                              'urn:oasis:names:specification:ubl:signature:Invoice',
                        );
                        builder.element(
                          'ds:Signature',
                          nest: () {
                            builder.attribute('Id', 'signature');
                            builder.attribute(
                              'xmlns:ds',
                              'http://www.w3.org/2000/09/xmldsig#',
                            );
                            builder.element(
                              'ds:SignedInfo',
                              nest: () {
                                builder.element(
                                  'ds:CanonicalizationMethod',
                                  nest: () {
                                    builder.attribute(
                                      'Algorithm',
                                      'http://www.w3.org/2006/12/xml-c14n11',
                                    );
                                    builder.text('');
                                  },
                                );
                                builder.element(
                                  'ds:SignatureMethod',
                                  nest: () {
                                    builder.attribute(
                                      'Algorithm',
                                      'http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256',
                                    );
                                    builder.text('');
                                  },
                                );
                                builder.element(
                                  'ds:Reference',
                                  nest: () {
                                    builder.attribute(
                                      'Id',
                                      'invoiceSignedData',
                                    );
                                    builder.attribute('URI', '');
                                    builder.element(
                                      'ds:Transforms',
                                      nest: () {
                                        builder.element(
                                          'ds:Transform',
                                          nest: () {
                                            builder.attribute(
                                              'Algorithm',
                                              'http://www.w3.org/TR/1999/REC-xpath-19991116',
                                            );
                                            builder.element(
                                              'ds:XPath',
                                              nest:
                                                  'not(//ancestor-or-self::ext:UBLExtensions)',
                                            );
                                          },
                                        );
                                        builder.element(
                                          'ds:Transform',
                                          nest: () {
                                            builder.attribute(
                                              'Algorithm',
                                              'http://www.w3.org/TR/1999/REC-xpath-19991116',
                                            );
                                            builder.element(
                                              'ds:XPath',
                                              nest:
                                                  'not(//ancestor-or-self::cac:Signature)',
                                            );
                                          },
                                        );
                                        builder.element(
                                          'ds:Transform',
                                          nest: () {
                                            builder.attribute(
                                              'Algorithm',
                                              'http://www.w3.org/TR/1999/REC-xpath-19991116',
                                            );
                                            builder.element(
                                              'ds:XPath',
                                              nest:
                                                  'not(//ancestor-or-self::cac:AdditionalDocumentReference[cbc:ID=\'QR\'])',
                                            );
                                          },
                                        );
                                        builder.element(
                                          'ds:Transform',
                                          nest: () {
                                            builder.attribute(
                                              'Algorithm',
                                              'http://www.w3.org/2006/12/xml-c14n11',
                                            );
                                            builder.text('');
                                          },
                                        );
                                      },
                                    );
                                    builder.element(
                                      'ds:DigestMethod',
                                      nest: () {
                                        builder.attribute(
                                          'Algorithm',
                                          'http://www.w3.org/2001/04/xmlenc#sha256',
                                        );
                                        builder.text('');
                                      },
                                    );
                                    builder.element(
                                      'ds:DigestValue',
                                      nest: invoiceHash,
                                    );
                                  },
                                );
                                builder.element(
                                  'ds:Reference',
                                  nest: () {
                                    builder.attribute(
                                      'Type',
                                      'http://www.w3.org/2000/09/xmldsig#SignatureProperties',
                                    );
                                    builder.attribute(
                                      'URI',
                                      '#xadesSignedProperties',
                                    );
                                    builder.element(
                                      'ds:DigestMethod',
                                      nest: () {
                                        builder.attribute(
                                          'Algorithm',
                                          'http://www.w3.org/2001/04/xmlenc#sha256',
                                        );
                                        builder.text('');
                                      },
                                    );
                                    builder.element(
                                      'ds:DigestValue',
                                      nest: signedPropertiesHash,
                                    );
                                  },
                                );
                              },
                            );
                            builder.element(
                              'ds:SignatureValue',
                              nest: digitalSignature,
                            );
                            builder.element(
                              'ds:KeyInfo',
                              nest: () {
                                builder.element(
                                  'ds:X509Data',
                                  nest: () {
                                    builder.element(
                                      'ds:X509Certificate',
                                      nest: certificateString,
                                    );
                                  },
                                );
                              },
                            );
                            builder.element('ds:Object-1');
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );

    return builder.buildDocument();
  }

  /// Generates the default  xades:SignedProperties XML template.
  static XmlDocument defaultUBLExtensionsSignedPropertiesForSigning({
    required String signingTime,
    required String certificateHash,
    required String certificateIssuer,
    required String certificateSerialNumber,
  }) {
    final builder = XmlBuilder();
    builder.element(
      'xades:SignedProperties',
      nest: () {
        builder.attribute('xmlns:xades', 'http://uri.etsi.org/01903/v1.3.2#');
        builder.attribute('Id', 'xadesSignedProperties');

        builder.element(
          'xades:SignedSignatureProperties',
          nest: () {
            builder.element('xades:SigningTime', nest: signingTime);

            builder.element(
              'xades:SigningCertificate',
              nest: () {
                builder.element(
                  'xades:Cert',
                  nest: () {
                    builder.element(
                      'xades:CertDigest',
                      nest: () {
                        builder.element(
                          'ds:DigestMethod',
                          nest: () {
                            builder.attribute(
                              'xmlns:ds',
                              'http://www.w3.org/2000/09/xmldsig#',
                            );
                            builder.attribute(
                              'Algorithm',
                              'http://www.w3.org/2001/04/xmlenc#sha256',
                            );
                          },
                        );
                        builder.element(
                          'ds:DigestValue',
                          nest: () {
                            builder.attribute(
                              'xmlns:ds',
                              'http://www.w3.org/2000/09/xmldsig#',
                            );
                            builder.text(certificateHash);
                          },
                        );
                      },
                    );

                    builder.element(
                      'xades:IssuerSerial',
                      nest: () {
                        builder.element(
                          'ds:X509IssuerName',
                          nest: () {
                            builder.attribute(
                              'xmlns:ds',
                              'http://www.w3.org/2000/09/xmldsig#',
                            );
                            builder.text(certificateIssuer);
                          },
                        );
                        builder.element(
                          'ds:X509SerialNumber',
                          nest: () {
                            builder.attribute(
                              'xmlns:ds',
                              'http://www.w3.org/2000/09/xmldsig#',
                            );
                            builder.text(certificateSerialNumber);
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
    return builder.buildDocument();
  }

  /// Generates the `<xades:SignedProperties>` XML structure after signed.
  static XmlDocument defaultUBLExtensionsSignedProperties({
    required String signingTime,
    required String certificateHash,
    required String certificateIssuer,
    required String certificateSerialNumber,
  }) {
    final builder = XmlBuilder();
    builder.element(
      'xades:QualifyingProperties',
      attributes: {
        'Target': 'signature',
        'xmlns:xades': 'http://uri.etsi.org/01903/v1.3.2#',
      },
      nest: () {
        builder.element(
          'xades:SignedProperties',
          nest: () {
            builder.attribute(
              'xmlns:xades',
              'http://uri.etsi.org/01903/v1.3.2#',
            );
            builder.attribute('Id', 'xadesSignedProperties');

            builder.element(
              'xades:SignedSignatureProperties',
              nest: () {
                builder.element('xades:SigningTime', nest: signingTime);

                builder.element(
                  'xades:SigningCertificate',
                  nest: () {
                    builder.element(
                      'xades:Cert',
                      nest: () {
                        builder.element(
                          'xades:CertDigest',
                          nest: () {
                            builder.element(
                              'ds:DigestMethod',
                              nest: () {
                                builder.attribute(
                                  'Algorithm',
                                  'http://www.w3.org/2001/04/xmlenc#sha256',
                                );
                                builder.text('');
                              },
                            );
                            builder.element(
                              'ds:DigestValue',
                              nest: certificateHash,
                            );
                          },
                        );

                        builder.element(
                          'xades:IssuerSerial',
                          nest: () {
                            builder.element(
                              'ds:X509IssuerName',
                              nest: certificateIssuer,
                            );
                            builder.element(
                              'ds:X509SerialNumber',
                              nest: certificateSerialNumber,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );

    return builder.buildDocument();
  }

  static XmlDocument generateQrAndSignatureXMl({required String qrString}) {
    final builder = XmlBuilder();
    builder.element(
      'cac:AdditionalDocumentReference',
      nest: () {
        builder.element('cbc:ID', nest: 'QR');
        builder.element(
          'cac:Attachment',
          nest: () {
            builder.element(
              'cbc:EmbeddedDocumentBinaryObject',
              nest: qrString,
              attributes: {'mimeCode': 'text/plain'},
            );
          },
        );
      },
    );
    builder.element(
      'cac:Signature',
      nest: () {
        builder.element(
          'cbc:ID',
          nest: 'urn:oasis:names:specification:ubl:signature:Invoice',
        );
        builder.element(
          'cbc:SignatureMethod',
          nest: "urn:oasis:names:specification:ubl:dsig:enveloped:xades",
        );
      },
    );

    return builder.buildDocument();
  }

  static String canonicalizeXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);

    // Recursively sort attributes and format the nodes
    String normalizeNode(XmlNode node) {
      if (node is XmlElement) {
        final sortedAttributes =
            node.attributes.toList()
              ..sort((a, b) => a.name.toString().compareTo(b.name.toString()));

        final buffer = StringBuffer();
        buffer.write('<${node.name}');

        for (var attr in sortedAttributes) {
          buffer.write(' ${attr.name}="${attr.value}"');
        }

        buffer.write('>');

        for (var child in node.children) {
          buffer.write(normalizeNode(child));
        }

        buffer.write('</${node.name}>');
        return buffer.toString();
      } else if (node is XmlText) {
        return node.value;
      } else if (node is XmlProcessing) {
        // Skip XML declaration
        return '';
      } else {
        return node.toXmlString();
      }
    }

    final normalizedXml = normalizeNode(document.rootElement);
    return normalizedXml;
  }

  static String generateHash(String xmlString) {
    /// Compute the SHA-256 hash
    final bytes = utf8.encode(xmlString); // Convert XML to bytes
    final hash = sha256.convert(bytes); // Compute the SHA-256 hash

    /// Encode the hash in Base64
    return base64.encode(hash.bytes);
  }
}
