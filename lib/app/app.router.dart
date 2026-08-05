// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i48;
import 'dart:typed_data' as _i49;

import 'package:cuboid_flutter_template/core/enums/enums.dart' as _i50;
import 'package:cuboid_flutter_template/core/models/agreement.dart' as _i45;
import 'package:cuboid_flutter_template/core/models/driver.dart' as _i43;
import 'package:cuboid_flutter_template/core/models/expense.dart' as _i41;
import 'package:cuboid_flutter_template/core/models/invoice.dart' as _i37;
import 'package:cuboid_flutter_template/core/models/party.dart' as _i42;
import 'package:cuboid_flutter_template/core/models/payment.dart' as _i40;
import 'package:cuboid_flutter_template/core/models/period.dart' as _i39;
import 'package:cuboid_flutter_template/core/models/route_rate.dart' as _i44;
import 'package:cuboid_flutter_template/core/models/settlement.dart' as _i38;
import 'package:cuboid_flutter_template/core/models/vehicle.dart' as _i46;
import 'package:cuboid_flutter_template/core/models/work_order.dart' as _i36;
import 'package:cuboid_flutter_template/features/auth/ui/accept_invitation/accept_invitation_view.dart'
    as _i32;
import 'package:cuboid_flutter_template/features/auth/ui/access_unavailable/access_unavailable_view.dart'
    as _i33;
import 'package:cuboid_flutter_template/features/auth/ui/forgot_password/forgot_password_view.dart'
    as _i30;
import 'package:cuboid_flutter_template/features/auth/ui/login/login_view.dart'
    as _i3;
import 'package:cuboid_flutter_template/features/auth/ui/reset_password/reset_password_view.dart'
    as _i31;
import 'package:cuboid_flutter_template/features/money/ui/balance_detail/balance_detail_view.dart'
    as _i15;
import 'package:cuboid_flutter_template/features/money/ui/expense_detail/expense_detail_view.dart'
    as _i14;
import 'package:cuboid_flutter_template/features/money/ui/invoice_detail/invoice_detail_view.dart'
    as _i10;
import 'package:cuboid_flutter_template/features/money/ui/payment_detail/payment_detail_view.dart'
    as _i13;
import 'package:cuboid_flutter_template/features/money/ui/settlement_detail/settlement_detail_view.dart'
    as _i11;
import 'package:cuboid_flutter_template/features/money/ui/statement_view/statement_view.dart'
    as _i12;
import 'package:cuboid_flutter_template/features/more/ui/agreement_detail/agreement_detail_view.dart'
    as _i23;
import 'package:cuboid_flutter_template/features/more/ui/agreements/agreements_view.dart'
    as _i20;
import 'package:cuboid_flutter_template/features/more/ui/business_profile/business_profile_view.dart'
    as _i26;
import 'package:cuboid_flutter_template/features/more/ui/driver_detail/driver_detail_view.dart'
    as _i19;
import 'package:cuboid_flutter_template/features/more/ui/drivers/drivers_view.dart'
    as _i18;
import 'package:cuboid_flutter_template/features/more/ui/route_rate_detail/route_rate_detail_view.dart'
    as _i22;
import 'package:cuboid_flutter_template/features/more/ui/route_rates/route_rates_view.dart'
    as _i21;
import 'package:cuboid_flutter_template/features/more/ui/staff_access/staff_access_view.dart'
    as _i25;
import 'package:cuboid_flutter_template/features/more/ui/vehicle_detail/vehicle_detail_view.dart'
    as _i24;
import 'package:cuboid_flutter_template/features/more/ui/vehicles/vehicles_view.dart'
    as _i17;
import 'package:cuboid_flutter_template/features/parties/ui/parties/parties_view.dart'
    as _i5;
import 'package:cuboid_flutter_template/features/parties/ui/party_detail/party_detail_view.dart'
    as _i16;
import 'package:cuboid_flutter_template/features/reports/data/report_type.dart'
    as _i47;
import 'package:cuboid_flutter_template/features/reports/ui/report_detail/report_detail_view.dart'
    as _i28;
import 'package:cuboid_flutter_template/features/reports/ui/reports_view.dart'
    as _i27;
import 'package:cuboid_flutter_template/features/shell/shell_view.dart' as _i4;
import 'package:cuboid_flutter_template/features/startup/startup_view.dart'
    as _i2;
import 'package:cuboid_flutter_template/features/work/ui/monthly_work/monthly_work_view.dart'
    as _i7;
import 'package:cuboid_flutter_template/features/work/ui/new_trip/new_trip_view.dart'
    as _i6;
