import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:zatca/models/address.dart';
import 'package:zatca/models/compliance_certificate.dart';
import 'package:zatca/models/customer.dart';
import 'package:zatca/models/egs_unit.dart';
import 'package:zatca/models/invoice.dart';
import 'package:zatca/models/invoice_line.dart';
import 'package:zatca/models/supplier.dart';
import 'package:zatca/certificate_manager.dart';
import 'package:zatca/resources/enums.dart';

import 'package:zatca/zatca_manager.dart';

void main() {
  late EGSUnitInfo egsUnitInfo;
  late String privateKeyPem;
  late ZatcaCertificate complianceCertificate;
  test('Certificate generate', () async {
    egsUnitInfo = EGSUnitInfo(
      uuid: "6f4d20e0-6bfe-4a80-9389-7dabe6620f14",
      taxpayerProvidedId: 'EGS2',
      model: 'IOS',
      crnNumber: '454634645645654',
      taxpayerName: "Wesam Alzahir",
      vatNumber: '399999999900003',
      branchName: 'My Branch Name',
      branchIndustry: 'Food',
      location: Location(
        city: "Khobar",
        citySubdivision: "West",
        street: "King Fahahd st",
        plotIdentification: "0000",
        building: "0000",
        postalZone: "31952",
      ),
    );

    final certificateManager = CertificateManager.instance;
    certificateManager.env = ZatcaEnvironment.sandbox;

    final keyPair = certificateManager.generateKeyPair();
    privateKeyPem = keyPair['privateKeyPem'];
    final csrPop = egsUnitInfo.toCsrProps("solution_name");
    final path = Platform.environment['TEMP_FOLDER'] ?? "/tmp/";
    final csr = await certificateManager.generateCSR(
      privateKeyPem,
      csrPop,
      path,
    );

    complianceCertificate = await certificateManager.issueComplianceCertificate(
      csr,
      '123345',
    );
    // final productionCertificate = await certificateManager
    //     .issueProductionCertificate(complianceCertificate);
  });
  test('Initialize zatca', () async {
    final zatcaManager = ZatcaManager.instance;
    zatcaManager.initializeZacta(
      sellerName: egsUnitInfo.taxpayerName,
      sellerTRN: egsUnitInfo.vatNumber,
      supplier: Supplier(
        companyID: egsUnitInfo.vatNumber,
        companyCRN: egsUnitInfo.crnNumber,
        registrationName: egsUnitInfo.taxpayerName,
        location: egsUnitInfo.location,
      ),
      privateKeyPem: privateKeyPem,
      certificatePem: complianceCertificate.complianceCertificatePem,
    );
  });

  test('Sign Simplified Invoice', () async {
    final zatcaManager = ZatcaManager.instance;
    final invoiceDate = DateTime.now().subtract(Duration(hours: 5));
    final invoice = SimplifiedInvoice(
      invoiceNumber: "EGS1-886431145-101",
      uuid: egsUnitInfo.uuid,
      issueDate: DateFormat('yyyy-MM-dd').format(invoiceDate),
      issueTime: DateFormat('HH:mm:ss').format(invoiceDate),
      actualDeliveryDate: DateFormat('yyyy-MM-dd').format(invoiceDate),
      currencyCode: 'SAR',
      taxCurrencyCode: 'SAR',
      customer: Customer(
        companyID: '300000000000003',
        registrationName: 'S7S',
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
          discounts: [Discount(amount: 2, reason: 'discount')],
        ),
      ],
      taxAmount: 1.50,
      totalAmount: 11.50,
      previousInvoiceHash: "zDnQnE05P6rFMqF1ai21V5hIRlUq/EXvrpsaoPkWRVI=",
    );

    final qrData = zatcaManager.generateZatcaQrInit(invoice: invoice, icv: 1);

    String invoiceHash = qrData.invoiceHash;
    String invoiceXmlString = qrData.xmlString;
    String qr = zatcaManager.getQrString(qrData);

    String ublXML = zatcaManager.generateUBLXml(
      invoiceHash: invoiceHash,
      signingTime:
          "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now())}Z",
      digitalSignature: qrData.digitalSignature,
      invoiceXmlString: invoiceXmlString,
      qrString: qr,
    );

    // print("XML: $ublXML");

    final certificateManager = CertificateManager.instance;
    await certificateManager.checkInvoiceCompliance(
      complianceCertificate: complianceCertificate,
      invoiceHash: invoiceHash,
      ublXml: ublXML,
      uuid: egsUnitInfo.uuid,
    );
  });

  test('Sign Simplified Credit Note', () async {
    final zatcaManager = ZatcaManager.instance;
    final invoiceDate = DateTime.now().subtract(Duration(hours: 5));
    final invoice = SimplifiedCreditNoteInvoice(
      invoiceNumber: "EGS1-886431145-102",
      uuid: egsUnitInfo.uuid,
      issueDate: DateFormat('yyyy-MM-dd').format(invoiceDate),
      issueTime: DateFormat('HH:mm:ss').format(invoiceDate),
      currencyCode: 'SAR',
      taxCurrencyCode: 'SAR',
      customer: Customer(
        companyID: '300000000000003',
        registrationName: 'S7S',
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
          quantity: 1,
          unitCode: 'PCE',
          lineExtensionAmount: 10,
          itemName: 'TEST NAME',
          taxPercent: 15,
          discounts: [Discount(amount: 2, reason: "Return Discount")],
        ),
      ],
      taxAmount: 1.50,
      totalAmount: 11.50,
      previousInvoiceHash: "zDnQnE05P6rFMqF1ai21V5hIRlUq/EXvrpsaoPkWRVI=",
      cancellation: InvoiceCancellation(
        reason: "Customer requested cancellation",
        canceledSerialInvoiceNumber: 'EGS1-886431145-101',
        paymentMethod: ZATCAPaymentMethods.cash,
      ),
    );

    final qrData = zatcaManager.generateZatcaQrInit(invoice: invoice, icv: 1);

    String invoiceHash = qrData.invoiceHash;
    String invoiceXmlString = qrData.xmlString;
    String qr = zatcaManager.getQrString(qrData);

    // print("qr: $qr");
    String ublXML = zatcaManager.generateUBLXml(
      invoiceHash: invoiceHash,
      signingTime:
          "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now())}Z",
      digitalSignature: qrData.digitalSignature,
      invoiceXmlString: invoiceXmlString,
      qrString: qr,
    );
    final certificateManager = CertificateManager.instance;
    await certificateManager.checkInvoiceCompliance(
      complianceCertificate: complianceCertificate,
      invoiceHash: invoiceHash,
      ublXml: ublXML,
      uuid: egsUnitInfo.uuid,
    );
    // print("XML: $ublXML");
  });

  test('Sign Standard Invoice', () async {
    final zatcaManager = ZatcaManager.instance;
    final invoiceDate = DateTime.now().subtract(Duration(hours: 5));
    final invoice = StandardInvoice(
      invoiceNumber: "EGS1-886431145-104",
      uuid: egsUnitInfo.uuid,
      issueDate: DateFormat('yyyy-MM-dd').format(invoiceDate),
      issueTime: DateFormat('HH:mm:ss').format(invoiceDate),
      actualDeliveryDate: DateFormat('yyyy-MM-dd').format(invoiceDate),
      currencyCode: 'SAR',
      taxCurrencyCode: 'SAR',
      customer: Customer(
        companyID: '300000000000003',
        registrationName: 'S7S',
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
          quantity: 1,
          unitCode: 'PCE',
          lineExtensionAmount: 10,
          itemName: 'TEST NAME',
          taxPercent: 15,
        ),
      ],
      taxAmount: 1.50,
      totalAmount: 11.50,
      previousInvoiceHash: "zDnQnE05P6rFMqF1ai21V5hIRlUq/EXvrpsaoPkWRVI=",
    );

    final qrData = zatcaManager.generateZatcaQrInit(invoice: invoice, icv: 1);

    String invoiceHash = qrData.invoiceHash;
    String invoiceXmlString = qrData.xmlString;
    String qr = zatcaManager.getQrString(qrData);
    String ublXML = zatcaManager.generateUBLXml(
      invoiceHash: invoiceHash,
      signingTime:
          "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now())}Z",
      digitalSignature: qrData.digitalSignature,
      invoiceXmlString: invoiceXmlString,
      qrString: qr,
    );
    final certificateManager = CertificateManager.instance;
    await certificateManager.checkInvoiceCompliance(
      complianceCertificate: complianceCertificate,
      invoiceHash: invoiceHash,
      ublXml: ublXML,
      uuid: egsUnitInfo.uuid,
    );
  });

  test('Sign Standard Credit Note', () async {
    final zatcaManager = ZatcaManager.instance;
    final invoiceDate = DateTime.now().subtract(Duration(hours: 5));
    final invoice = StandardCreditNoteInvoice(
      invoiceNumber: "EGS1-886431145-105",
      uuid: egsUnitInfo.uuid,
      issueDate: DateFormat('yyyy-MM-dd').format(invoiceDate),
      issueTime: DateFormat('HH:mm:ss').format(invoiceDate),
      currencyCode: 'SAR',
      taxCurrencyCode: 'SAR',
      customer: Customer(
        companyID: '300000000000003',
        registrationName: 'S7S',
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
          quantity: 1,
          unitCode: 'PCE',
          lineExtensionAmount: 10,
          itemName: 'TEST NAME',
          taxPercent: 15,
        ),
      ],
      taxAmount: 1.50,
      totalAmount: 11.50,
      previousInvoiceHash: "zDnQnE05P6rFMqF1ai21V5hIRlUq/EXvrpsaoPkWRVI=",
      cancellation: InvoiceCancellation(
        reason: "Customer requested cancellation",
        canceledSerialInvoiceNumber: 'EGS1-886431145-104',
        paymentMethod: ZATCAPaymentMethods.cash,
      ),
    );

    final qrData = zatcaManager.generateZatcaQrInit(invoice: invoice, icv: 1);

    String invoiceHash = qrData.invoiceHash;
    String invoiceXmlString = qrData.xmlString;
    String qr = zatcaManager.getQrString(qrData);
    String ublXML = zatcaManager.generateUBLXml(
      invoiceHash: invoiceHash,
      signingTime:
          "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now())}Z",
      digitalSignature: qrData.digitalSignature,
      invoiceXmlString: invoiceXmlString,
      qrString: qr,
    );
    final certificateManager = CertificateManager.instance;
    await certificateManager.checkInvoiceCompliance(
      complianceCertificate: complianceCertificate,
      invoiceHash: invoiceHash,
      ublXml: ublXML,
      uuid: egsUnitInfo.uuid,
    );
  });
}
