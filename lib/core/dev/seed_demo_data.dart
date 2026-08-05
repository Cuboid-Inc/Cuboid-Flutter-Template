// ponytail: dev-only seeder for the local Supabase reset cycle. Delete this
// file and its Home button once real data entry replaces it.
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/core/models/expense.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/route_rate.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/money.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/agreement_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/driver_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/route_rate_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';

/// Seeds detailed master, work, and historical money data through the same
/// repositories used by the UI.
Future<String> seedDemoData() async {
  final parties = locator<PartiesRepository>();
  final vehicleRepo = locator<VehicleRepository>();
  final driverRepo = locator<DriverRepository>();
  final routeRateRepo = locator<RouteRateRepository>();
  final agreementRepo = locator<AgreementRepository>();
  final workRepo = locator<WorkRepository>();
  final moneyRepo = locator<MoneyRepository>();

  Future<T> save<T>(String what, Future<Result<T>> operation) async =>
      switch (await operation) {
        Success(:final value) => value,
        Failure(:final failure) => throw StateError(
          'Seed failed at $what: $failure',
        ),
      };

  final now = DateTime.now();
  DateTime date(int daysFromToday) {
    final value = now.add(Duration(days: daysFromToday));
    return DateTime(value.year, value.month, value.day);
  }

  final partyDefs = [
    Party(
      id: '',
      name: 'Al Futtaim Logistics',
      type: PartyType.customer,
      address: 'Dubai Investment Park 2',
      city: 'Dubai',
      trn: '100234567800003',
      contactPerson: 'Nadia Rahman',
      phone: '+971 50 410 1101',
      email: 'accounts@alfuttaim-logistics.demo',
      paymentTerms: PaymentTerms.net30,
      notes: 'Monthly fleet and spot delivery customer.',
    ),
    Party(
      id: '',
      name: 'Gulf Retail Group',
      type: PartyType.customer,
      address: 'Ras Al Khor Industrial Area 2',
      city: 'Dubai',
      trn: '100345678900003',
      contactPerson: 'Sameer Khan',
      phone: '+971 55 420 2202',
      email: 'finance@gulfretail.demo',
      paymentTerms: PaymentTerms.net15,
      notes: 'Retail replenishment and weekend runs.',
    ),
    Party(
      id: '',
      name: 'Skyline Events UAE',
      type: PartyType.customer,
      address: 'Al Quoz Industrial Area 3',
      city: 'Dubai',
      trn: '100456789000003',
      contactPerson: 'Lina Joseph',
      phone: '+971 52 430 3303',
      email: 'operations@skylineevents.demo',
      paymentTerms: PaymentTerms.net7,
      notes: 'Event transport with evening and weekend work.',
    ),
    Party(
      id: '',
      name: 'Desert Rentals LLC',
      type: PartyType.supplier,
      address: 'Industrial Area 10',
      city: 'Sharjah',
      trn: '100567890100003',
      contactPerson: 'Tariq Mehmood',
      phone: '+971 56 440 4404',
      email: 'billing@desertrentals.demo',
      paymentTerms: PaymentTerms.net15,
      notes: 'External trailers and relief drivers.',
    ),
    Party(
      id: '',
      name: 'Emirates Haulage Co',
      type: PartyType.supplier,
      address: 'Mussafah M-14',
      city: 'Abu Dhabi',
      trn: '100678901200003',
      contactPerson: 'Omar Farooq',
      phone: '+971 50 450 5505',
      email: 'accounts@emirateshaulage.demo',
      paymentTerms: PaymentTerms.net30,
      notes: 'External trucks for inter-emirate work.',
    ),
    Party(
      id: '',
      name: 'Falcon Fuel Services',
      type: PartyType.supplier,
      address: 'Jebel Ali Industrial Area 1',
      city: 'Dubai',
      trn: '100789012300003',
      contactPerson: 'Adeel Hussain',
      phone: '+971 54 460 6606',
      email: 'fleetcards@falconfuel.demo',
      paymentTerms: PaymentTerms.net30,
      notes: 'Fleet fuel card supplier.',
    ),
    Party(
      id: '',
      name: 'City Fleet Workshop',
      type: PartyType.supplier,
      address: 'Al Qusais Industrial Area 4',
      city: 'Dubai',
      trn: '100890123400003',
      contactPerson: 'Bilal Ahmed',
      phone: '+971 58 470 7707',
      email: 'service@cityfleetworkshop.demo',
      paymentTerms: PaymentTerms.net15,
      notes: 'Scheduled servicing, tyres, and repairs.',
    ),
  ];
  final savedParties = <Party>[];
  for (final party in partyDefs) {
    savedParties.add(await save('party ${party.name}', parties.create(party)));
  }
  final customerIds = savedParties.take(3).map((party) => party.id).toList();
  final supplierIds = savedParties.skip(3).map((party) => party.id).toList();

  final vehicleDefs = [
    Vehicle(
      id: '',
      plateNumber: 'DXB-A-11001',
      label: 'Flatbed 01',
      vehicleClass: VehicleClass.flatbed,
      ownership: VehicleOwnership.owned,
      make: 'Hino',
      model: '500',
      year: 2022,
      registrationExpiry: date(210),
      insuranceExpiry: date(165),
      inspectionExpiry: date(120),
      notes: 'Primary long-route flatbed.',
    ),
    Vehicle(
      id: '',
      plateNumber: 'DXB-A-11002',
      label: 'Ten Ton 01',
      vehicleClass: VehicleClass.tenTon,
      ownership: VehicleOwnership.owned,
      make: 'Isuzu',
      model: 'FVR',
      year: 2021,
      registrationExpiry: date(145),
      insuranceExpiry: date(95),
      inspectionExpiry: date(60),
      notes: 'Retail and warehouse deliveries.',
    ),
    Vehicle(
      id: '',
      plateNumber: 'DXB-A-11003',
      label: 'Pickup 01',
      vehicleClass: VehicleClass.pickup,
      ownership: VehicleOwnership.owned,
      make: 'Toyota',
      model: 'Hilux',
      year: 2023,
      registrationExpiry: date(280),
      insuranceExpiry: date(240),
      inspectionExpiry: date(185),
      notes: 'Small deliveries and site support.',
    ),
    Vehicle(
      id: '',
      plateNumber: 'SHJ-B-22004',
      label: 'Trailer 01 External',
      vehicleClass: VehicleClass.trailer,
      ownership: VehicleOwnership.external,
      supplierId: supplierIds[0],
      make: 'MAN',
      model: 'TGX',
      year: 2020,
      registrationExpiry: date(80),
      insuranceExpiry: date(45),
      notes: 'Desert Rentals trailer and tractor unit.',
    ),
    Vehicle(
      id: '',
      plateNumber: 'DXB-C-33005',
      label: 'Seven Ton 01',
      vehicleClass: VehicleClass.sevenTon,
      ownership: VehicleOwnership.owned,
      make: 'Mitsubishi Fuso',
      model: 'Fighter',
      year: 2022,
      registrationExpiry: date(190),
      insuranceExpiry: date(155),
      inspectionExpiry: date(100),
      notes: 'Backup vehicle for retail routes.',
    ),
    Vehicle(
      id: '',
      plateNumber: 'DXB-D-44006',
      label: 'Staff Bus 01',
      vehicleClass: VehicleClass.thirtySeatBus,
      ownership: VehicleOwnership.owned,
      make: 'Ashok Leyland',
      model: 'Oyster',
      year: 2021,
      registrationExpiry: date(135),
      insuranceExpiry: date(110),
      inspectionExpiry: date(75),
      notes: 'Thirty-seat staff and event transport.',
    ),
    Vehicle(
      id: '',
      plateNumber: 'AUH-E-55007',
      label: 'Three Ton 01 External',
      vehicleClass: VehicleClass.threeTon,
      ownership: VehicleOwnership.external,
      supplierId: supplierIds[1],
      make: 'Isuzu',
      model: 'NPR',
      year: 2020,
      registrationExpiry: date(70),
      insuranceExpiry: date(35),
      notes: 'Emirates Haulage overflow vehicle.',
    ),
  ];
  final savedVehicles = <Vehicle>[];
  for (final vehicle in vehicleDefs) {
    savedVehicles.add(
      await save('vehicle ${vehicle.label}', vehicleRepo.addVehicle(vehicle)),
    );
  }

  final driverDefs = [
    Driver(
      id: '',
      name: 'Rashid Al Marri',
      phone: '+971 50 510 1001',
      licenceNumber: 'DXB-L-41001',
      licenceExpiry: date(430),
      identityReference: '784-1988-4100101-1',
      identityExpiry: date(610),
      notes: 'Flatbed and ten-ton qualified.',
    ),
    Driver(
      id: '',
      name: 'Faisal Noor',
      phone: '+971 55 520 2002',
      licenceNumber: 'DXB-L-41002',
      licenceExpiry: date(260),
      identityReference: '784-1990-4100202-2',
      identityExpiry: date(520),
      notes: 'Pickup and city delivery routes.',
    ),
    Driver(
      id: '',
      name: 'Imran Sheikh',
      phone: '+971 52 530 3003',
      licenceNumber: 'DXB-L-41003',
      licenceExpiry: date(330),
      identityReference: '784-1987-4100303-3',
      identityExpiry: date(480),
      notes: 'Long-haul relief driver.',
    ),
    Driver(
      id: '',
      name: 'Waleed Hassan',
      phone: '+971 56 540 4004',
      licenceNumber: 'DXB-L-41004',
      licenceExpiry: date(180),
      identityReference: '784-1992-4100404-4',
      identityExpiry: date(390),
      notes: 'Seven-ton and warehouse deliveries.',
    ),
    Driver(
      id: '',
      name: 'Omar Saeed',
      phone: '+971 50 550 5005',
      licenceNumber: 'AUH-L-51005',
      licenceExpiry: date(220),
      identityReference: '784-1989-5100505-5',
      identityExpiry: date(450),
      supplierId: supplierIds[1],
      notes: 'Emirates Haulage supplied driver.',
    ),
    Driver(
      id: '',
      name: 'Arun Mathew',
      phone: '+971 54 560 6006',
      licenceNumber: 'DXB-L-41006',
      licenceExpiry: date(370),
      identityReference: '784-1991-4100606-6',
      identityExpiry: date(570),
      notes: 'Bus and passenger transport qualified.',
    ),
    Driver(
      id: '',
      name: 'Khalid Mahmood',
      phone: '+971 58 570 7007',
      licenceNumber: 'DXB-L-41007',
      licenceExpiry: date(290),
      identityReference: '784-1986-4100707-7',
      identityExpiry: date(505),
      notes: 'Bus relief and event shift driver.',
    ),
    Driver(
      id: '',
      name: 'Sajid Ali',
      phone: '+971 52 580 8008',
      licenceNumber: 'SHJ-L-61008',
      licenceExpiry: date(150),
      identityReference: '784-1985-6100808-8',
      identityExpiry: date(345),
      supplierId: supplierIds[0],
      notes: 'Desert Rentals trailer driver.',
    ),
  ];
  final savedDrivers = <Driver>[];
  for (final driver in driverDefs) {
    savedDrivers.add(
      await save('driver ${driver.name}', driverRepo.addDriver(driver)),
    );
  }

  final routeDefs = [
    RouteRate(
      id: '',
      appliesTo: 'Dubai to Abu Dhabi',
      pickup: 'Dubai',
      destination: 'Abu Dhabi',
      vehicleClass: VehicleClass.tenTon,
      rate: 950,
      defaultExtras: {'Gate pass': 75, 'Waiting hour': 90},
    ),
    RouteRate(
      id: '',
      appliesTo: 'Dubai to Sharjah',
      pickup: 'Dubai',
      destination: 'Sharjah',
      vehicleClass: VehicleClass.pickup,
      rate: 250,
      defaultExtras: {'Waiting hour': 60},
    ),
    RouteRate(
      id: '',
      appliesTo: 'Dubai to Al Ain',
      pickup: 'Dubai',
      destination: 'Al Ain',
      vehicleClass: VehicleClass.flatbed,
      rate: 1200,
      defaultExtras: {'Gate pass': 75, 'Overnight': 350},
    ),
    RouteRate(
      id: '',
      appliesTo: 'Dubai to Fujairah',
      pickup: 'Dubai',
      destination: 'Fujairah',
      vehicleClass: VehicleClass.trailer,
      rate: 1400,
      defaultExtras: {'Waiting hour': 100, 'Gate pass': 90},
    ),
    RouteRate(
      id: '',
      appliesTo: 'Dubai to Ras Al Khaimah',
      pickup: 'Dubai',
      destination: 'Ras Al Khaimah',
      vehicleClass: VehicleClass.sevenTon,
      rate: 1050,
      defaultExtras: {'Waiting hour': 80},
    ),
    RouteRate(
      id: '',
      appliesTo: 'Dubai local event shuttle',
      pickup: 'Dubai',
      destination: 'Dubai',
      vehicleClass: VehicleClass.thirtySeatBus,
      rate: 1800,
      defaultExtras: {'Night shift': 450, 'Sunday work': 350},
    ),
    RouteRate(
      id: '',
      appliesTo: 'Abu Dhabi to Dubai',
      pickup: 'Abu Dhabi',
      destination: 'Dubai',
      vehicleClass: VehicleClass.threeTon,
      rate: 1100,
      defaultExtras: {'Gate pass': 75},
    ),
  ];
  for (final route in routeDefs) {
    await save('route ${route.appliesTo}', routeRateRepo.addRouteRate(route));
  }

  final agreementDefs = [
    Agreement(
      id: '',
      reference: 'AGR-AFL-001',
      name: 'Al Futtaim Monthly Fleet',
      customerId: customerIds[0],
      rateModel: RateModel.monthly,
      startDate: date(-365),
      endDate: date(365),
      invoiceGrouping: InvoiceGrouping.monthlyConsolidated,
      baseRate: 45000,
      dutyDays: 26,
      includedHours: 10,
      overtimeRate: 85,
      extraDayRate: 1750,
      extraTripRate: 650,
      defaultVehicleId: savedVehicles[0].id,
      purchaseOrderReference: 'PO-AFL-2026-014',
      paymentTerms: PaymentTerms.net30,
      notes: 'Flatbed with operator, fuel, and maintenance included.',
      defaultExtras: {'Night shift': 500, 'Parking': 100},
    ),
    Agreement(
      id: '',
      reference: 'AGR-AFL-002',
      name: 'Al Futtaim Spot Trips',
      customerId: customerIds[0],
      rateModel: RateModel.perTrip,
      startDate: date(-400),
      endDate: date(330),
      defaultVehicleId: savedVehicles[1].id,
      purchaseOrderReference: 'PO-AFL-SPOT-09',
      paymentTerms: PaymentTerms.net30,
      notes: 'Rates follow the route card plus approved extras.',
    ),
    Agreement(
      id: '',
      reference: 'AGR-GRG-001',
      name: 'Gulf Retail Monthly Fleet',
      customerId: customerIds[1],
      rateModel: RateModel.monthly,
      startDate: date(-420),
      endDate: date(310),
      invoiceGrouping: InvoiceGrouping.monthlyConsolidated,
      baseRate: 38000,
      dutyDays: 26,
      includedHours: 10,
      overtimeRate: 75,
      extraDayRate: 1450,
      extraTripRate: 500,
      defaultVehicleId: savedVehicles[4].id,
      purchaseOrderReference: 'GRG-PO-7781',
      paymentTerms: PaymentTerms.net15,
      notes: 'Seven-ton retail replenishment contract.',
      defaultExtras: {'Sunday work': 400, 'Parking': 75},
    ),
    Agreement(
      id: '',
      reference: 'AGR-GRG-002',
      name: 'Gulf Retail Weekend Runs',
      customerId: customerIds[1],
      rateModel: RateModel.perTrip,
      startDate: date(-390),
      endDate: date(300),
      defaultVehicleId: savedVehicles[2].id,
      paymentTerms: PaymentTerms.net15,
      notes: 'Pickup deliveries on Fridays and weekends.',
    ),
    Agreement(
      id: '',
      reference: 'AGR-AFL-003',
      name: 'Al Futtaim Seasonal Add-on',
      customerId: customerIds[0],
      rateModel: RateModel.monthly,
      startDate: date(-210),
      endDate: date(120),
      baseRate: 15000,
      dutyDays: 12,
      includedHours: 8,
      overtimeRate: 75,
      extraDayRate: 900,
      extraTripRate: 450,
      defaultVehicleId: savedVehicles[2].id,
      paymentTerms: PaymentTerms.net30,
      notes: 'Seasonal overflow pickup allocation.',
    ),
    Agreement(
      id: '',
      reference: 'AGR-GRG-003',
      name: 'Gulf Retail Ad-hoc Trips',
      customerId: customerIds[1],
      rateModel: RateModel.perTrip,
      startDate: date(-330),
      endDate: date(365),
      defaultVehicleId: savedVehicles[6].id,
      paymentTerms: PaymentTerms.net15,
      notes: 'Overflow routes use approved external vehicles.',
    ),
    Agreement(
      id: '',
      reference: 'AGR-SKY-001',
      name: 'Skyline Event Transport',
      customerId: customerIds[2],
      rateModel: RateModel.perTrip,
      startDate: date(-300),
      endDate: date(240),
      defaultVehicleId: savedVehicles[5].id,
      purchaseOrderReference: 'SKY-EVENTS-26',
      paymentTerms: PaymentTerms.net7,
      notes: 'Event shuttles billed per movement and shift.',
    ),
    Agreement(
      id: '',
      reference: 'AGR-GRG-004',
      name: 'Gulf Retail Staff Shuttle',
      customerId: customerIds[1],
      rateModel: RateModel.monthly,
      startDate: date(-250),
      endDate: date(365),
      invoiceGrouping: InvoiceGrouping.monthlyConsolidated,
      baseRate: 26000,
      dutyDays: 26,
      includedHours: 12,
      overtimeRate: 65,
      extraDayRate: 1100,
      extraTripRate: 300,
      defaultVehicleId: savedVehicles[5].id,
      purchaseOrderReference: 'GRG-HR-2026-11',
      paymentTerms: PaymentTerms.net15,
      notes: 'Daily staff transport between accommodation and warehouse.',
    ),
    Agreement(
      id: '',
      reference: 'AGR-AFL-004',
      name: 'Al Futtaim Cross-emirate Trips',
      customerId: customerIds[0],
      rateModel: RateModel.perTrip,
      startDate: date(-280),
      endDate: date(365),
      defaultVehicleId: savedVehicles[0].id,
      purchaseOrderReference: 'AFL-LH-2026-08',
      paymentTerms: PaymentTerms.net30,
      notes: 'Long-haul flatbed and trailer movements.',
    ),
  ];
  final savedAgreements = <Agreement>[];
  for (final agreement in agreementDefs) {
    savedAgreements.add(
      await save(
        'agreement ${agreement.name}',
        agreementRepo.addAgreement(agreement),
      ),
    );
  }

  final workDefs = <(WorkOrder, bool)>[
    (
      WorkOrder(
        id: '',
        number: '',
        customerId: customerIds[0],
        agreementId: savedAgreements[1].id,
        date: date(-330),
        pickup: 'Dubai Investment Park',
        destination: 'Mussafah, Abu Dhabi',
        plannedStart: date(-330).add(const Duration(hours: 6)),
        plannedEnd: date(-330).add(const Duration(hours: 15)),
        customerJobReference: 'AFL-JOB-24018',
        description: 'Ten-ton warehouse transfer.',
        allocations: [
          VehicleAllocation(
            vehicleId: savedVehicles[1].id,
            driverId: savedDrivers[0].id,
            notes: 'Report to gate 3 before loading.',
          ),
        ],
        chargeLines: const [
          ChargeLine(
            name: 'Dubai to Abu Dhabi trip',
            description: 'Ten-ton vehicle with driver.',
            unitPrice: 950,
          ),
          ChargeLine(name: 'Gate pass', unitPrice: 75),
        ],
        notes: 'POD received from customer warehouse.',
      ),
      true,
    ),
    (
      WorkOrder(
        id: '',
        number: '',
        customerId: customerIds[1],
        agreementId: savedAgreements[3].id,
        date: date(-300),
        pickup: 'Ras Al Khor Warehouse',
        destination: 'Sharjah City Centre',
        plannedStart: date(-300).add(const Duration(hours: 7)),
        plannedEnd: date(-300).add(const Duration(hours: 11)),
        customerJobReference: 'GRG-WE-8821',
        description: 'Weekend retail replenishment.',
        allocations: [
          VehicleAllocation(
            vehicleId: savedVehicles[2].id,
            driverId: savedDrivers[1].id,
          ),
        ],
        chargeLines: const [
          ChargeLine(name: 'Dubai to Sharjah trip', unitPrice: 250),
          ChargeLine(name: 'Waiting', quantity: 2, unitPrice: 60, unit: 'hour'),
        ],
        notes: 'Two-hour unloading wait approved by store manager.',
      ),
      true,
    ),
    (
      WorkOrder(
        id: '',
        number: '',
        customerId: customerIds[0],
        agreementId: savedAgreements[8].id,
        date: date(-260),
        pickup: 'Jebel Ali Free Zone',
        destination: 'Al Ain Industrial Area',
        plannedStart: date(-260).add(const Duration(hours: 5)),
        plannedEnd: date(-260).add(const Duration(hours: 18)),
        customerJobReference: 'AFL-LH-24102',
        description: 'Machinery movement on flatbed.',
        allocations: [
          VehicleAllocation(
            vehicleId: savedVehicles[0].id,
            driverId: savedDrivers[2].id,
            notes: 'Load secured with four ratchet straps.',
          ),
        ],
        chargeLines: const [
          ChargeLine(name: 'Dubai to Al Ain trip', unitPrice: 1200),
          ChargeLine(name: 'Overnight allowance', unitPrice: 350),
        ],
        notes: 'Security clearance attached to customer job.',
      ),
      true,
    ),
    (
      WorkOrder(
        id: '',
        number: '',
        customerId: customerIds[2],
        agreementId: savedAgreements[6].id,
        date: date(-220),
        pickup: 'Al Quoz Equipment Yard',
        destination: 'Yas Conference Centre',
        plannedStart: date(-220).add(const Duration(hours: 10)),
        plannedEnd: date(-219).add(const Duration(hours: 1)),
        customerJobReference: 'SKY-EVT-1088',
        description: 'Guest and crew shuttle for conference setup.',
        allocations: [
          VehicleAllocation(
            vehicleId: savedVehicles[5].id,
            driverId: savedDrivers[5].id,
          ),
        ],
        chargeLines: const [
          ChargeLine(name: 'Event shuttle shift', quantity: 2, unitPrice: 1800),
          ChargeLine(name: 'Night shift', unitPrice: 450),
        ],
        notes: 'Final passenger manifest confirmed.',
      ),
      true,
    ),
    (
      WorkOrder(
        id: '',
        number: '',
        customerId: customerIds[1],
        agreementId: savedAgreements[7].id,
        date: date(-180),
        pickup: 'Muhaisnah Staff Accommodation',
        destination: 'Ras Al Khor Warehouse',
        workType: WorkType.monthlyExtra,
        customerJobReference: 'GRG-HR-M01',
        description: 'Monthly staff shuttle service.',
        allocations: [
          VehicleAllocation(
            vehicleId: savedVehicles[5].id,
            driverId: savedDrivers[6].id,
          ),
        ],
        chargeLines: const [
          ChargeLine(name: 'Monthly staff shuttle', unitPrice: 26000),
          ChargeLine(
            name: 'Extra day',
            quantity: 2,
            unitPrice: 1100,
            unit: 'day',
          ),
        ],
        notes: 'Monthly attendance sheet approved by HR.',
      ),
      true,
    ),
    (
      WorkOrder(
        id: '',
        number: '',
        customerId: customerIds[0],
        agreementId: savedAgreements[8].id,
        date: date(-145),
        pickup: 'Dubai South Logistics District',
        destination: 'Fujairah Port',
        plannedStart: date(-145).add(const Duration(hours: 4)),
        plannedEnd: date(-145).add(const Duration(hours: 17)),
        customerJobReference: 'AFL-LH-24276',
        description: 'Container chassis movement to port.',
        allocations: [
          VehicleAllocation(
            vehicleId: savedVehicles[3].id,
            driverId: savedDrivers[7].id,
            source: VehicleSource.supplier,
            supplierId: supplierIds[0],
            supplierPayable: 900,
            notes: 'Desert Rentals rate includes driver and fuel.',
          ),
        ],
        chargeLines: const [
          ChargeLine(name: 'Dubai to Fujairah trailer trip', unitPrice: 1400),
          ChargeLine(name: 'Port gate pass', unitPrice: 90),
        ],
        notes: 'External vehicle documents checked before dispatch.',
      ),
      true,
    ),
    (
      WorkOrder(
        id: '',
        number: '',
        customerId: customerIds[1],
        agreementId: savedAgreements[5].id,
        date: date(-100),
        pickup: 'Mussafah Distribution Centre',
        destination: 'Dubai Festival City',
        plannedStart: date(-100).add(const Duration(hours: 5)),
        plannedEnd: date(-100).add(const Duration(hours: 14)),
        customerJobReference: 'GRG-ADHOC-921',
        description: 'Urgent stock transfer from Abu Dhabi.',
        allocations: [
          VehicleAllocation(
            vehicleId: savedVehicles[6].id,
            driverId: savedDrivers[4].id,
            source: VehicleSource.supplier,
            supplierId: supplierIds[1],
            supplierPayable: 650,
            notes: 'External three-ton vehicle.',
          ),
        ],
        chargeLines: const [
          ChargeLine(name: 'Abu Dhabi to Dubai trip', unitPrice: 1100),
          ChargeLine(name: 'Gate pass', unitPrice: 75),
        ],
        notes: 'Delivery completed before store opening.',
      ),
      true,
    ),
    (
      WorkOrder(
        id: '',
        number: '',
        customerId: customerIds[0],
        agreementId: savedAgreements[0].id,
        date: date(-70),
        pickup: 'Monthly hire',
        destination: 'Al Futtaim Logistics sites',
        workType: WorkType.monthlyExtra,
        customerJobReference: 'AFL-MONTH-05',
        description: 'Monthly flatbed hire with approved overtime.',
        allocations: [
          VehicleAllocation(
            vehicleId: savedVehicles[0].id,
            driverId: savedDrivers[0].id,
          ),
        ],
        chargeLines: const [
          ChargeLine(name: 'Monthly hire', unitPrice: 45000),
          ChargeLine(
            name: 'Overtime',
            quantity: 8,
            unitPrice: 85,
            unit: 'hour',
          ),
          ChargeLine(name: 'Parking', unitPrice: 100),
        ],
        notes: 'Timesheet and parking receipts approved.',
      ),
      true,
    ),
    (
      WorkOrder(
        id: '',
        number: '',
        customerId: customerIds[2],
        agreementId: savedAgreements[6].id,
        date: date(-40),
        pickup: 'Dubai World Trade Centre',
        destination: 'Expo City Dubai',
        plannedStart: date(-40).add(const Duration(hours: 8)),
        plannedEnd: date(-39).add(const Duration(hours: 1)),
        customerJobReference: 'SKY-EVT-1314',
        description: 'Two-shift event shuttle operation.',
        allocations: [
          VehicleAllocation(
            vehicleId: savedVehicles[5].id,
            driverId: savedDrivers[5].id,
          ),
          VehicleAllocation(
            vehicleId: savedVehicles[4].id,
            driverId: savedDrivers[3].id,
            notes: 'Seven-ton carried event equipment.',
          ),
        ],
        chargeLines: const [
          ChargeLine(name: 'Event shuttle shift', quantity: 3, unitPrice: 1800),
          ChargeLine(name: 'Equipment vehicle', unitPrice: 1050),
          ChargeLine(name: 'Night shift', unitPrice: 450),
        ],
        notes: 'Passenger and equipment movements completed.',
      ),
      true,
    ),
    (
      WorkOrder(
        id: '',
        number: '',
        customerId: customerIds[1],
        agreementId: savedAgreements[3].id,
        date: date(-15),
        pickup: 'Ras Al Khor Warehouse',
        destination: 'Dubai Marina Store',
        plannedStart: date(-15).add(const Duration(hours: 6)),
        plannedEnd: date(-15).add(const Duration(hours: 10)),
        customerJobReference: 'GRG-WE-9940',
        description: 'Early morning retail replenishment.',
        allocations: [
          VehicleAllocation(
            vehicleId: savedVehicles[2].id,
            driverId: savedDrivers[1].id,
          ),
        ],
        chargeLines: const [
          ChargeLine(name: 'Dubai local pickup run', unitPrice: 250),
          ChargeLine(name: 'Parking', unitPrice: 50),
        ],
        notes: 'Signed delivery note received.',
      ),
      true,
    ),
    (
      WorkOrder(
        id: '',
        number: '',
        customerId: customerIds[0],
        agreementId: savedAgreements[1].id,
        date: date(-3),
        pickup: 'Dubai Investment Park',
        destination: 'Abu Dhabi Airport Free Zone',
        plannedStart: date(-3).add(const Duration(hours: 6)),
        plannedEnd: date(-3).add(const Duration(hours: 16)),
        customerJobReference: 'AFL-JOB-26044',
        description: 'Planned ten-ton airport delivery.',
        allocations: [
          VehicleAllocation(
            vehicleId: savedVehicles[1].id,
            driverId: savedDrivers[2].id,
          ),
        ],
        chargeLines: const [
          ChargeLine(name: 'Dubai to Abu Dhabi trip', unitPrice: 950),
          ChargeLine(name: 'Airport gate pass', unitPrice: 125),
        ],
        notes: 'Awaiting final security slot.',
      ),
      false,
    ),
    (
      WorkOrder(
        id: '',
        number: '',
        customerId: customerIds[2],
        agreementId: savedAgreements[6].id,
        date: date(2),
        pickup: 'Al Quoz Equipment Yard',
        destination: 'Dubai Harbour',
        plannedStart: date(2).add(const Duration(hours: 14)),
        plannedEnd: date(3).add(const Duration(hours: 1)),
        customerJobReference: 'SKY-EVT-1402',
        description: 'Upcoming evening event shuttle.',
        allocations: [
          VehicleAllocation(
            vehicleId: savedVehicles[5].id,
            driverId: savedDrivers[6].id,
          ),
        ],
        chargeLines: const [
          ChargeLine(name: 'Event shuttle shift', unitPrice: 1800),
          ChargeLine(name: 'Night shift', unitPrice: 450),
        ],
        notes: 'Driver and bus assigned.',
      ),
      false,
    ),
  ];
  final workOrders = <WorkOrder>[];
  for (final (definition, shouldComplete) in workDefs) {
    final created = await save(
      'work order ${definition.customerJobReference}',
      workRepo.create(definition),
    );
    workOrders.add(
      shouldComplete
          ? await save(
              'complete ${created.number}',
              workRepo.complete(created.id),
            )
          : created,
    );
  }

  final partyById = {for (final party in savedParties) party.id: party};
  final invoices = <Invoice>[];
  for (final work in workOrders.take(10)) {
    final buyer = partyById[work.customerId]!;
    final issueDate = work.date.add(const Duration(days: 2));
    invoices.add(
      await save(
        'invoice for ${work.number}',
        moneyRepo.issueInvoice(
          Invoice(
            id: '',
            number: '',
            buyerId: buyer.id,
            buyerName: buyer.name,
            buyerAddress: '${buyer.address}, ${buyer.city}, ${buyer.country}',
            buyerTrn: buyer.trn,
            buyerContact: '${buyer.contactPerson}, ${buyer.email}',
            paymentTerms: buyer.paymentTerms.label,
            issueDate: issueDate,
            dueDate: issueDate.add(
              Duration(
                days: switch (buyer.paymentTerms) {
                  PaymentTerms.net7 => 7,
                  PaymentTerms.net15 => 15,
                  PaymentTerms.net30 => 30,
                  PaymentTerms.net45 => 45,
                  PaymentTerms.net60 => 60,
                  PaymentTerms.onReceipt => 0,
                },
              ),
            ),
            supplyDate: work.date,
            linkedWorkOrderIds: [work.id],
            lines: [
              for (final line in work.chargeLines)
                InvoiceLine(
                  name: line.name,
                  description: line.description,
                  quantity: line.quantity,
                  unitPrice: line.unitPrice,
                  unit: line.unit,
                  discount: line.discount,
                  vatRate: line.vatRate,
                ),
            ],
          ),
        ),
      ),
    );
  }

  final settlements = <SupplierSettlement>[];
  for (final (workIndex, supplierIndex) in [(5, 0), (6, 1)]) {
    final work = workOrders[workIndex];
    final allocation = work.allocations.first;
    settlements.add(
      await save(
        'settlement for ${work.number}',
        moneyRepo.issueSettlement(
          SupplierSettlement(
            id: '',
            number: '',
            supplierId: supplierIds[supplierIndex],
            periodStart: work.date,
            periodEnd: work.date,
            lines: [
              SettlementLine(
                workOrderId: work.id,
                date: work.date,
                amount: allocation.supplierPayable,
                customerName: partyById[work.customerId]!.name,
                vehicleId: allocation.vehicleId,
                driverId: allocation.driverId,
                route: work.route,
              ),
            ],
          ),
        ),
      ),
    );
  }

  final expenseDefs = <(Expense, String?, bool)>[
    (
      Expense(
        id: '',
        date: date(-335),
        category: ExpenseCategory.fuel,
        payee: savedParties[5].name,
        net: 4850,
        vat: 242.50,
        vehicleId: savedVehicles[1].id,
        workOrderId: workOrders[0].id,
        description: 'Monthly diesel fleet card statement.',
        dueDate: date(-305),
        reference: 'FFS-2408-1182',
        notes: 'Includes Abu Dhabi trip fuel.',
      ),
      supplierIds[2],
      true,
    ),
    (
      Expense(
        id: '',
        date: date(-302),
        category: ExpenseCategory.driverPay,
        payee: savedDrivers[1].name,
        net: 7200,
        driverId: savedDrivers[1].id,
        workOrderId: workOrders[1].id,
        description: 'Monthly salary and weekend trip allowance.',
        dueDate: date(-298),
        reference: 'PAY-DRV-2409-02',
        notes: 'Paid through payroll cash account.',
      ),
      null,
      true,
    ),
    (
      Expense(
        id: '',
        date: date(-270),
        category: ExpenseCategory.maintenance,
        payee: savedParties[6].name,
        net: 12800,
        vat: 640,
        vehicleId: savedVehicles[0].id,
        description: 'Major service, brake pads, and two tyres.',
        dueDate: date(-255),
        reference: 'CFW-2410-447',
        notes: 'Preventive maintenance before Al Ain movement.',
      ),
      supplierIds[3],
      true,
    ),
    (
      Expense(
        id: '',
        date: date(-223),
        category: ExpenseCategory.parking,
        payee: 'Yas Conference Centre Parking',
        net: 380,
        vat: 19,
        vehicleId: savedVehicles[5].id,
        driverId: savedDrivers[5].id,
        workOrderId: workOrders[3].id,
        description: 'Event bus parking and access.',
        reference: 'PARK-YAS-1088',
        notes: 'Receipt attached to event paperwork.',
      ),
      null,
      true,
    ),
    (
      Expense(
        id: '',
        date: date(-188),
        category: ExpenseCategory.fuel,
        payee: savedParties[5].name,
        net: 7325,
        vat: 366.25,
        vehicleId: savedVehicles[5].id,
        description: 'Bus fuel statement for staff shuttle month.',
        dueDate: date(-158),
        reference: 'FFS-2501-1550',
        notes: 'Matched against vehicle fuel card log.',
      ),
      supplierIds[2],
      true,
    ),
    (
      Expense(
        id: '',
        date: date(-146),
        category: ExpenseCategory.vehicleRent,
        payee: savedParties[3].name,
        net: 18000,
        vat: 900,
        vehicleId: savedVehicles[3].id,
        workOrderId: workOrders[5].id,
        description: 'Trailer monthly hire and Fujairah dispatch.',
        dueDate: date(-131),
        reference: 'DRL-2502-778',
        notes: 'Work order supplier payable settled separately.',
      ),
      supplierIds[0],
      true,
    ),
    (
      Expense(
        id: '',
        date: date(-103),
        category: ExpenseCategory.vehicleRent,
        payee: savedParties[4].name,
        net: 9650,
        vat: 482.50,
        vehicleId: savedVehicles[6].id,
        driverId: savedDrivers[4].id,
        workOrderId: workOrders[6].id,
        description: 'External three-ton hire and driver services.',
        dueDate: date(-73),
        reference: 'EHC-2504-209',
        notes: 'Includes standby charge for urgent dispatch.',
      ),
      supplierIds[1],
      true,
    ),
    (
      Expense(
        id: '',
        date: date(-72),
        category: ExpenseCategory.toll,
        payee: 'Salik',
        net: 1260,
        vehicleId: savedVehicles[0].id,
        workOrderId: workOrders[7].id,
        description: 'Fleet toll account monthly recharge.',
        reference: 'SALIK-2505-01',
        notes: 'Allocated to monthly fleet activity.',
      ),
      null,
      true,
    ),
    (
      Expense(
        id: '',
        date: date(-43),
        category: ExpenseCategory.driverPay,
        payee: savedDrivers[5].name,
        net: 8450,
        driverId: savedDrivers[5].id,
        workOrderId: workOrders[8].id,
        description: 'Salary, event overtime, and night allowance.',
        dueDate: date(-38),
        reference: 'PAY-DRV-2506-06',
        notes: 'Event overtime approved by operations.',
      ),
      null,
      true,
    ),
    (
      Expense(
        id: '',
        date: date(-31),
        category: ExpenseCategory.maintenance,
        payee: savedParties[6].name,
        net: 6800,
        vat: 340,
        vehicleId: savedVehicles[5].id,
        description: 'Bus air-conditioning repair and service.',
        dueDate: date(-16),
        reference: 'CFW-2506-912',
        notes: 'Repair completed after event shift.',
      ),
      supplierIds[3],
      false,
    ),
    (
      Expense(
        id: '',
        date: date(-16),
        category: ExpenseCategory.parking,
        payee: 'Dubai Marina Parking',
        net: 95,
        vat: 4.75,
        vehicleId: savedVehicles[2].id,
        driverId: savedDrivers[1].id,
        workOrderId: workOrders[9].id,
        description: 'Delivery bay parking charge.',
        reference: 'PARK-DM-9940',
        notes: 'Pending reimbursement approval.',
      ),
      null,
      false,
    ),
    (
      Expense(
        id: '',
        date: date(-10),
        category: ExpenseCategory.fuel,
        payee: savedParties[5].name,
        net: 8120,
        vat: 406,
        description: 'Current fleet fuel card statement.',
        dueDate: date(20),
        reference: 'FFS-2607-2044',
        notes: 'Open statement for all owned vehicles.',
      ),
      supplierIds[2],
      false,
    ),
    (
      Expense(
        id: '',
        date: date(-5),
        category: ExpenseCategory.gatePass,
        payee: 'Abu Dhabi Airport Free Zone',
        net: 125,
        vehicleId: savedVehicles[1].id,
        workOrderId: workOrders[10].id,
        description: 'Airport delivery gate permit.',
        reference: 'ADAFZ-GP-26044',
        notes: 'Permit issued for planned work order.',
      ),
      null,
      false,
    ),
    (
      Expense(
        id: '',
        date: date(-2),
        category: ExpenseCategory.other,
        payee: 'Fleet Mobile Services',
        net: 2200,
        vat: 110,
        description: 'Vehicle tracking subscriptions for the quarter.',
        dueDate: date(13),
        reference: 'FMS-Q3-2607',
        notes: 'Covers all seven active vehicles.',
      ),
      null,
      false,
    ),
  ];
  final expenses = <Expense>[];
  for (final (definition, partyId, shouldPay) in expenseDefs) {
    final expense = await save(
      'expense ${definition.reference}',
      moneyRepo.addExpense(definition),
    );
    expenses.add(expense);
    if (shouldPay) {
      await save(
        'payment for expense ${definition.reference}',
        moneyRepo.recordPayment(
          Payment(
            id: '',
            direction: PaymentDirection.outgoing,
            partyId: partyId,
            date: expense.date.add(const Duration(days: 5)),
            amount: expense.total,
            method: PaymentMethod.bankTransfer,
            bankOrChequeReference: 'PAY-${definition.reference}',
            allocations: [
              PaymentAllocation(expenseId: expense.id, amount: expense.total),
            ],
            notes: 'Historical expense payment.',
          ),
        ),
      );
    }
  }

  final invoicePayments = <(int, num, PaymentMethod)>[
    (0, invoices[0].gross, PaymentMethod.bankTransfer),
    (1, roundMoney(invoices[1].gross / 2), PaymentMethod.bankTransfer),
    (2, invoices[2].gross, PaymentMethod.cheque),
    (3, invoices[3].gross, PaymentMethod.cash),
    (5, invoices[5].gross, PaymentMethod.bankTransfer),
    (7, roundMoney(invoices[7].gross - 25000), PaymentMethod.bankTransfer),
    (8, roundMoney(invoices[8].gross * 0.6), PaymentMethod.bankTransfer),
  ];
  for (final (index, amount, method) in invoicePayments) {
    final invoice = invoices[index];
    await save(
      'payment for ${invoice.number}',
      moneyRepo.recordPayment(
        Payment(
          id: '',
          direction: PaymentDirection.incoming,
          partyId: invoice.buyerId,
          date: invoice.issueDate.add(const Duration(days: 12)),
          amount: amount,
          method: method,
          bankOrChequeReference: method == PaymentMethod.cheque
              ? 'CHQ-DEMO-${index + 1}'
              : 'RCPT-DEMO-${index + 1}',
          chequeDate: method == PaymentMethod.cheque
              ? invoice.issueDate.add(const Duration(days: 14))
              : null,
          allocations: [
            PaymentAllocation(invoiceId: invoice.id, amount: amount),
          ],
          notes: method == PaymentMethod.cheque
              ? 'Cheque received and awaiting clearance.'
              : 'Historical customer receipt.',
        ),
      ),
    );
  }

  for (var index = 0; index < settlements.length; index++) {
    final settlement = settlements[index];
    final amount = index == 0
        ? settlement.total
        : roundMoney(settlement.total / 2);
    await save(
      'payment for ${settlement.number}',
      moneyRepo.recordPayment(
        Payment(
          id: '',
          direction: PaymentDirection.outgoing,
          partyId: settlement.supplierId,
          date: settlement.periodEnd.add(const Duration(days: 10)),
          amount: amount,
          method: PaymentMethod.bankTransfer,
          bankOrChequeReference: 'SUP-PAY-${index + 1}',
          allocations: [
            PaymentAllocation(settlementId: settlement.id, amount: amount),
          ],
          notes: index == 0
              ? 'Supplier settlement paid in full.'
              : 'First supplier settlement instalment.',
        ),
      ),
    );
  }

  await save(
    'July payment for ${invoices[7].number}',
    moneyRepo.recordPayment(
      Payment(
        id: '',
        direction: PaymentDirection.incoming,
        partyId: invoices[7].buyerId,
        date: date(-8),
        amount: 25000,
        method: PaymentMethod.bankTransfer,
        bankOrChequeReference: 'RCPT-AFL-2607',
        allocations: [
          PaymentAllocation(invoiceId: invoices[7].id, amount: 25000),
        ],
        notes: 'Final payment against the monthly fleet invoice.',
      ),
    ),
  );
  await save(
    'July payment for expense ${expenses[11].reference}',
    moneyRepo.recordPayment(
      Payment(
        id: '',
        direction: PaymentDirection.outgoing,
        partyId: supplierIds[2],
        date: date(-6),
        amount: expenses[11].total,
        method: PaymentMethod.bankTransfer,
        bankOrChequeReference: 'PAY-FFS-2607',
        allocations: [
          PaymentAllocation(
            expenseId: expenses[11].id,
            amount: expenses[11].total,
          ),
        ],
        notes: 'Payment against the current fleet fuel statement.',
      ),
    ),
  );

  parties.invalidateCache();
  workRepo.invalidateCache();
  moneyRepo.invalidateCache();
  return '${savedParties.length} parties, ${savedVehicles.length} vehicles, '
      '${savedDrivers.length} drivers, ${routeDefs.length} routes, '
      '${savedAgreements.length} agreements, ${workOrders.length} work orders, '
      '${invoices.length} invoices, ${settlements.length} settlements, '
      '${expenses.length} expenses, and 20 payments seeded.';
}
