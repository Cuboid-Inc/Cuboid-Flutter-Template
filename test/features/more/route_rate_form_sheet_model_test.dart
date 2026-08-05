import 'package:cuboid_flutter_template/app/app.dialogs.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/route_rate.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/route_rate_form/route_rate_form_sheet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockPartiesRepository extends Mock implements PartiesRepository {}

void main() {
  late MockPartiesRepository partiesRepository;
  late MockDialogService dialogs;

  setUp(() {
    partiesRepository = MockPartiesRepository();
    dialogs = MockDialogService();
    replaceTestRegistration<PartiesRepository>(partiesRepository);
    replaceTestRegistration<DialogService>(dialogs);
  });

  tearDown(locator.reset);

  test('submit rejects missing route fields and invalid rate', () {
    var completed = false;
    final model = _validModel((_) => completed = true)
      ..pickupController.clear();
    model.submit();
    expect(completed, isFalse);

    model.pickupController.text = 'A';
    model.destinationController.clear();
    model.submit();
    expect(completed, isFalse);

    model.destinationController.text = 'B';
    model.rateAEDController.text = 'invalid';
    model.submit();
    expect(completed, isFalse);
    model.dispose();
  });

  test('submit rejects missing extra names and invalid extra rates', () {
    final model = _validModel();
    model.extras = const [MapEntry('', 1)];
    model.extraKeyControllers.add(TextEditingController());
    model.extraValControllers.add(TextEditingController(text: '1'));
    expect(model.validateExtras(), 'Extra name is required');

    model.extraKeyControllers.single.text = 'Waiting';
    model.extraValControllers.single.text = 'invalid';
    expect(
      model.validateExtras(),
      'Extra rates must be valid amounts of 0 or more',
    );
    model.dispose();
  });

  test('init loads customers and exposes errors', () async {
    final customer = Party(
      id: 'c1',
      name: 'Customer',
      type: PartyType.customer,
    );
    when(
      () => partiesRepository.partiesForDirection(PaymentDirection.incoming),
    ).thenAnswer((_) async => Success([customer]));
    final model = RouteRateFormSheetModel(
      completer: (_) {},
      request: SheetRequest(),
    );
    await model.init();
    expect(model.customers, [customer]);
    expect(model.errorMessage, isNull);

    when(
      () => partiesRepository.partiesForDirection(PaymentDirection.incoming),
    ).thenAnswer((_) async => const Failure(ValidationFailure('load failed')));
    await model.init();
    expect(model.errorMessage, 'load failed');
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
      expect(model.extraValControllers.single.text, '12.50');

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

  test('submit returns route data with extras and selections', () {
    RouteRate? saved;
    final model = _validModel(
      (response) => saved = response.data as RouteRate?,
    );
    model.selectAppliesTo('Customer only');
    model.selectVehicleClass(VehicleClass.sevenTon);
    model.extras = [const MapEntry('Waiting', 12.5)];
    model.extraKeyControllers.add(TextEditingController(text: ' Waiting '));
    model.extraValControllers.add(TextEditingController(text: '12.50'));
    expect(model.validateExtras(), isNull);
    model.submit();

    expect(saved, isNotNull);
    expect(saved!.appliesTo, 'Customer only');
    expect(saved!.vehicleClass, VehicleClass.sevenTon);
    expect(saved!.defaultExtras, {'Waiting': 12.5});
    model.dispose();
  });

  test('edit mode prefills route fields and preserves route id', () {
    final initial = RouteRate(
      id: 'r1',
      appliesTo: 'Customer only',
      pickup: 'A',
      destination: 'B',
      vehicleClass: VehicleClass.sevenTon,
      rate: 25,
      defaultExtras: const {'Waiting': 12.5},
    );
    RouteRate? saved;
    final model = RouteRateFormSheetModel(
      completer: (response) => saved = response.data as RouteRate?,
      request: SheetRequest(data: initial),
    );

    expect(model.isEditing, isTrue);
    expect(model.pickupController.text, 'A');
    expect(model.destinationController.text, 'B');
    expect(model.rateAEDController.text, '25.00');
    expect(model.extraKeyControllers.single.text, 'Waiting');
    model.submit();

    expect(saved!.id, 'r1');
    expect(saved!.defaultExtras, {'Waiting': 12.5});
    model.dispose();
  });
}

RouteRateFormSheetModel _validModel([
  void Function(SheetResponse response)? completer,
]) =>
    RouteRateFormSheetModel(
        completer: completer ?? (_) {},
        request: SheetRequest(),
      )
      ..pickupController.text = 'A'
      ..destinationController.text = 'B'
      ..rateAEDController.text = '10';
