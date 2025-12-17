import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zatca/models/address.dart';
import 'package:zatca/models/customer.dart';
import 'package:zatca/models/egs_unit.dart';
import 'package:zatca/models/invoice.dart';
import 'package:zatca/models/invoice_line.dart';
import 'package:zatca/models/qr_data.dart';
import 'package:zatca/models/supplier.dart';
import 'package:zatca/certificate_manager.dart';
import 'package:zatca/resources/enums.dart';
import 'package:zatca/zatca_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final egsUnitInfo = EGSUnitInfo(
    uuid: "6f4d20e0-6bfe-4a80-9389-7dabe6620f14",
    taxpayerProvidedId: 'EGS2',
    model: 'IOS',
    crnNumber: '454634645645654',
    taxpayerName: "My Branch",
    vatNumber: '310175397400003',
    branchName: 'My Branch',
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
  String privateKeyPem = '';
  String complianceCertificatePem = '';
  // late String productionCertificate;
  ZatcaQr? qrData;
  String qr = '';
  String ublXML = '';
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 40),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "EGS Unit Info",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                'UUID: ${egsUnitInfo.uuid}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Model: ${egsUnitInfo.model}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'CRN Number: ${egsUnitInfo.crnNumber}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Taxpayer Name: ${egsUnitInfo.taxpayerName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'VAT Number: ${egsUnitInfo.vatNumber}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Branch Name: ${egsUnitInfo.branchName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Branch Industry: ${egsUnitInfo.branchIndustry}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Location: ${egsUnitInfo.location.city}, ${egsUnitInfo.location.street}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  generateCertificate();
                },
                child: const Text("Generate Certificate"),
              ),

              const SizedBox(height: 10),
              if (privateKeyPem.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 5),
                        Text(
                          'Private Key Generated',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 5),
                        Text(
                          'Compliance Certificate Generated',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  initZATCAAndGenerateQr();
                },
                child: const Text("init ZATCA And GenerateQr"),
              ),

              const SizedBox(height: 10),
              if (qrData != null && qr.isNotEmpty)
                Column(
                  children: [
                    QrImageView(
                      data: qr,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ],
                ),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  generateReportingXml();
                },
                child: const Text("Generate Reporting XML"),
              ),

              const SizedBox(height: 10),
              if (ublXML.isNotEmpty)
                Column(
                  children: [
                    Text(
                      'UBL XML:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SelectableText(
                      ublXML,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  generateCertificate() async {
    /// Initialize the EGSUnitInfo object with the required details.
    /// This object contains information about the EGS unit, such as its UUID, model, CRN number, taxpayer name, VAT number, branch name, industry, and location.

    /// Declare variables for private key and compliance certificate PEM strings.
    /// These will be used to store the generated private key and compliance certificate in PEM format.
    /// In a real-world scenario, these should be securely stored and managed.
    /// The private key is used for signing the compliance certificate, and the compliance certificate is used for generating the production certificate.

    bool isDeskTop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    if (isDeskTop) {
      /// Initialize the CertificateManager singleton instance.
      final certificateManager = CertificateManager.instance;
      certificateManager.env = ZatcaEnvironment.sandbox;

      /// Generate a key pair for the EGS unit.
      final keyPair = certificateManager.generateKeyPair();

      setState(() {
        privateKeyPem = keyPair['privateKeyPem'];
      });

      /// Generate a CSR (Certificate Signing Request) using the EGS unit info and private key.
      ///
      final appDocDir = await getApplicationDocumentsDirectory();
      final csrPop = egsUnitInfo.toCsrProps("solution_name");
      final csr = await certificateManager.generateCSR(
        privateKeyPem,
        csrPop,
        appDocDir.path,
      );

      /// Issue a compliance certificate using the CSR.
      final complianceCertificate = await certificateManager
          .issueComplianceCertificate(csr, '123345');

      setState(() {
        complianceCertificatePem =
            complianceCertificate.complianceCertificatePem;
      });

      /// Issue a production certificate using the compliance certificate.
      // final productionCertificate = await certificateManager
      //     .issueProductionCertificate(complianceCertificate);
    } else {
      /// For non-desktop platforms, use hardcoded PEM strings for private key and compliance certificate.
      /// These should be replaced with actual PEM content.
      /// In a real-world scenario, you would fetch these securely from a server or a key management system.
      privateKeyPem =
          """-----BEGIN EC PRIVATE KEY-----\nprivate_key_pem_content\n-----END EC PRIVATE KEY-----""";
      complianceCertificatePem =
          """-----BEGIN CERTIFICATE-----\ncertificate_pem_content\n-----END CERTIFICATE-----""";
    }
  }

  initZATCAAndGenerateQr() {
    assert(
      privateKeyPem.isNotEmpty,
      "Private key PEM must not be empty, please generate the certificate first",
    );

    /// Ensure that the compliance certificate PEM is not empty before proceeding.
    /// This is crucial as the compliance certificate is required for generating the ZATCA QR code.
    /// If it is empty, an assertion error will be thrown to indicate that the compliance certificate must be generated first.
    assert(
      complianceCertificatePem.isNotEmpty,
      "Compliance certificate PEM must not be empty, please generate the certificate first",
    );

    /// Initialize the ZatcaManager singleton instance with seller and supplier details.
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
      certificatePem: complianceCertificatePem,
    );

    final invoice = SimplifiedInvoice(
      invoiceNumber: "EGS1-886431145-101",
      uuid: egsUnitInfo.uuid,
      issueDate: "2024-02-29",
      issueTime: "11:40:40",
      actualDeliveryDate: "2024-02-29",
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
          discounts: [Discount(amount: 2, reason: 'discount')],
        ),
      ],
      taxAmount: 1.50,
      totalAmount: 11.50,
      previousInvoiceHash: "zDnQnE05P6rFMqF1ai21V5hIRlUq/EXvrpsaoPkWRVI=",
    );

    setState(() {
      /// Generate QR data for the invoice using the ZatcaManager.
      qrData = zatcaManager.generateZatcaQrInit(invoice: invoice, icv: 1);
      qr = zatcaManager.getQrString(qrData!);
    });
  }

  generateReportingXml() {
    assert(
      qrData != null,
      "QR data must not be null, please generate the QR code first",
    );

    /// Ensure that the ZatcaManager instance is initialized before generating the reporting XML.

    final zatcaManager = ZatcaManager.instance;

    /// Extract additional details like invoice hash and digital signature.
    String invoiceHash = qrData!.invoiceHash;
    String invoiceXmlString = qrData!.xmlString;

    setState(() {
      /// Generate UBL XML using the extracted details.
      ublXML = zatcaManager.generateUBLXml(
        invoiceHash: invoiceHash,
        signingTime:
            "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now())}Z",
        digitalSignature: qrData!.digitalSignature,
        invoiceXmlString: invoiceXmlString,
        qrString: qr,
      );
    });
  }
}
