// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedBottomsheetGenerator
// **************************************************************************

import 'package:stacked_services/stacked_services.dart';

import 'app.locator.dart';
import '../ui/bottom_sheets/add_expense/add_expense_sheet.dart';
import '../ui/bottom_sheets/agreement_form/agreement_form_sheet.dart';
import '../ui/bottom_sheets/driver_form/driver_form_sheet.dart';
import '../ui/bottom_sheets/invite_staff_form/invite_staff_form_sheet.dart';
import '../ui/bottom_sheets/party_form/party_form_sheet.dart';
import '../ui/bottom_sheets/payment_form/payment_form_sheet.dart';
import '../ui/bottom_sheets/period/period_sheet.dart';
import '../ui/bottom_sheets/route_rate_form/route_rate_form_sheet.dart';
import '../ui/bottom_sheets/vehicle_form/vehicle_form_sheet.dart';

enum BottomSheetType {
  paymentForm,
  addExpense,
  period,
  partyForm,
  vehicleForm,
  driverForm,
  agreementForm,
  routeRateForm,
  inviteStaffForm,
}

void setupBottomSheetUi() {
  final bottomsheetService = locator<BottomSheetService>();

  final Map<BottomSheetType, SheetBuilder> builders = {
    BottomSheetType.paymentForm: (context, request, completer) =>
        PaymentFormSheet(request: request, completer: completer),
    BottomSheetType.addExpense: (context, request, completer) =>
        AddExpenseSheet(request: request, completer: completer),
    BottomSheetType.period: (context, request, completer) =>
        PeriodSheet(request: request, completer: completer),
    BottomSheetType.partyForm: (context, request, completer) =>
        PartyFormSheet(request: request, completer: completer),
    BottomSheetType.vehicleForm: (context, request, completer) =>
        VehicleFormSheet(request: request, completer: completer),
    BottomSheetType.driverForm: (context, request, completer) =>
        DriverFormSheet(request: request, completer: completer),
    BottomSheetType.agreementForm: (context, request, completer) =>
        AgreementFormSheet(request: request, completer: completer),
    BottomSheetType.routeRateForm: (context, request, completer) =>
        RouteRateFormSheet(request: request, completer: completer),
    BottomSheetType.inviteStaffForm: (context, request, completer) =>
        InviteStaffFormSheet(request: request, completer: completer),
  };

  bottomsheetService.setCustomSheetBuilders(builders);
}
