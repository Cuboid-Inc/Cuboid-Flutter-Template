export './enums_extentions.dart';

enum PartyType { customer, supplier }

enum VehicleOwnership { owned, external }

enum VehicleSource { owned, supplier }

enum WorkStatus { planned, completed, canceled, billed }

enum WorkType { perTrip, monthlyExtra }

enum InvoiceStatus { draft, issued, partPaid, paid, voided }

enum SettlementStatus { draft, issued, partPaid, paid, voided }

enum PaymentDirection { incoming, outgoing }

enum PaymentMethod { cash, bankTransfer, cheque }

enum ChequeState { received, cleared, bounced }

enum RateModel { monthly, perTrip }

enum InvoiceGrouping { perWork, monthlyConsolidated }

enum Responsibility { operator, customer }

enum StaffRole { owner, staff }

enum StaffStatus { invited, active, suspended }

enum AccessPack { operations, masterData, money, reports }

enum ExpenseCategory {
  driverPay,
  fuel,
  maintenance,
  toll,
  parking,
  gatePass,
  vehicleRent,
  other,
}

enum MoneySegment {
  invoices,
  statements,
  settlements,
  payments,
  expenses,
  balances,
}

enum MonthlyExtraType {
  overtime,
  extraDay,
  extraTrip,
  nightShift,
  sundayWork,
  parking,
  custom,
}

enum PaymentTerms { onReceipt, net7, net15, net30, net45, net60 }

enum VehicleClass {
  threeTon,
  sevenTon,
  tenTon,
  flatbed,
  thirtySeatBus,
  trailer,
  pickup,
  custom,
}
