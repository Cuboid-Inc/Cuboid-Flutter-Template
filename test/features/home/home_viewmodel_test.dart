import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/home/data/home_repository.dart';
import 'package:fleetgo/features/home/ui/home_viewmodel.dart';
import 'package:fleetgo/features/money/data/money_repository.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/models/expense.dart';
import 'package:fleetgo/core/models/payment.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/core/models/report_models.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:fleetgo/ui/bottom_sheets/payment_form/payment_form_sheet_model.dart';
import 'package:fleetgo/ui/bottom_sheets/period/period_sheet_model.dart';
import 'package:fleetgo/features/shell/shell_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../helpers/stacked_service_mocks.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockHomeRepository extends Mock implements HomeRepository {}

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockShellService extends Mock implements ShellService {}

class FakePeriod extends Fake implements Period {}

class FakeExpense extends Fake implements Expense {}

void main() {
  late MockNavigationService navigationService;
  late MockSnackbarService snackbarService;
  late MockAuthRepository authRepository;
  late MockHomeRepository homeRepository;
  late MockMoneyRepository moneyRepository;
  late MockBottomSheetService bottomSheetService;
  late MockShellService shellService;
  setUpAll(() {
    registerFallbackValue(FakePeriod());
    registerFallbackValue(FakeExpense());
  });

  setUp(() {
    navigationService = MockNavigationService();
    snackbarService = MockSnackbarService();
    authRepository = MockAuthRepository();
    homeRepository = MockHomeRepository();
    moneyRepository = MockMoneyRepository();
    bottomSheetService = MockBottomSheetService();
    shellService = MockShellService();

    replaceTestRegistration<NavigationService>(navigationService);
    replaceTestRegistration<SnackbarService>(snackbarService);
    if (locator.isRegistered<AuthRepository>()) {
      locator.unregister<AuthRepository>();
    }
    if (locator.isRegistered<HomeRepository>()) {
      locator.unregister<HomeRepository>();
    }
    if (locator.isRegistered<MoneyRepository>()) {
      locator.unregister<MoneyRepository>();
    }
    replaceTestRegistration<BottomSheetService>(bottomSheetService);
    if (locator.isRegistered<ShellService>()) {
      locator.unregister<ShellService>();
    }

    locator.registerSingleton<AuthRepository>(authRepository);
    locator.registerSingleton<HomeRepository>(homeRepository);
    locator.registerSingleton<MoneyRepository>(moneyRepository);
    locator.registerSingleton<ShellService>(shellService);
  });

  tearDown(() {
    locator.reset();
  });

  group('HomeViewModel Permission Checks -', () {
    test('owner@almasar.ae has all permissions', () {
      when(() => authRepository.currentAccess).thenReturn(_access(owner: true));

      final viewModel = HomeViewModel(homeRepository, moneyRepository);

      expect(viewModel.hasMoneyPermission, isTrue);
      expect(viewModel.hasOperationsPermission, isTrue);
      expect(viewModel.hasReportsPermission, isTrue);
    });

    test('aisha@almasar.ae has operations and money, but not reports', () {
      when(
        () => authRepository.currentAccess,
      ).thenReturn(_access(packs: {AccessPack.operations, AccessPack.money}));

      final viewModel = HomeViewModel(homeRepository, moneyRepository);

      expect(viewModel.hasMoneyPermission, isTrue);
      expect(viewModel.hasOperationsPermission, isTrue);
      expect(viewModel.hasReportsPermission, isFalse);
    });

    test('omar@almasar.ae has reports, but not operations or money', () {
      when(
        () => authRepository.currentAccess,
      ).thenReturn(_access(packs: {AccessPack.reports}));

      final viewModel = HomeViewModel(homeRepository, moneyRepository);

      expect(viewModel.hasMoneyPermission, isFalse);
      expect(viewModel.hasOperationsPermission, isFalse);
      expect(viewModel.hasReportsPermission, isTrue);
    });
  });

  group('HomeViewModel Redirection Navigation -', () {
    test('openReceivables sets Money tab index and Invoices segment', () {
      when(() => authRepository.currentAccess).thenReturn(_access(owner: true));
      final viewModel = HomeViewModel(homeRepository, moneyRepository);

      viewModel.openReceivables();

      verify(() => shellService.setIndex(2)).called(1);
      verify(
        () => shellService.setMoneySegment(MoneySegment.invoices),
      ).called(1);
    });

    test('openPayables sets Money tab index and Settlements segment', () {
      when(() => authRepository.currentAccess).thenReturn(_access(owner: true));
      final viewModel = HomeViewModel(homeRepository, moneyRepository);

      viewModel.openPayables();

      verify(() => shellService.setIndex(2)).called(1);
      verify(
        () => shellService.setMoneySegment(MoneySegment.settlements),
      ).called(1);
    });

    test(
      'openCompletedJobs sets Work tab index and Completed status filter',
      () {
        when(
          () => authRepository.currentAccess,
        ).thenReturn(_access(owner: true));
        final viewModel = HomeViewModel(homeRepository, moneyRepository);

        viewModel.openCompletedJobs();

        verify(() => shellService.setIndex(1)).called(1);
        verify(
          () => shellService.setWorkFilter(WorkStatus.completed),
        ).called(1);
      },
    );

    test('openPendingCheques sets Money tab index and Payments segment', () {
      when(() => authRepository.currentAccess).thenReturn(_access(owner: true));
      final viewModel = HomeViewModel(homeRepository, moneyRepository);

      viewModel.openPendingCheques();

      verify(() => shellService.setIndex(2)).called(1);
      verify(
        () => shellService.setMoneySegment(MoneySegment.payments),
      ).called(1);
    });
  });

  test('loads summary and exposes attention and formatted values', () async {
    final selected = Period.month(2026, 7);
    when(() => authRepository.currentAccess).thenReturn(_access(owner: true));
    when(() => homeRepository.fetchSummary(any())).thenAnswer(
      (_) async => Success(
        HomeSummary(
          period: selected,
          profit: 100,
          billed: 200,
          revenue: 120,
          operatingCosts: 20,
          received: 150,
          paidOut: 50,
          cashFlow: 100,
          totalReceivables: 75,
          totalPayables: 25,
          receivableCount: 2,
          payableCount: 1,
          unbilledCount: 1,
          pendingChequeCount: 2,
          expiries: [
            ExpiringDocument(
              ownerId: 'v',
              ownerName: 'Truck',
              ownerType: 'vehicle',
              kind: 'Insurance',
              expiresOn: DateTime(2026, 7, 10),
            ),
            ExpiringDocument(
              ownerId: 'd',
              ownerName: 'Driver',
              ownerType: 'driver',
              kind: 'Licence',
              expiresOn: DateTime(2026, 7, 11),
            ),
          ],
        ),
      ),
    );
    final model = HomeViewModel(homeRepository, moneyRepository);
    await model.load();
    expect(model.summary, isNotNull);
    expect(model.profit, contains('100'));
    expect(model.resultLabel, 'Profit');
    expect(model.revenue, contains('120'));
    expect(model.operatingCosts, contains('20'));
    expect(model.cashFlow, contains('+'));
    expect(model.receivableCount, 2);
    expect(model.payableCount, 1);
    expect(model.attention, hasLength(4));
    expect(model.attention.first.title, '1 completed job needs billing');
    model.openVehicleDocuments();
    model.openDriverDocuments();
    verify(() => navigationService.navigateTo(any())).called(2);
  });

  test('handles load and action failures, and period selection', () async {
    when(() => authRepository.currentAccess).thenReturn(_access(owner: true));
    when(() => homeRepository.fetchSummary(any())).thenAnswer(
      (_) async => const Failure(ValidationFailure('summary failed')),
    );
    final model = HomeViewModel(homeRepository, moneyRepository);
    await model.load();
    expect(model.errorMessage, 'summary failed');
    when(
      () => bottomSheetService.showCustomSheet<Period, PeriodSheetData>(
        variant: any(named: 'variant'),
        data: any(named: 'data'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer((_) async => SheetResponse(data: Period.month(2026, 6)));
    await model.selectPeriod();
    verify(() => homeRepository.fetchSummary(any())).called(2);
    when(
      () => navigationService.navigateTo(any()),
    ).thenAnswer((_) async => null);
    await model.newTrip();
    when(
      () => bottomSheetService.showCustomSheet<Expense, dynamic>(
        variant: any(named: 'variant'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer(
      (_) async => SheetResponse(
        data: Expense(
          id: 'e',
          date: DateTime(2026),
          category: ExpenseCategory.fuel,
          payee: 'P',
          net: 1,
        ),
      ),
    );
    when(() => moneyRepository.addExpense(any())).thenAnswer(
      (_) async => const Failure(ValidationFailure('expense failed')),
    );
    await model.addExpense();
    verify(
      () => snackbarService.showCustomSnackBar(
        message: 'expense failed',
        variant: SnackbarType.error,
      ),
    ).called(1);
    when(
      () => bottomSheetService.showCustomSheet<Payment, PaymentFormData>(
        variant: any(named: 'variant'),
        data: any(named: 'data'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer((_) async => null);
    await model.paymentIn();
    await model.paymentOut();
  });
}

AuthAccess _access({bool owner = false, Set<AccessPack> packs = const {}}) =>
    AuthAccess(
      memberId: 'member',
      tenantId: 'tenant',
      tenantName: 'Tenant',
      email: 'user@example.com',
      displayName: 'User',
      role: owner ? StaffRole.owner : StaffRole.staff,
      status: MembershipStatus.active,
      accessPacks: packs,
    );