import 'package:cuboid_flutter_template/features/work/ui/prepare_month/prepare_month_view.dart'
    as _i8;
import 'package:cuboid_flutter_template/features/work/ui/work_detail/work_detail_view.dart'
    as _i9;
import 'package:cuboid_flutter_template/ui/pdf/pdf_preview_view.dart' as _i29;
import 'package:flutter/cupertino.dart' as _i35;
import 'package:flutter/material.dart' as _i34;
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i51;

class Routes {
  static const startupView = '/';

  static const loginView = '/login-view';

  static const shellView = '/shell-view';

  static const partiesView = '/parties-view';

  static const newTripView = '/new-trip-view';

  static const monthlyWorkView = '/monthly-work-view';

  static const prepareMonthView = '/prepare-month-view';

  static const workDetailView = '/work-detail-view';

  static const invoiceDetailView = '/invoice-detail-view';

  static const settlementDetailView = '/settlement-detail-view';

  static const statementView = '/statement-view';

  static const paymentDetailView = '/payment-detail-view';

  static const expenseDetailView = '/expense-detail-view';

  static const balanceDetailView = '/balance-detail-view';

  static const partyDetailView = '/party-detail-view';

  static const vehiclesView = '/vehicles-view';

  static const driversView = '/drivers-view';

  static const driverDetailView = '/driver-detail-view';

  static const agreementsView = '/agreements-view';

  static const routeRatesView = '/route-rates-view';

  static const routeRateDetailView = '/route-rate-detail-view';

  static const agreementDetailView = '/agreement-detail-view';

  static const vehicleDetailView = '/vehicle-detail-view';

  static const staffAccessView = '/staff-access-view';

  static const businessProfileView = '/business-profile-view';

  static const reportsView = '/reports-view';

  static const reportDetailView = '/report-detail-view';

  static const pdfPreviewView = '/pdf-preview-view';

  static const forgotPasswordView = '/forgot-password-view';

  static const resetPasswordView = '/reset-password-view';

  static const acceptInvitationView = '/accept-invitation-view';

  static const accessUnavailableView = '/access-unavailable-view';

