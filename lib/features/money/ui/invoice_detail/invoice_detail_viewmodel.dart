import 'package:cuboid_flutter_template/app/app.bottomsheets.dart';
import 'package:cuboid_flutter_template/app/app.dialogs.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/business_profile_repository.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/payment_form/payment_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:cuboid_flutter_template/ui/pdf/fleet_pdf.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum InvoiceDetailBusy { recordPayment, voidInvoice }

class InvoiceDetailViewModel extends BaseViewModel {
  InvoiceDetailViewModel(
    this.invoice, {
    MoneyRepository? repository,
    BusinessProfileRepository? businessProfileRepository,
    WorkRepository? workRepository,
  }) : _repository = repository ?? locator<MoneyRepository>(),
       _businessProfileRepository =
           businessProfileRepository ?? locator<BusinessProfileRepository>(),
       _workRepository = workRepository ?? locator<WorkRepository>();

  final Invoice invoice;
  final _bottomSheets = locator<BottomSheetService>();
  final _dialogs = locator<DialogService>();
  final _navigation = locator<NavigationService>();
  final MoneyRepository _repository;
  final BusinessProfileRepository _businessProfileRepository;
  final WorkRepository _workRepository;
  final _snackbar = locator<SnackbarService>();
  BusinessProfile? businessProfile;
  num balance = 0;

  List<WorkOrder> linkedWorkOrders = const [];
  List<Payment> linkedPayments = const [];

  Future<void> init() async {
    setBusy(true);
    switch (await _repository.fetchBalances()) {
      case Success(:final value):
        balance = value.invoices[invoice.id] ?? 0;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _businessProfileRepository.fetchBusinessProfile()) {
      case Success(:final value):
        businessProfile = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    // Load linked work orders
    switch (await _workRepository.fetchAll()) {
      case Success(:final value):
        linkedWorkOrders = value
            .where(
              (w) =>
                  invoice.linkedWorkOrderIds.contains(w.id) ||
                  w.invoiceId == invoice.id,
            )
            .toList();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    // Load linked payments
    switch (await _repository.fetchPayments()) {
      case Success(:final value):
        linkedPayments = value
            .where(
              (p) =>
                  p.allocations.any((alloc) => alloc.invoiceId == invoice.id),
            )
            .toList();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    setBusy(false);
  }

  void openPdf() {
    if (businessProfile == null) return;
    _navigation.navigateTo(
      Routes.pdfPreviewView,
      arguments: PdfPreviewViewArguments(
        title: '${invoice.number}.pdf',
        build: () => buildInvoicePdf(invoice, businessProfile!),
      ),
    );
  }

  void viewWorkOrder(WorkOrder work) {
    _navigation.navigateTo(
      Routes.workDetailView,
      arguments: WorkDetailViewArguments(work: work),
    );
  }

  Future<void> recordPayment() async {
    if (busy(InvoiceDetailBusy.recordPayment)) return;
    final response = await _bottomSheets
        .showCustomSheet<Payment, PaymentFormData>(
          variant: BottomSheetType.paymentForm,
          data: PaymentFormData(
            direction: PaymentDirection.incoming,
            partyId: invoice.buyerId,
            invoiceId: invoice.id,
          ),
          isScrollControlled: true,
        );
    final payment = response?.data;
    if (payment == null) return;
    switch (await runBusyFuture(
      _repository.recordPayment(payment),
      busyObject: InvoiceDetailBusy.recordPayment,
    )) {
      case Success():
        await init();
        invoice.status = balance <= 0
            ? InvoiceStatus.paid
            : InvoiceStatus.partPaid;
        notifyListeners();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
  }

  Future<void> voidInvoice() async {
    if (busy(InvoiceDetailBusy.voidInvoice)) return;
    final response = await _dialogs.showCustomDialog(
      variant: DialogType.confirm,
      title: 'Void invoice?',
      description: 'This reserves the invoice number and cannot be undone.',
      mainButtonTitle: 'Void invoice',
      secondaryButtonTitle: 'Keep invoice',
    );
    if (response?.confirmed != true) return;
    switch (await runBusyFuture(
      _repository.voidInvoice(invoice.id),
      busyObject: InvoiceDetailBusy.voidInvoice,
    )) {
      case Success():
        invoice.status = InvoiceStatus.voided;
        notifyListeners();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
  }
}
