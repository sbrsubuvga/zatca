library flutter_zatca;

import 'copliance_api.dart';
import 'egs.dart';
import 'templates/simplified_tax_invoices.dart';
import 'zatca_invoice.dart';




final lineItem1 = ZATCAInvoiceLineItem(
  id: "1",
  name: "TEST NAME",
  quantity: 1,
  tax_exclusive_price: 10,
  VAT_percent: 0.15,
  discounts: [],
  other_taxes: [],

);



final egsUnit = EGSUnitInfo(
  uuid: "6f4d20e0-6bfe-4a80-9389-7dabe6620f14",
  customId: "EGS2",
  model: "IOS",
  crnNumber: "454634645645654",
  vatName: "Wesam Alzahir",
  vatNumber: "399999999900003",
  branchName: "My Branch Name",
  branchIndustry: "Food",
  location: EGSUnitLocation(
    city: "Khobar",
    citySubdivision: "West",
    street: "King Fahahd st",
    plotIdentification: "0000",
    building: "0000",
    postalZone: "31952",
  ),
  customerInfo: EGSUnitCustomerInfo(
    city: "jeddah",
    citySubdivision: "ssss",
    buyerName: "S7S",
    building: "00",
    postalZone: "00000",
    street: "__",
    vatNumber: "300000000000003",
  ),
);

final invoice = SimplifiedInvoice(
  invoice_counter_number: 1,
  invoice_type: ZATCAInvoiceTypes.INVOICE,
  invoice_serial_number: "EGS1-886431145-101",
  issue_date: "2024-02-29",
  issue_time: "11:40:40",
  previous_invoice_hash: "zDnQnE05P6rFMqF1ai21V5hIRlUq/EXvrpsaoPkWRVI=",
  line_items: [lineItem1],
  actual_delivery_date: "2024-02-29",
  egs_info: egsUnit,
  payment_method: ZATCAPaymentMethods.CASH
);


class Zatca {
  ZATCAInvoice  zatcaInvoice=ZATCAInvoice(props: invoice,acceptWarning: true);


 final  egs = EGS(egsUnitInfo: egsUnit);


   generateInvoice()async{

      egs.egsUnitInfo.privateKey="""-----BEGIN EC PRIVATE KEY-----
MHQCAQEEIPY5phXaRlw94Wb0bpQCLUpFVjGbHVAqL8BX0zSlPEm2oAcGBSuBBAAK
oUQDQgAEmRGlsBbHAKpzfqBVZ3P6UZLkQZA+RhFDShJ2uibLX/0FxnWSXsZy8Kok
+ynuizQl772/pRod0QhBa5D49PDE4Q==
-----END EC PRIVATE KEY-----""";


      egs.egsUnitInfo.complianceCertificate="""-----BEGIN CERTIFICATE-----
      MIID3jCCA4SgAwIBAgITEQAAOAPF90Ajs/xcXwABAAA4AzAKBggqhkjOPQQDAjBiMRUwEwYKCZImiZPyLGQBGRYFbG9jYWwxEzARBgoJkiaJk/IsZAEZFgNnb3YxFzAVBgoJkiaJk/IsZAEZFgdleHRnYXp0MRswGQYDVQQDExJQUlpFSU5WT0lDRVNDQTQtQ0EwHhcNMjQwMTExMDkxOTMwWhcNMjkwMTA5MDkxOTMwWjB1MQswCQYDVQQGEwJTQTEmMCQGA1UEChMdTWF4aW11bSBTcGVlZCBUZWNoIFN1cHBseSBMVEQxFjAUBgNVBAsTDVJpeWFkaCBCcmFuY2gxJjAkBgNVBAMTHVRTVC04ODY0MzExNDUtMzk5OTk5OTk5OTAwMDAzMFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAEoWCKa0Sa9FIErTOv0uAkC1VIKXxU9nPpx2vlf4yhMejy8c02XJblDq7tPydo8mq0ahOMmNo8gwni7Xt1KT9UeKOCAgcwggIDMIGtBgNVHREEgaUwgaKkgZ8wgZwxOzA5BgNVBAQMMjEtVFNUfDItVFNUfDMtZWQyMmYxZDgtZTZhMi0xMTE4LTliNTgtZDlhOGYxMWU0NDVmMR8wHQYKCZImiZPyLGQBAQwPMzk5OTk5OTk5OTAwMDAzMQ0wCwYDVQQMDAQxMTAwMREwDwYDVQQaDAhSUlJEMjkyOTEaMBgGA1UEDwwRU3VwcGx5IGFjdGl2aXRpZXMwHQYDVR0OBBYEFEX+YvmmtnYoDf9BGbKo7ocTKYK1MB8GA1UdIwQYMBaAFJvKqqLtmqwskIFzVvpP2PxT+9NnMHsGCCsGAQUFBwEBBG8wbTBrBggrBgEFBQcwAoZfaHR0cDovL2FpYTQuemF0Y2EuZ292LnNhL0NlcnRFbnJvbGwvUFJaRUludm9pY2VTQ0E0LmV4dGdhenQuZ292LmxvY2FsX1BSWkVJTlZPSUNFU0NBNC1DQSgxKS5jcnQwDgYDVR0PAQH/BAQDAgeAMDwGCSsGAQQBgjcVBwQvMC0GJSsGAQQBgjcVCIGGqB2E0PsShu2dJIfO+xnTwFVmh/qlZYXZhD4CAWQCARIwHQYDVR0lBBYwFAYIKwYBBQUHAwMGCCsGAQUFBwMCMCcGCSsGAQQBgjcVCgQaMBgwCgYIKwYBBQUHAwMwCgYIKwYBBQUHAwIwCgYIKoZIzj0EAwIDSAAwRQIhALE/ichmnWXCUKUbca3yci8oqwaLvFdHVjQrveI9uqAbAiA9hC4M8jgMBADPSzmd2uiPJA6gKR3LE03U75eqbC/rXA==
      -----END CERTIFICATE-----""";
      egs.egsUnitInfo.complianceApiSecret='CkYsEXfV8c1gFHAtFWoZv73pGMvh/Qyo4LzKM2h/8Hg=';

        Map<String,dynamic> invoice=   egs.signInvoice(invoice: zatcaInvoice,production: false);
        // print("***************start1");
        // ComplianceAPI api=ComplianceAPI();
        // print("***************start2");
        // final response= await api.checkInvoiceCompliance(
        //     invoice['signed_invoice_string'],
        //     invoice['invoice_hash'],
        //     egs.egsUnitInfo.uuid,
        //     egs.egsUnitInfo.complianceCertificate!,
        //     egs.egsUnitInfo.complianceApiSecret!
        // );
        // print("***error $response *****");
       return invoice;
  }


}