  static const all = <String>{
    startupView,
    loginView,
    shellView,
    partiesView,
    newTripView,
    monthlyWorkView,
    prepareMonthView,
    workDetailView,
    invoiceDetailView,
    settlementDetailView,
    statementView,
    paymentDetailView,
    expenseDetailView,
    balanceDetailView,
    partyDetailView,
    vehiclesView,
    driversView,
    driverDetailView,
    agreementsView,
    routeRatesView,
    routeRateDetailView,
    agreementDetailView,
    vehicleDetailView,
    staffAccessView,
    businessProfileView,
    reportsView,
    reportDetailView,
    pdfPreviewView,
    forgotPasswordView,
    resetPasswordView,
    acceptInvitationView,
    accessUnavailableView,
  };
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(Routes.startupView, page: _i2.StartupView),
    _i1.RouteDef(Routes.loginView, page: _i3.LoginView),
    _i1.RouteDef(Routes.shellView, page: _i4.ShellView),
    _i1.RouteDef(Routes.partiesView, page: _i5.PartiesView),
    _i1.RouteDef(Routes.newTripView, page: _i6.NewTripView),
    _i1.RouteDef(Routes.monthlyWorkView, page: _i7.MonthlyWorkView),
    _i1.RouteDef(Routes.prepareMonthView, page: _i8.PrepareMonthView),
    _i1.RouteDef(Routes.workDetailView, page: _i9.WorkDetailView),
    _i1.RouteDef(Routes.invoiceDetailView, page: _i10.InvoiceDetailView),
    _i1.RouteDef(Routes.settlementDetailView, page: _i11.SettlementDetailView),
    _i1.RouteDef(Routes.statementView, page: _i12.StatementView),
    _i1.RouteDef(Routes.paymentDetailView, page: _i13.PaymentDetailView),
    _i1.RouteDef(Routes.expenseDetailView, page: _i14.ExpenseDetailView),
    _i1.RouteDef(Routes.balanceDetailView, page: _i15.BalanceDetailView),
    _i1.RouteDef(Routes.partyDetailView, page: _i16.PartyDetailView),
    _i1.RouteDef(Routes.vehiclesView, page: _i17.VehiclesView),
    _i1.RouteDef(Routes.driversView, page: _i18.DriversView),
    _i1.RouteDef(Routes.driverDetailView, page: _i19.DriverDetailView),
    _i1.RouteDef(Routes.agreementsView, page: _i20.AgreementsView),
    _i1.RouteDef(Routes.routeRatesView, page: _i21.RouteRatesView),
    _i1.RouteDef(Routes.routeRateDetailView, page: _i22.RouteRateDetailView),
    _i1.RouteDef(Routes.agreementDetailView, page: _i23.AgreementDetailView),
    _i1.RouteDef(Routes.vehicleDetailView, page: _i24.VehicleDetailView),
    _i1.RouteDef(Routes.staffAccessView, page: _i25.StaffAccessView),
    _i1.RouteDef(Routes.businessProfileView, page: _i26.BusinessProfileView),
    _i1.RouteDef(Routes.reportsView, page: _i27.ReportsView),
    _i1.RouteDef(Routes.reportDetailView, page: _i28.ReportDetailView),
    _i1.RouteDef(Routes.pdfPreviewView, page: _i29.PdfPreviewView),
    _i1.RouteDef(Routes.forgotPasswordView, page: _i30.ForgotPasswordView),
    _i1.RouteDef(Routes.resetPasswordView, page: _i31.ResetPasswordView),
    _i1.RouteDef(Routes.acceptInvitationView, page: _i32.AcceptInvitationView),
    _i1.RouteDef(
      Routes.accessUnavailableView,
      page: _i33.AccessUnavailableView,
    ),
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.StartupView: (data) {
      final args = data.getArgs<StartupViewArguments>(
        orElse: () => const StartupViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i2.StartupView(key: args.key),
        settings: data,
      );
    },
    _i3.LoginView: (data) {
      final args = data.getArgs<LoginViewArguments>(
        orElse: () => const LoginViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i3.LoginView(key: args.key),
        settings: data,
      );
    },
    _i4.ShellView: (data) {
      final args = data.getArgs<ShellViewArguments>(
        orElse: () => const ShellViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i4.ShellView(key: args.key),
        settings: data,
      );
    },
    _i5.PartiesView: (data) {
      final args = data.getArgs<PartiesViewArguments>(
        orElse: () => const PartiesViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i5.PartiesView(key: args.key),
        settings: data,
      );
    },
    _i6.NewTripView: (data) {
      final args = data.getArgs<NewTripViewArguments>(
        orElse: () => const NewTripViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i6.NewTripView(key: args.key),
        settings: data,
      );
    },
    _i7.MonthlyWorkView: (data) {
      final args = data.getArgs<MonthlyWorkViewArguments>(
        orElse: () => const MonthlyWorkViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i7.MonthlyWorkView(key: args.key),
        settings: data,
      );
    },
    _i8.PrepareMonthView: (data) {
      final args = data.getArgs<PrepareMonthViewArguments>(
        orElse: () => const PrepareMonthViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i8.PrepareMonthView(key: args.key, customerId: args.customerId),
        settings: data,
      );
    },
    _i9.WorkDetailView: (data) {
      final args = data.getArgs<WorkDetailViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i9.WorkDetailView(key: args.key, work: args.work),
        settings: data,
      );
    },
    _i10.InvoiceDetailView: (data) {
      final args = data.getArgs<InvoiceDetailViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i10.InvoiceDetailView(key: args.key, invoice: args.invoice),
        settings: data,
      );
    },
    _i11.SettlementDetailView: (data) {
      final args = data.getArgs<SettlementDetailViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i11.SettlementDetailView(
          key: args.key,
          settlement: args.settlement,
        ),
        settings: data,
      );
    },
    _i12.StatementView: (data) {
      final args = data.getArgs<StatementViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i12.StatementView(
          key: args.key,
          partyId: args.partyId,
          period: args.period,
        ),
        settings: data,
      );
    },
    _i13.PaymentDetailView: (data) {
      final args = data.getArgs<PaymentDetailViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i13.PaymentDetailView(key: args.key, payment: args.payment),
        settings: data,
      );
    },
    _i14.ExpenseDetailView: (data) {
      final args = data.getArgs<ExpenseDetailViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i14.ExpenseDetailView(key: args.key, expense: args.expense),
        settings: data,
      );
    },
    _i15.BalanceDetailView: (data) {
      final args = data.getArgs<BalanceDetailViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i15.BalanceDetailView(key: args.key, party: args.party),
        settings: data,
      );
    },
    _i16.PartyDetailView: (data) {
      final args = data.getArgs<PartyDetailViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i16.PartyDetailView(key: args.key, party: args.party),
        settings: data,
      );
    },
    _i17.VehiclesView: (data) {
      final args = data.getArgs<VehiclesViewArguments>(
        orElse: () => const VehiclesViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i17.VehiclesView(key: args.key),
        settings: data,
      );
    },
    _i18.DriversView: (data) {
      final args = data.getArgs<DriversViewArguments>(
        orElse: () => const DriversViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i18.DriversView(key: args.key),
        settings: data,
      );
    },
    _i19.DriverDetailView: (data) {
      final args = data.getArgs<DriverDetailViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i19.DriverDetailView(key: args.key, driver: args.driver),
        settings: data,
      );
    },
    _i20.AgreementsView: (data) {
      final args = data.getArgs<AgreementsViewArguments>(
        orElse: () => const AgreementsViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i20.AgreementsView(key: args.key),
        settings: data,
      );
    },
    _i21.RouteRatesView: (data) {
      final args = data.getArgs<RouteRatesViewArguments>(
        orElse: () => const RouteRatesViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i21.RouteRatesView(key: args.key),
        settings: data,
      );
    },
    _i22.RouteRateDetailView: (data) {
      final args = data.getArgs<RouteRateDetailViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i22.RouteRateDetailView(key: args.key, routeRate: args.routeRate),
        settings: data,
      );
    },
    _i23.AgreementDetailView: (data) {
      final args = data.getArgs<AgreementDetailViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i23.AgreementDetailView(key: args.key, agreement: args.agreement),
        settings: data,
      );
    },
    _i24.VehicleDetailView: (data) {
      final args = data.getArgs<VehicleDetailViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i24.VehicleDetailView(key: args.key, vehicle: args.vehicle),
        settings: data,
      );
    },
    _i25.StaffAccessView: (data) {
      final args = data.getArgs<StaffAccessViewArguments>(
        orElse: () => const StaffAccessViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i25.StaffAccessView(key: args.key),
        settings: data,
      );
    },
    _i26.BusinessProfileView: (data) {
      final args = data.getArgs<BusinessProfileViewArguments>(
        orElse: () => const BusinessProfileViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i26.BusinessProfileView(key: args.key),
        settings: data,
      );
    },
    _i27.ReportsView: (data) {
      final args = data.getArgs<ReportsViewArguments>(
        orElse: () => const ReportsViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i27.ReportsView(key: args.key),
        settings: data,
      );
    },
    _i28.ReportDetailView: (data) {
      final args = data.getArgs<ReportDetailViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i28.ReportDetailView(
          key: args.key,
          type: args.type,
          period: args.period,
        ),
        settings: data,
      );
    },
    _i29.PdfPreviewView: (data) {
      final args = data.getArgs<PdfPreviewViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i29.PdfPreviewView(args.title, args.build, key: args.key),
        settings: data,
      );
    },
    _i30.ForgotPasswordView: (data) {
      final args = data.getArgs<ForgotPasswordViewArguments>(
        orElse: () => const ForgotPasswordViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i30.ForgotPasswordView(key: args.key),
        settings: data,
      );
    },
    _i31.ResetPasswordView: (data) {
      final args = data.getArgs<ResetPasswordViewArguments>(
        orElse: () => const ResetPasswordViewArguments(),
      );
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i31.ResetPasswordView(key: args.key),
        settings: data,
      );
    },
    _i32.AcceptInvitationView: (data) {
      final args = data.getArgs<AcceptInvitationViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i32.AcceptInvitationView(
          key: args.key,
          email: args.email,
          businessName: args.businessName,
          accessPacks: args.accessPacks,
        ),
        settings: data,
      );
    },
    _i33.AccessUnavailableView: (data) {
      final args = data.getArgs<AccessUnavailableViewArguments>(nullOk: false);
      return _i34.MaterialPageRoute<dynamic>(
        builder: (context) => _i33.AccessUnavailableView(
          key: args.key,
          title: args.title,
          message: args.message,
          showRetry: args.showRetry,
        ),
        settings: data,
      );
    },
  };

  @override
  List<_i1.RouteDef> get routes => _routes;

  @override
  Map<Type, _i1.StackedRouteFactory> get pagesMap => _pagesMap;
}

