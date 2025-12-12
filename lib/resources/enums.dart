/// This file contains all the enums used in the app
enum InvoiceType {
  /// Standard Invoices and Simplified Invoices
  standardInvoice("Standard Invoice", "388", InvoiceRelationType.b2b),
  standardCreditNote("Standard Credit Note", "381", InvoiceRelationType.b2b),
  standardDebitNote("Standard Debit Note", "383", InvoiceRelationType.b2b),
  simplifiedInvoice("Simplified Invoice", "388", InvoiceRelationType.b2c),
  simplifiedCreditNote(
    "Simplified Credit Note",
    "381",
    InvoiceRelationType.b2c,
  ),
  simplifiedDebitNote("Simplified Debit Note", "383", InvoiceRelationType.b2c);

  /// enum string value.
  final String name;
  final String code;
  final InvoiceRelationType invoiceRelationType;

  /// Constructor for [InvoiceType] enum.
  const InvoiceType(this.name, this.code, this.invoiceRelationType);
}

/// This enum represents the type of invoice relation.
enum InvoiceRelationType {
  b2b('0100000'),
  b2c('0200000');

  final String value;
  const InvoiceRelationType(this.value);
}

/// This enum represents the type of environment.
enum ZatcaEnvironment {
  sandbox("sandbox"),
  simulation("simulation"),
  production("production");

  final String value;
  const ZatcaEnvironment(this.value);
}

/// This enum represents the ZATCA payment methods.
enum ZATCAPaymentMethods {
  cash("10"),
  credit("30"),
  bankAccount("42"),
  bankCard("48");

  final String value;
  const ZATCAPaymentMethods(this.value);
}
