import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.dialogs.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/models/agreement.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/more/data/vehicle_repository.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/ui/bottom_sheets/agreement_form/agreement_form_sheet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockVehicleRepository vehicleRepository;
  late MockPartiesRepository partiesRepository;
  late MockDialogService dialogs;

  setUp(() {
    vehicleRepository = MockVehicleRepository();
    partiesRepository = MockPartiesRepository();
    dialogs = MockDialogService();
    replaceTestRegistration<VehicleRepository>(vehicleRepository);
    replaceTestRegistration<PartiesRepository>(partiesRepository);
    replaceTestRegistration<DialogService>(dialogs);
  });

  tearDown(locator.reset);

  final cases = <(String, void Function(AgreementFormSheetModel))>[
    ('name', (model) => model.nameController.clear()),
    ('customer', (model) => model.customerId = null),
    ('rates', (model) => model.baseRateAEDController.text = 'invalid'),
    ('duty days', (model) => model.dutyDaysController.text = '32'),
    ('included hours', (model) => model.includedHoursController.text = '745'),
    ('VAT rate', (model) => model.vatRateController.text = '101'),
  ];

  for (final testCase in cases) {
    test('submit rejects invalid ${testCase.$1}', () {
      var completed = false;
      final model = _validModel((_) => completed = true);
      testCase.$2(model);

      model.submit();

      expect(completed, isFalse);
      model.dispose();
    });
  }

  test('init hydrates default vehicle and reports failures', () async {
    final vehicle = Vehicle(
      id: 'v1',
      plateNumber: 'DXB A 1',
      label: 'Truck',
      vehicleClass: VehicleClass.threeTon,
      ownership: VehicleOwnership.owned,
    );
    when(
      () => vehicleRepository.fetchById('v1'),
    ).thenAnswer((_) async => Success(vehicle));
    final initial = Agreement(
      id: 'a1',
      reference: 'AGR-1',
      name: 'Existing',
      customerId: 'c1',
      defaultVehicleId: 'v1',
      rateModel: RateModel.perTrip,
      baseRate: 0,
      dutyDays: 0,
      includedHours: 0,
      overtimeRate: 0,
      extraDayRate: 0,
      extraTripRate: 0,
      vatRate: 5,
      defaultExtras: const {},
      paymentTerms: PaymentTerms.onReceipt,
    );
    final model = AgreementFormSheetModel(
      completer: (_) {},
      request: SheetRequest(data: initial),
    );
    await model.init();
    expect(model.selectedVehicle, vehicle);
    expect(model.errorMessage, isNull);

    when(() => vehicleRepository.fetchById('v1')).thenAnswer(
      (_) async => const Failure(ValidationFailure('vehicle failed')),
    );
    await model.init();
    expect(model.selectedVehicle, vehicle);
    expect(model.errorMessage, 'vehicle failed');
    model.dispose();
  });

  test('selection methods ignore null and update values', () {
    final model = _validModel();
    model.selectRateModel(RateModel.monthly);
    model.selectCustomer(
      const Party(id: 'c1', name: 'Customer', type: PartyType.customer),
    );
    model.selectVehicle(
      Vehicle(
        id: 'v1',
        plateNumber: 'DXB A 1',
        label: 'Truck',
        vehicleClass: VehicleClass.threeTon,
        ownership: VehicleOwnership.owned,
      ),
    );
    model.selectPaymentTerms(PaymentTerms.net30);
    expect(model.rateModel, RateModel.monthly);
    expect(model.customerId, 'c1');
    expect(model.defaultVehicleId, 'v1');
    expect(model.paymentTerms, PaymentTerms.net30);

    model.selectRateModel(null);
    model.selectCustomer(null);
    model.selectVehicle(null);
    model.selectPaymentTerms(null);
    expect(model.rateModel, RateModel.monthly);
    expect(model.customerId, isNull);
    expect(model.defaultVehicleId, isNull);
    expect(model.paymentTerms, PaymentTerms.net30);
    model.dispose();
  });

  test(
    'extra dialogs add, edit, ignore duplicates, and remove extras',
    () async {
      final model = _validModel();
      when(
        () => dialogs.showCustomDialog(variant: DialogType.addEditExtra),
      ).thenAnswer(
        (_) async => DialogResponse(
          confirmed: true,
          data: {'name': 'Waiting', 'amount': 12.5},
        ),
      );
      await model.openAddExtraDialog();
      expect(model.extras, hasLength(1));
      expect(model.extras.single.key, 'Waiting');
      expect(model.extras.single.value, 12.5);
      await model.openAddExtraDialog();
      expect(model.extras, hasLength(1));

      when(
        () => dialogs.showCustomDialog(
          variant: DialogType.addEditExtra,
          data: {'name': 'Waiting', 'amount': 12.5},
        ),
      ).thenAnswer(
        (_) async => DialogResponse(confirmed: true, data: {'amount': 20}),
      );
      await model.openEditExtraDialog(0);
      expect(model.extras.single.value, 20);
      expect(model.extraValControllers.single.text, '20.00');
      model.removeExtra(0);
      expect(model.extras, isEmpty);
      model.dispose();
    },
  );

  test('submit returns a valid agreement with extras', () {
    Agreement? saved;
    final model = _validModel(
      (response) => saved = response.data as Agreement?,
    );
    model.selectRateModel(RateModel.monthly);
    model.selectPaymentTerms(PaymentTerms.net45);
    model.notesController.text = ' Notes ';
    model.extras = [const MapEntry('Waiting', 12.5)];
    model.extraKeyControllers.add(TextEditingController(text: ' Waiting '));
    model.extraValControllers.add(TextEditingController(text: '12.50'));
    expect(model.validateExtras(), isNull);
    model.submit();

    expect(saved, isNotNull);
    expect(saved!.name, 'Agreement');
    expect(saved!.rateModel, RateModel.monthly);
    expect(saved!.paymentTerms, PaymentTerms.net45);
    expect(saved!.defaultExtras, {'Waiting': 12.5});
    expect(saved!.notes, 'Notes');
    model.dispose();
  });

  test('edit mode prefills agreement fields and preserves identity', () {
    final initial = Agreement(
      id: 'a1',
      reference: 'AGR-1',
      name: 'Existing',
      customerId: 'c1',
      rateModel: RateModel.monthly,
      baseRate: 100,
      dutyDays: 20,
      includedHours: 160,
      overtimeRate: 10,
      extraDayRate: 20,
      extraTripRate: 30,
      vatRate: 5,
      defaultExtras: const {'Waiting': 12.5},
      notes: 'Old note',
      paymentTerms: PaymentTerms.net30,
    );
    Agreement? saved;
    final model = AgreementFormSheetModel(
      completer: (response) => saved = response.data as Agreement?,
      request: SheetRequest(data: initial),
    );
    expect(model.isEditing, isTrue);
    expect(model.nameController.text, 'Existing');
    expect(model.baseRateAEDController.text, '100.00');
    expect(model.extraKeyControllers.single.text, 'Waiting');
    expect(model.paymentTerms, PaymentTerms.net30);
    model.submit();
    expect(saved!.id, 'a1');
    expect(saved!.reference, 'AGR-1');
    expect(saved!.defaultExtras, {'Waiting': 12.5});
    model.dispose();
  });
}

AgreementFormSheetModel _validModel([
  void Function(SheetResponse response)? completer,
]) =>
    AgreementFormSheetModel(
        completer: completer ?? (_) {},
        request: SheetRequest(),
      )
      ..nameController.text = 'Agreement'
      ..customerId = 'customer'
      ..baseRateAEDController.text = '0'
      ..overtimeRateController.text = '0'
      ..extraDayRateController.text = '0'
      ..extraTripRateController.text = '0'
      ..dutyDaysController.text = '0'
      ..includedHoursController.text = '0'
      ..vatRateController.text = '5';