class StartupViewArguments {
  const StartupViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant StartupViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class LoginViewArguments {
  const LoginViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant LoginViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class ShellViewArguments {
  const ShellViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant ShellViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class PartiesViewArguments {
  const PartiesViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant PartiesViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class NewTripViewArguments {
  const NewTripViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant NewTripViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class MonthlyWorkViewArguments {
  const MonthlyWorkViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant MonthlyWorkViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class PrepareMonthViewArguments {
  const PrepareMonthViewArguments({this.key, this.customerId});

  final _i35.Key? key;

  final String? customerId;

  @override
  String toString() {
    return '{"key": "$key", "customerId": "$customerId"}';
  }

  @override
  bool operator ==(covariant PrepareMonthViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.customerId == customerId;
  }

  @override
  int get hashCode {
    return key.hashCode ^ customerId.hashCode;
  }
}

class WorkDetailViewArguments {
  const WorkDetailViewArguments({this.key, required this.work});

  final _i35.Key? key;

  final _i36.WorkOrder work;

  @override
  String toString() {
    return '{"key": "$key", "work": "$work"}';
  }

  @override
  bool operator ==(covariant WorkDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.work == work;
  }

  @override
  int get hashCode {
    return key.hashCode ^ work.hashCode;
  }
}

class InvoiceDetailViewArguments {
  const InvoiceDetailViewArguments({this.key, required this.invoice});

  final _i35.Key? key;

  final _i37.Invoice invoice;

  @override
  String toString() {
    return '{"key": "$key", "invoice": "$invoice"}';
  }

  @override
  bool operator ==(covariant InvoiceDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.invoice == invoice;
  }

  @override
  int get hashCode {
    return key.hashCode ^ invoice.hashCode;
  }
}

class SettlementDetailViewArguments {
  const SettlementDetailViewArguments({this.key, required this.settlement});

  final _i35.Key? key;

  final _i38.SupplierSettlement settlement;

  @override
  String toString() {
    return '{"key": "$key", "settlement": "$settlement"}';
  }

  @override
  bool operator ==(covariant SettlementDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.settlement == settlement;
  }

  @override
  int get hashCode {
    return key.hashCode ^ settlement.hashCode;
  }
}

class StatementViewArguments {
  const StatementViewArguments({
    this.key,
    required this.partyId,
    required this.period,
  });

  final _i35.Key? key;

  final String partyId;

  final _i39.Period period;

  @override
  String toString() {
    return '{"key": "$key", "partyId": "$partyId", "period": "$period"}';
  }

  @override
  bool operator ==(covariant StatementViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.partyId == partyId &&
        other.period == period;
  }

  @override
  int get hashCode {
    return key.hashCode ^ partyId.hashCode ^ period.hashCode;
  }
}

class PaymentDetailViewArguments {
  const PaymentDetailViewArguments({this.key, required this.payment});

  final _i35.Key? key;

  final _i40.Payment payment;

  @override
  String toString() {
    return '{"key": "$key", "payment": "$payment"}';
  }

  @override
  bool operator ==(covariant PaymentDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.payment == payment;
  }

  @override
  int get hashCode {
    return key.hashCode ^ payment.hashCode;
  }
}

class ExpenseDetailViewArguments {
  const ExpenseDetailViewArguments({this.key, required this.expense});

  final _i35.Key? key;

  final _i41.Expense expense;

  @override
  String toString() {
    return '{"key": "$key", "expense": "$expense"}';
  }

  @override
  bool operator ==(covariant ExpenseDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.expense == expense;
  }

  @override
  int get hashCode {
    return key.hashCode ^ expense.hashCode;
  }
}

class BalanceDetailViewArguments {
  const BalanceDetailViewArguments({this.key, required this.party});

  final _i35.Key? key;

  final _i42.Party party;

  @override
  String toString() {
    return '{"key": "$key", "party": "$party"}';
  }

  @override
  bool operator ==(covariant BalanceDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.party == party;
  }

  @override
  int get hashCode {
    return key.hashCode ^ party.hashCode;
  }
}

class PartyDetailViewArguments {
  const PartyDetailViewArguments({this.key, required this.party});

  final _i35.Key? key;

  final _i42.Party party;

  @override
  String toString() {
    return '{"key": "$key", "party": "$party"}';
  }

  @override
  bool operator ==(covariant PartyDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.party == party;
  }

  @override
  int get hashCode {
    return key.hashCode ^ party.hashCode;
  }
}

class VehiclesViewArguments {
  const VehiclesViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant VehiclesViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class DriversViewArguments {
  const DriversViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant DriversViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class DriverDetailViewArguments {
  const DriverDetailViewArguments({this.key, required this.driver});

  final _i35.Key? key;

  final _i43.Driver driver;

  @override
  String toString() {
    return '{"key": "$key", "driver": "$driver"}';
  }

  @override
  bool operator ==(covariant DriverDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.driver == driver;
  }

  @override
  int get hashCode {
    return key.hashCode ^ driver.hashCode;
  }
}

class AgreementsViewArguments {
  const AgreementsViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant AgreementsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class RouteRatesViewArguments {
  const RouteRatesViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant RouteRatesViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class RouteRateDetailViewArguments {
  const RouteRateDetailViewArguments({this.key, required this.routeRate});

  final _i35.Key? key;

  final _i44.RouteRate routeRate;

  @override
  String toString() {
    return '{"key": "$key", "routeRate": "$routeRate"}';
  }

  @override
  bool operator ==(covariant RouteRateDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.routeRate == routeRate;
  }

  @override
  int get hashCode {
    return key.hashCode ^ routeRate.hashCode;
  }
}

class AgreementDetailViewArguments {
  const AgreementDetailViewArguments({this.key, required this.agreement});

  final _i35.Key? key;

  final _i45.Agreement agreement;

  @override
  String toString() {
    return '{"key": "$key", "agreement": "$agreement"}';
  }

  @override
  bool operator ==(covariant AgreementDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.agreement == agreement;
  }

  @override
  int get hashCode {
    return key.hashCode ^ agreement.hashCode;
  }
}

class VehicleDetailViewArguments {
  const VehicleDetailViewArguments({this.key, required this.vehicle});

  final _i35.Key? key;

  final _i46.Vehicle vehicle;

  @override
  String toString() {
    return '{"key": "$key", "vehicle": "$vehicle"}';
  }

  @override
  bool operator ==(covariant VehicleDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.vehicle == vehicle;
  }

  @override
  int get hashCode {
    return key.hashCode ^ vehicle.hashCode;
  }
}

class StaffAccessViewArguments {
  const StaffAccessViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant StaffAccessViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class BusinessProfileViewArguments {
  const BusinessProfileViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant BusinessProfileViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class ReportsViewArguments {
  const ReportsViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant ReportsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class ReportDetailViewArguments {
  const ReportDetailViewArguments({
    this.key,
    required this.type,
    required this.period,
  });

  final _i35.Key? key;

  final _i47.ReportType type;

  final _i39.Period period;

  @override
  String toString() {
    return '{"key": "$key", "type": "$type", "period": "$period"}';
  }

  @override
  bool operator ==(covariant ReportDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.type == type && other.period == period;
  }

  @override
  int get hashCode {
    return key.hashCode ^ type.hashCode ^ period.hashCode;
  }
}

class PdfPreviewViewArguments {
  const PdfPreviewViewArguments({
    required this.title,
    required this.build,
    this.key,
  });

  final String title;

  final _i48.Future<_i49.Uint8List> Function() build;

  final _i35.Key? key;

  @override
  String toString() {
    return '{"title": "$title", "build": "$build", "key": "$key"}';
  }

  @override
  bool operator ==(covariant PdfPreviewViewArguments other) {
    if (identical(this, other)) return true;
    return other.title == title && other.build == build && other.key == key;
  }

  @override
  int get hashCode {
    return title.hashCode ^ build.hashCode ^ key.hashCode;
  }
}

class ForgotPasswordViewArguments {
  const ForgotPasswordViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant ForgotPasswordViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class ResetPasswordViewArguments {
  const ResetPasswordViewArguments({this.key});

  final _i35.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant ResetPasswordViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class AcceptInvitationViewArguments {
  const AcceptInvitationViewArguments({
    this.key,
    required this.email,
    required this.businessName,
    required this.accessPacks,
  });

  final _i35.Key? key;

  final String email;

  final String businessName;

  final List<_i50.AccessPack> accessPacks;

  @override
  String toString() {
    return '{"key": "$key", "email": "$email", "businessName": "$businessName", "accessPacks": "$accessPacks"}';
  }

  @override
  bool operator ==(covariant AcceptInvitationViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.email == email &&
        other.businessName == businessName &&
        other.accessPacks == accessPacks;
  }

  @override
  int get hashCode {
    return key.hashCode ^
        email.hashCode ^
        businessName.hashCode ^
        accessPacks.hashCode;
  }
}

class AccessUnavailableViewArguments {
  const AccessUnavailableViewArguments({
    this.key,
    required this.title,
    required this.message,
    this.showRetry = false,
  });

  final _i35.Key? key;

  final String title;

  final String message;

  final bool showRetry;

  @override
  String toString() {
    return '{"key": "$key", "title": "$title", "message": "$message", "showRetry": "$showRetry"}';
  }

  @override
  bool operator ==(covariant AccessUnavailableViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.title == title &&
        other.message == message &&
        other.showRetry == showRetry;
  }

  @override
  int get hashCode {
    return key.hashCode ^
        title.hashCode ^
        message.hashCode ^
        showRetry.hashCode;
  }
}

extension NavigatorStateExtension on _i51.NavigationService {
  Future<dynamic> navigateToStartupView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.startupView,
      arguments: StartupViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToLoginView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.loginView,
      arguments: LoginViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToShellView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.shellView,
      arguments: ShellViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToPartiesView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.partiesView,
      arguments: PartiesViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToNewTripView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.newTripView,
      arguments: NewTripViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToMonthlyWorkView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.monthlyWorkView,
      arguments: MonthlyWorkViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToPrepareMonthView({
    _i35.Key? key,
    String? customerId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.prepareMonthView,
      arguments: PrepareMonthViewArguments(key: key, customerId: customerId),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToWorkDetailView({
    _i35.Key? key,
    required _i36.WorkOrder work,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.workDetailView,
      arguments: WorkDetailViewArguments(key: key, work: work),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToInvoiceDetailView({
    _i35.Key? key,
    required _i37.Invoice invoice,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.invoiceDetailView,
      arguments: InvoiceDetailViewArguments(key: key, invoice: invoice),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToSettlementDetailView({
    _i35.Key? key,
    required _i38.SupplierSettlement settlement,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.settlementDetailView,
      arguments: SettlementDetailViewArguments(
        key: key,
        settlement: settlement,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToStatementView({
    _i35.Key? key,
    required String partyId,
    required _i39.Period period,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.statementView,
      arguments: StatementViewArguments(
        key: key,
        partyId: partyId,
        period: period,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToPaymentDetailView({
    _i35.Key? key,
    required _i40.Payment payment,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.paymentDetailView,
      arguments: PaymentDetailViewArguments(key: key, payment: payment),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToExpenseDetailView({
    _i35.Key? key,
    required _i41.Expense expense,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.expenseDetailView,
      arguments: ExpenseDetailViewArguments(key: key, expense: expense),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToBalanceDetailView({
    _i35.Key? key,
    required _i42.Party party,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.balanceDetailView,
      arguments: BalanceDetailViewArguments(key: key, party: party),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToPartyDetailView({
    _i35.Key? key,
    required _i42.Party party,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.partyDetailView,
      arguments: PartyDetailViewArguments(key: key, party: party),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToVehiclesView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.vehiclesView,
      arguments: VehiclesViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToDriversView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.driversView,
      arguments: DriversViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToDriverDetailView({
    _i35.Key? key,
    required _i43.Driver driver,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.driverDetailView,
      arguments: DriverDetailViewArguments(key: key, driver: driver),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToAgreementsView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.agreementsView,
      arguments: AgreementsViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToRouteRatesView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.routeRatesView,
      arguments: RouteRatesViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToRouteRateDetailView({
    _i35.Key? key,
    required _i44.RouteRate routeRate,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.routeRateDetailView,
      arguments: RouteRateDetailViewArguments(key: key, routeRate: routeRate),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToAgreementDetailView({
    _i35.Key? key,
    required _i45.Agreement agreement,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.agreementDetailView,
      arguments: AgreementDetailViewArguments(key: key, agreement: agreement),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToVehicleDetailView({
    _i35.Key? key,
    required _i46.Vehicle vehicle,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.vehicleDetailView,
      arguments: VehicleDetailViewArguments(key: key, vehicle: vehicle),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToStaffAccessView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.staffAccessView,
      arguments: StaffAccessViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToBusinessProfileView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.businessProfileView,
      arguments: BusinessProfileViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToReportsView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.reportsView,
      arguments: ReportsViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToReportDetailView({
    _i35.Key? key,
    required _i47.ReportType type,
    required _i39.Period period,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.reportDetailView,
      arguments: ReportDetailViewArguments(
        key: key,
        type: type,
        period: period,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToPdfPreviewView({
    required String title,
    required _i48.Future<_i49.Uint8List> Function() build,
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.pdfPreviewView,
      arguments: PdfPreviewViewArguments(title: title, build: build, key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToForgotPasswordView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.forgotPasswordView,
      arguments: ForgotPasswordViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToResetPasswordView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.resetPasswordView,
      arguments: ResetPasswordViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToAcceptInvitationView({
    _i35.Key? key,
    required String email,
    required String businessName,
    required List<_i50.AccessPack> accessPacks,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.acceptInvitationView,
      arguments: AcceptInvitationViewArguments(
        key: key,
        email: email,
        businessName: businessName,
        accessPacks: accessPacks,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToAccessUnavailableView({
    _i35.Key? key,
    required String title,
    required String message,
    bool showRetry = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.accessUnavailableView,
      arguments: AccessUnavailableViewArguments(
        key: key,
        title: title,
        message: message,
        showRetry: showRetry,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithStartupView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.startupView,
      arguments: StartupViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithLoginView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.loginView,
      arguments: LoginViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithShellView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.shellView,
      arguments: ShellViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithPartiesView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.partiesView,
      arguments: PartiesViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithNewTripView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.newTripView,
      arguments: NewTripViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithMonthlyWorkView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.monthlyWorkView,
      arguments: MonthlyWorkViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithPrepareMonthView({
    _i35.Key? key,
    String? customerId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.prepareMonthView,
      arguments: PrepareMonthViewArguments(key: key, customerId: customerId),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithWorkDetailView({
    _i35.Key? key,
    required _i36.WorkOrder work,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.workDetailView,
      arguments: WorkDetailViewArguments(key: key, work: work),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithInvoiceDetailView({
    _i35.Key? key,
    required _i37.Invoice invoice,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.invoiceDetailView,
      arguments: InvoiceDetailViewArguments(key: key, invoice: invoice),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithSettlementDetailView({
    _i35.Key? key,
    required _i38.SupplierSettlement settlement,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.settlementDetailView,
      arguments: SettlementDetailViewArguments(
        key: key,
        settlement: settlement,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithStatementView({
    _i35.Key? key,
    required String partyId,
    required _i39.Period period,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.statementView,
      arguments: StatementViewArguments(
        key: key,
        partyId: partyId,
        period: period,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithPaymentDetailView({
    _i35.Key? key,
    required _i40.Payment payment,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.paymentDetailView,
      arguments: PaymentDetailViewArguments(key: key, payment: payment),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithExpenseDetailView({
    _i35.Key? key,
    required _i41.Expense expense,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.expenseDetailView,
      arguments: ExpenseDetailViewArguments(key: key, expense: expense),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithBalanceDetailView({
    _i35.Key? key,
    required _i42.Party party,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.balanceDetailView,
      arguments: BalanceDetailViewArguments(key: key, party: party),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithPartyDetailView({
    _i35.Key? key,
    required _i42.Party party,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.partyDetailView,
      arguments: PartyDetailViewArguments(key: key, party: party),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithVehiclesView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.vehiclesView,
      arguments: VehiclesViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithDriversView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.driversView,
      arguments: DriversViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithDriverDetailView({
    _i35.Key? key,
    required _i43.Driver driver,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.driverDetailView,
      arguments: DriverDetailViewArguments(key: key, driver: driver),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithAgreementsView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.agreementsView,
      arguments: AgreementsViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithRouteRatesView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.routeRatesView,
      arguments: RouteRatesViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithRouteRateDetailView({
    _i35.Key? key,
    required _i44.RouteRate routeRate,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.routeRateDetailView,
      arguments: RouteRateDetailViewArguments(key: key, routeRate: routeRate),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithAgreementDetailView({
    _i35.Key? key,
    required _i45.Agreement agreement,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.agreementDetailView,
      arguments: AgreementDetailViewArguments(key: key, agreement: agreement),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithVehicleDetailView({
    _i35.Key? key,
    required _i46.Vehicle vehicle,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.vehicleDetailView,
      arguments: VehicleDetailViewArguments(key: key, vehicle: vehicle),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithStaffAccessView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.staffAccessView,
      arguments: StaffAccessViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithBusinessProfileView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.businessProfileView,
      arguments: BusinessProfileViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithReportsView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.reportsView,
      arguments: ReportsViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithReportDetailView({
    _i35.Key? key,
    required _i47.ReportType type,
    required _i39.Period period,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.reportDetailView,
      arguments: ReportDetailViewArguments(
        key: key,
        type: type,
        period: period,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithPdfPreviewView({
    required String title,
    required _i48.Future<_i49.Uint8List> Function() build,
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.pdfPreviewView,
      arguments: PdfPreviewViewArguments(title: title, build: build, key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithForgotPasswordView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.forgotPasswordView,
      arguments: ForgotPasswordViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithResetPasswordView({
    _i35.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.resetPasswordView,
      arguments: ResetPasswordViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithAcceptInvitationView({
    _i35.Key? key,
    required String email,
    required String businessName,
    required List<_i50.AccessPack> accessPacks,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.acceptInvitationView,
      arguments: AcceptInvitationViewArguments(
        key: key,
        email: email,
        businessName: businessName,
        accessPacks: accessPacks,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithAccessUnavailableView({
    _i35.Key? key,
    required String title,
    required String message,
    bool showRetry = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.accessUnavailableView,
      arguments: AccessUnavailableViewArguments(
        key: key,
        title: title,
        message: message,
        showRetry: showRetry,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }
}
