import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/driver_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/features/reports/data/reports_repository.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/add_expense/add_expense_sheet.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/add_expense/add_expense_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/agreement_form/agreement_form_sheet.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/agreement_form/agreement_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/driver_form/driver_form_sheet.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/driver_form/driver_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/invite_staff_form/invite_staff_form_sheet.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/invite_staff_form/invite_staff_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/party_form/party_form_sheet.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/party_form/party_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/payment_form/payment_form_sheet.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/payment_form/payment_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/period/period_sheet.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/period/period_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/route_rate_form/route_rate_form_sheet.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/route_rate_form/route_rate_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/vehicle_form/vehicle_form_sheet.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/vehicle_form/vehicle_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/dialogs/add_edit_extra/add_edit_extra_dialog.dart';
import 'package:cuboid_flutter_template/ui/dialogs/add_edit_extra/add_edit_extra_dialog_model.dart';
import 'package:cuboid_flutter_template/ui/dialogs/confirm/confirm_dialog.dart';
import 'package:cuboid_flutter_template/ui/dialogs/confirm/confirm_dialog_model.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/demo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../helpers/stacked_service_mocks.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockDriverRepository extends Mock implements DriverRepository {}

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

class MockReportsRepository extends Mock implements ReportsRepository {}

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget render(Widget Function(BuildContext) builder) => MaterialApp(
  home: Scaffold(body: Builder(builder: (context) => builder(context))),
);

void main() {
  late MockMoneyRepository money;
  late MockPartiesRepository parties;
  late MockVehicleRepository vehicles;
  late MockDriverRepository drivers;

  setUp(() async {
    await setupLocator();
    money = MockMoneyRepository();
    parties = MockPartiesRepository();
    vehicles = MockVehicleRepository();
    drivers = MockDriverRepository();
    replaceTestRegistration<AuthRepository>(MockAuthRepository());
    replaceTestRegistration<MoneyRepository>(money);
    replaceTestRegistration<PartiesRepository>(parties);
    replaceTestRegistration<VehicleRepository>(vehicles);
    replaceTestRegistration<DriverRepository>(drivers);
    replaceTestRegistration<ReportsRepository>(MockReportsRepository());
    replaceTestRegistration<NavigationService>(MockNavigationService());
    replaceTestRegistration<SnackbarService>(MockSnackbarService());
    replaceTestRegistration<BottomSheetService>(MockBottomSheetService());
    replaceTestRegistration<DialogService>(MockDialogService());
  });

  tearDown(locator.reset);

  testWidgets('app button renders enabled, disabled, compact, and loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Column(
          children: [
            AppButton(label: 'Save'),
            AppButton(label: 'Compact', compact: true),
            AppButton(label: 'Loading', loading: true),
          ],
        ),
      ),
    );
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Compact'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('bottom sheets render their initial forms', (tester) async {
    final completer = <SheetResponse>[];
    final request = SheetRequest();
    final paymentRequest = SheetRequest(
      data: const PaymentFormData(direction: PaymentDirection.incoming),
    );
    final builders = <Widget Function(BuildContext)>[
      (context) => AddExpenseSheet(
        request: request,
        completer: completer.add,
      ).builder(context, AddExpenseSheetModel(completer: completer.add), null),
      (context) =>
          AgreementFormSheet(
            request: request,
            completer: completer.add,
          ).builder(
            context,
            AgreementFormSheetModel(completer: completer.add, request: request),
            null,
          ),
      (context) =>
          DriverFormSheet(request: request, completer: completer.add).builder(
            context,
            DriverFormSheetModel(completer: completer.add, request: request),
            null,
          ),
      (context) =>
          InviteStaffFormSheet(
            request: request,
            completer: completer.add,
          ).builder(
            context,
            InviteStaffFormSheetModel(
              completer: completer.add,
              request: request,
            ),
            null,
          ),
      (context) =>
          PartyFormSheet(request: request, completer: completer.add).builder(
            context,
            PartyFormSheetModel(completer: completer.add, request: request),
            null,
          ),
      (context) =>
          PaymentFormSheet(
            request: paymentRequest,
            completer: completer.add,
          ).builder(
            context,
            PaymentFormSheetModel(
              completer: completer.add,
              request: paymentRequest,
            ),
            null,
          ),
      (context) =>
          PeriodSheet(request: request, completer: completer.add).builder(
            context,
            PeriodSheetModel(completer: completer.add, request: request),
            null,
          ),
      (context) =>
          RouteRateFormSheet(
            request: request,
            completer: completer.add,
          ).builder(
            context,
            RouteRateFormSheetModel(completer: completer.add, request: request),
            null,
          ),
      (context) =>
          VehicleFormSheet(request: request, completer: completer.add).builder(
            context,
            VehicleFormSheetModel(completer: completer.add, request: request),
            null,
          ),
    ];

    for (final builder in builders) {
      await tester.pumpWidget(render(builder));
      expect(find.byType(DemoSheet), findsOneWidget);
    }
  });

  testWidgets('dialogs render their actions and request text', (tester) async {
    final responses = <DialogResponse>[];
    final addRequest = DialogRequest();
    await tester.pumpWidget(
      render(
        (context) =>
            AddEditExtraDialog(
              request: addRequest,
              completer: responses.add,
            ).builder(
              context,
              AddEditExtraDialogModel(
                completer: responses.add,
                request: addRequest,
              ),
              null,
            ),
      ),
    );
    expect(find.text('Add Extra'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    final confirmRequest = DialogRequest(
      title: 'Delete vehicle',
      description: 'This action is permanent.',
      mainButtonTitle: 'Delete',
      secondaryButtonTitle: 'Keep',
    );
    await tester.pumpWidget(
      render(
        (context) => ConfirmDialog(
          request: confirmRequest,
          completer: responses.add,
        ).builder(context, ConfirmDialogModel(completer: responses.add), null),
      ),
    );
    expect(find.text('Delete vehicle'), findsOneWidget);
    expect(find.text('This action is permanent.'), findsOneWidget);
    expect(find.text('Keep'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}
