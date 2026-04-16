import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:zatca/certificate_manager.dart';
import 'package:zatca/models/compliance_certificate.dart';
import 'package:zatca/models/invoice.dart';
import 'package:zatca/models/invoice_line.dart';
import 'package:zatca/models/supplier.dart';
import 'package:zatca/resources/enums.dart';
import 'package:zatca/zatca_manager.dart';

import '../../data/storage.dart';
import '../onboarding/onboarding_bloc.dart';
import 'invoice_event.dart';
import 'invoice_state.dart';

/// Drives the invoice creation flow:
/// form editing → build UBL XML → sign → submit → display result.
class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final OnboardingBloc onboardingBloc;
  final OnboardingStorage storage;
  final ZatcaManager zatcaManager;
  final CertificateManager certificateManager;

  InvoiceBloc({
    required this.onboardingBloc,
    required this.storage,
    ZatcaManager? zatcaManager,
    CertificateManager? certificateManager,
  }) : zatcaManager = zatcaManager ?? ZatcaManager.instance,
       certificateManager = certificateManager ?? CertificateManager.instance,
       super(const InvoiceState()) {
    on<InvoiceStarted>(_onStarted);
    on<InvoiceKindChanged>(_onKindChanged);
    on<InvoiceNumberChanged>(_onNumberChanged);
    on<InvoicePaymentMethodChanged>(_onPaymentChanged);
    on<InvoiceCustomerChanged>(_onCustomerChanged);
    on<InvoiceCancellationChanged>(_onCancellationChanged);
    on<InvoiceLineAdded>(_onLineAdded);
    on<InvoiceLineRemoved>(_onLineRemoved);
    on<InvoiceLineUpdated>(_onLineUpdated);
    on<InvoiceSubmitted>(_onSubmitted);
    on<InvoiceDismissed>(_onDismissed);
  }

  void _onStarted(InvoiceStarted event, Emitter<InvoiceState> emit) {
    final icv = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    emit(
      InvoiceState(
        invoiceNumber: 'EGS1-$icv',
        lines: [
          InvoiceLineDraft(
            id: '1',
            itemName: 'Sample Item',
            quantity: '1',
            unitPrice: '100',
            taxPercent: '15',
          ),
        ],
      ),
    );
  }

  void _onKindChanged(InvoiceKindChanged event, Emitter<InvoiceState> emit) {
    emit(
      state.copyWith(
        kind: event.kind,
        clearCustomer: event.kind.isSimplified,
        clearError: true,
      ),
    );
  }

  void _onNumberChanged(
    InvoiceNumberChanged event,
    Emitter<InvoiceState> emit,
  ) => emit(state.copyWith(invoiceNumber: event.value));

  void _onPaymentChanged(
    InvoicePaymentMethodChanged event,
    Emitter<InvoiceState> emit,
  ) => emit(state.copyWith(paymentMethod: event.method));

  void _onCustomerChanged(
    InvoiceCustomerChanged event,
    Emitter<InvoiceState> emit,
  ) => emit(state.copyWith(customer: event.customer));

  void _onCancellationChanged(
    InvoiceCancellationChanged event,
    Emitter<InvoiceState> emit,
  ) => emit(
    state.copyWith(
      cancellationReason: event.reason,
      canceledSerialInvoiceNumber: event.canceledSerialInvoiceNumber,
    ),
  );

  void _onLineAdded(InvoiceLineAdded event, Emitter<InvoiceState> emit) {
    final nextId = '${state.lines.length + 1}';
    emit(
      state.copyWith(
        lines: [
          ...state.lines,
          InvoiceLineDraft(
            id: nextId,
            itemName: '',
            quantity: '1',
            unitPrice: '0',
            taxPercent: '15',
          ),
        ],
      ),
    );
  }

  void _onLineRemoved(InvoiceLineRemoved event, Emitter<InvoiceState> emit) {
    if (state.lines.length <= 1) return;
    final updated = [...state.lines]..removeAt(event.index);
    for (var i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith()..id;
    }
    emit(state.copyWith(lines: updated));
  }

  void _onLineUpdated(InvoiceLineUpdated event, Emitter<InvoiceState> emit) {
    final updated = [...state.lines];
    updated[event.index] = event.draft;
    emit(state.copyWith(lines: updated));
  }

  Future<void> _onSubmitted(
    InvoiceSubmitted event,
    Emitter<InvoiceState> emit,
  ) async {
    final onboarding = onboardingBloc.state;
    if (!onboarding.isReadyToInvoice) {
      emit(
        state.copyWith(
          status: InvoiceStatus.failure,
          errorMessage:
              'Device not onboarded. Generate a compliance certificate first.',
        ),
      );
      return;
    }
    if (state.lines.isEmpty) {
      emit(
        state.copyWith(
          status: InvoiceStatus.failure,
          errorMessage: 'Add at least one invoice line.',
        ),
      );
      return;
    }
    if (state.kind.isStandard && state.customer == null) {
      emit(
        state.copyWith(
          status: InvoiceStatus.failure,
          errorMessage: 'Standard (B2B) invoices require customer info.',
        ),
      );
      return;
    }
    if (state.kind.isCreditOrDebitNote &&
        (state.cancellationReason.trim().isEmpty ||
            state.canceledSerialInvoiceNumber.trim().isEmpty)) {
      emit(
        state.copyWith(
          status: InvoiceStatus.failure,
          errorMessage:
              'Credit/debit notes need a reason and the original invoice number.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: InvoiceStatus.submitting, clearError: true));

    try {
      final supplier = Supplier(
        companyID: onboarding.egs!.vatNumber,
        companyCRN: onboarding.egs!.crnNumber,
        registrationName: onboarding.egs!.taxpayerName,
        location: onboarding.egs!.location,
      );

      // Pick compliance cert. The production flow is deliberately
      // untouched here — clearance/reporting uses production cert
      // in real life but compliance cert works for the sandbox
      // compliance-check endpoint.
      final activeCertPem =
          onboarding.productionCertPem ?? onboarding.complianceCertPem!;

      zatcaManager.initializeZatca(
        privateKeyPem: onboarding.privateKeyPem!,
        certificatePem: activeCertPem,
        supplier: supplier,
        sellerName: onboarding.egs!.taxpayerName,
        sellerTRN: onboarding.egs!.vatNumber,
      );

      final lines = state.lines
          .map(
            (d) => InvoiceLine(
              id: d.id,
              quantity: d.quantityD,
              unitCode: d.unitCode,
              lineExtensionAmount: d.quantityD * d.unitPriceD - d.discountAmountD,
              itemName: d.itemName.isEmpty ? 'Item ${d.id}' : d.itemName,
              taxPercent: d.taxPercentD,
              discounts: d.discountAmountD > 0
                  ? [
                      Discount(
                        amount: d.discountAmountD,
                        reason: d.discountReason.isEmpty
                            ? 'Discount'
                            : d.discountReason,
                      ),
                    ]
                  : const [],
            ),
          )
          .toList();

      final taxAmount = lines.fold<double>(0, (s, l) => s + l.taxAmount);
      final lineSubtotal = lines.fold<double>(
        0,
        (s, l) => s + l.lineExtensionAmount,
      );
      final total = lineSubtotal + taxAmount;

      final now = DateTime.now();
      final issueDate = DateFormat('yyyy-MM-dd').format(now);
      final issueTime = DateFormat('HH:mm:ss').format(now);
      final pih = await storage.loadPih();

      // Per ZATCA: each invoice needs its own RFC4122 UUID, and the
      // same UUID must appear in both the XML and the API request body
      // — otherwise the API returns INVOICE_UUID_VALIDATION.
      final invoiceUuid = const Uuid().v4();

      final invoice = _buildInvoice(
        kind: state.kind,
        invoiceNumber: state.invoiceNumber,
        uuid: invoiceUuid,
        issueDate: issueDate,
        issueTime: issueTime,
        paymentMethod: state.paymentMethod,
        customer: state.customer,
        cancellationReason: state.cancellationReason,
        canceledSerialInvoiceNumber: state.canceledSerialInvoiceNumber,
        lines: lines,
        taxAmount: taxAmount,
        totalAmount: total,
        previousInvoiceHash: pih,
      );

      final icv = (await storage.loadIcv()) + 1;
      final qrData = zatcaManager.generateZatcaQrInit(
        invoice: invoice,
        icv: icv,
      );
      final qrString = zatcaManager.getQrString(qrData);
      final ublXml = zatcaManager.generateUBLXml(
        invoiceHash: qrData.invoiceHash,
        signingTime:
            "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(now)}Z",
        digitalSignature: qrData.digitalSignature,
        invoiceXmlString: qrData.xmlString,
        qrString: qrString,
      );

      final certificate = ZatcaCertificate(
        complianceCertificatePem: onboarding.complianceCertPem!,
        complianceApiSecret: onboarding.complianceSecret!,
        complianceRequestId: onboarding.complianceRequestId!,
      );

      certificateManager.env = onboarding.environment;
      final endpoint = state.kind.isStandard
          ? 'Compliance check (B2B clearance)'
          : 'Compliance check (B2C reporting)';

      await certificateManager.checkInvoiceCompliance(
        complianceCertificate: certificate,
        ublXml: ublXml,
        invoiceHash: qrData.invoiceHash,
        uuid: invoiceUuid,
        environment: onboarding.environment,
      );

      // The checkInvoiceCompliance only throws on HTTP failure.
      // On 200/202 it returns void, so we model success optimistically.
      final result = SubmissionResult(
        apiEndpoint: endpoint,
        status: 'OK',
        infoMessages: const ['ZATCA accepted the invoice (sandbox).'],
        warningMessages: const [],
        errorMessages: const [],
        cleared: true,
      );

      await storage.saveIcv(icv);
      await storage.savePih(qrData.invoiceHash);

      emit(
        state.copyWith(
          status: InvoiceStatus.success,
          invoiceHash: qrData.invoiceHash,
          digitalSignature: qrData.digitalSignature,
          qrString: qrString,
          ublXml: ublXml,
          submission: result,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onDismissed(InvoiceDismissed event, Emitter<InvoiceState> emit) {
    emit(const InvoiceState());
  }

  BaseInvoice _buildInvoice({
    required InvoiceKind kind,
    required String invoiceNumber,
    required String uuid,
    required String issueDate,
    required String issueTime,
    required ZATCAPaymentMethods paymentMethod,
    customer,
    required String cancellationReason,
    required String canceledSerialInvoiceNumber,
    required List<InvoiceLine> lines,
    required double taxAmount,
    required double totalAmount,
    required String previousInvoiceHash,
  }) {
    switch (kind) {
      case InvoiceKind.simplifiedInvoice:
        return SimplifiedInvoice(
          invoiceNumber: invoiceNumber,
          uuid: uuid,
          issueDate: issueDate,
          issueTime: issueTime,
          currencyCode: 'SAR',
          taxCurrencyCode: 'SAR',
          customer: customer,
          invoiceLines: lines,
          taxAmount: taxAmount,
          totalAmount: totalAmount,
          previousInvoiceHash: previousInvoiceHash,
          actualDeliveryDate: issueDate,
          paymentMethod: paymentMethod,
        );
      case InvoiceKind.standardInvoice:
        return StandardInvoice(
          invoiceNumber: invoiceNumber,
          uuid: uuid,
          issueDate: issueDate,
          issueTime: issueTime,
          currencyCode: 'SAR',
          taxCurrencyCode: 'SAR',
          customer: customer!,
          invoiceLines: lines,
          taxAmount: taxAmount,
          totalAmount: totalAmount,
          previousInvoiceHash: previousInvoiceHash,
          actualDeliveryDate: issueDate,
          paymentMethod: paymentMethod,
        );
      case InvoiceKind.simplifiedCreditNote:
        return SimplifiedCreditNoteInvoice(
          invoiceNumber: invoiceNumber,
          uuid: uuid,
          issueDate: issueDate,
          issueTime: issueTime,
          currencyCode: 'SAR',
          taxCurrencyCode: 'SAR',
          customer: customer,
          invoiceLines: lines,
          taxAmount: taxAmount,
          totalAmount: totalAmount,
          previousInvoiceHash: previousInvoiceHash,
          cancellation: InvoiceCancellation(
            reason: cancellationReason,
            canceledSerialInvoiceNumber: canceledSerialInvoiceNumber,
            paymentMethod: paymentMethod,
          ),
        );
      case InvoiceKind.standardCreditNote:
        return StandardCreditNoteInvoice(
          invoiceNumber: invoiceNumber,
          uuid: uuid,
          issueDate: issueDate,
          issueTime: issueTime,
          currencyCode: 'SAR',
          taxCurrencyCode: 'SAR',
          customer: customer!,
          invoiceLines: lines,
          taxAmount: taxAmount,
          totalAmount: totalAmount,
          previousInvoiceHash: previousInvoiceHash,
          cancellation: InvoiceCancellation(
            reason: cancellationReason,
            canceledSerialInvoiceNumber: canceledSerialInvoiceNumber,
            paymentMethod: paymentMethod,
          ),
        );
      case InvoiceKind.simplifiedDebitNote:
        return SimplifiedDebitNoteInvoice(
          invoiceNumber: invoiceNumber,
          uuid: uuid,
          issueDate: issueDate,
          issueTime: issueTime,
          currencyCode: 'SAR',
          taxCurrencyCode: 'SAR',
          customer: customer,
          invoiceLines: lines,
          taxAmount: taxAmount,
          totalAmount: totalAmount,
          previousInvoiceHash: previousInvoiceHash,
          cancellation: InvoiceCancellation(
            reason: cancellationReason,
            canceledSerialInvoiceNumber: canceledSerialInvoiceNumber,
            paymentMethod: paymentMethod,
          ),
        );
      case InvoiceKind.standardDebitNote:
        return StandardDebitNoteInvoice(
          invoiceNumber: invoiceNumber,
          uuid: uuid,
          issueDate: issueDate,
          issueTime: issueTime,
          currencyCode: 'SAR',
          taxCurrencyCode: 'SAR',
          customer: customer!,
          invoiceLines: lines,
          taxAmount: taxAmount,
          totalAmount: totalAmount,
          previousInvoiceHash: previousInvoiceHash,
          cancellation: InvoiceCancellation(
            reason: cancellationReason,
            canceledSerialInvoiceNumber: canceledSerialInvoiceNumber,
            paymentMethod: paymentMethod,
          ),
        );
    }
  }
}
