import 'dart:async';

import 'package:cuboid_flutter_template/app/app.dialogs.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/money/ui/invoice_detail/invoice_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/features/more/data/business_profile_repository.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockBusinessProfileRepository extends Mock
    implements BusinessProfileRepository {}

class MockWorkRepository extends Mock implements WorkRepository {}

void main() {
  late MockMoneyRepository moneyRepository;
  late MockBusinessProfileRepository businessProfileRepository;
  late MockWorkRepository workRepository;
  late MockSnackbarService snackbarService;
  late MockBottomSheetService bottomSheetService;
  late MockDialogService dialogService;
  late MockNavigationService navigationService;

  setUp(() {
    moneyRepository = MockMoneyRepository();
    businessProfileRepository = MockBusinessProfileRepository();
    workRepository = MockWorkRepository();
    snackbarService = MockSnackbarService();
    bottomSheetService = MockBottomSheetService();
    dialogService = MockDialogService();
    navigationService = MockNavigationService();

    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<BottomSheetService>(bottomSheetService);
    replaceTestRegistration<DialogService>(dialogService);
    replaceTestRegistration<NavigationService>(navigationService);
  });

  tearDown(() {
    locator.reset();
  });

  test('init loads matching work orders and payments', () async {
    final invoice = Invoice(
      id: 'i268',
      number: 'INV-2026-003268',
      buyerId: 'c1',
      buyerName: 'Gulf Star',
      issueDate: DateTime.now(),
      dueDate: DateTime.now(),
      lines: const [],
      linkedWorkOrderIds: ['work-1'],
    );

    final workOrder = WorkOrder(
      id: 'work-1',
      number: 'WO-1039',
      customerId: 'c1',
      agreementId: 'a12',
      date: DateTime.now(),
      pickup: 'Monthly hire',
      destination: 'Sunday work',
      invoiceId: 'i268',
    );

    final payment = Payment(
      id: 'p1',
      direction: PaymentDirection.incoming,
      partyId: 'c1',
      date: DateTime.now(),
      amount: 5000.00,
      method: PaymentMethod.cheque,
      allocations: [
        const PaymentAllocation(amount: 5000.00, invoiceId: 'i268'),
      ],
    );

    when(() => moneyRepository.fetchBalances()).thenAnswer(
      (_) async => Success(
        MoneyBalances(
          invoices: {'i268': 0},
          settlements: const {},
          parties: const {},
        ),
      ),
    );
    when(() => businessProfileRepository.fetchBusinessProfile()).thenAnswer(
      (_) async => const Success(
        BusinessProfile(legalName: 'Test', address: 'Test', trn: '123'),
      ),
    );
    when(
      () => workRepository.fetchAll(),
    ).thenAnswer((_) async => Success([workOrder]));
    when(
      () => moneyRepository.fetchPayments(),
    ).thenAnswer((_) async => Success([payment]));

    final model = InvoiceDetailViewModel(
      invoice,
      repository: moneyRepository,
      businessProfileRepository: businessProfileRepository,
      workRepository: workRepository,
    );

    await model.init();

    expect(model.balance, 0);
    expect(model.linkedWorkOrders, hasLength(1));
    expect(model.linkedWorkOrders.first.id, 'work-1');
    expect(model.linkedPayments, hasLength(1));
    expect(model.linkedPayments.first.id, 'p1');
  });

  test(
    'voidInvoice ignores a second call while the first is pending',
    () async {
      final invoice = Invoice(
        id: 'invoice',
        number: 'INV-1',
        buyerId: 'customer',
        buyerName: 'Customer',
        issueDate: DateTime(2026, 7),
      );
      final pending = Completer<Result<void>>();
      when(
        () => dialogService.showCustomDialog(
          variant: DialogType.confirm,
          title: 'Void invoice?',
          description: 'This reserves the invoice number and cannot be undone.',
          mainButtonTitle: 'Void invoice',
          secondaryButtonTitle: 'Keep invoice',
        ),
      ).thenAnswer((_) async => DialogResponse(confirmed: true));
      when(
        () => moneyRepository.voidInvoice('invoice'),
      ).thenAnswer((_) => pending.future);
      when(
        () => snackbarService.showCustomSnackBar(
          message: 'Void failed',
          variant: SnackbarType.error,
        ),
      ).thenAnswer((_) => null);
      final model = InvoiceDetailViewModel(
        invoice,
        repository: moneyRepository,
        businessProfileRepository: businessProfileRepository,
        workRepository: workRepository,
      );

      final first = model.voidInvoice();
      await Future<void>.delayed(Duration.zero);
      final second = model.voidInvoice();

      verify(() => moneyRepository.voidInvoice('invoice')).called(1);
      pending.complete(const Failure(ValidationFailure('Void failed')));
      await Future.wait([first, second]);
    },
  );

  test('voidInvoice marks an invoice voided after confirmation', () async {
    final invoice = Invoice(
      id: 'invoice',
      number: 'INV-1',
      buyerId: 'customer',
      buyerName: 'Customer',
      issueDate: DateTime(2026, 7),
    );
    when(
      () => dialogService.showCustomDialog(
        variant: DialogType.confirm,
        title: 'Void invoice?',
        description: 'This reserves the invoice number and cannot be undone.',
        mainButtonTitle: 'Void invoice',
        secondaryButtonTitle: 'Keep invoice',
      ),
    ).thenAnswer((_) async => DialogResponse(confirmed: true));
    when(
      () => moneyRepository.voidInvoice('invoice'),
    ).thenAnswer((_) async => const Success(null));
    final model = InvoiceDetailViewModel(
      invoice,
      repository: moneyRepository,
      businessProfileRepository: businessProfileRepository,
      workRepository: workRepository,
    );
    await model.voidInvoice();
    expect(invoice.status, InvoiceStatus.voided);
  });
}
