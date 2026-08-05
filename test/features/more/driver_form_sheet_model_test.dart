import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/driver_form/driver_form_sheet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

class MockPartiesRepository extends Mock implements PartiesRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockPartiesRepository partiesRepository;

  setUp(() {
    partiesRepository = MockPartiesRepository();
    if (locator.isRegistered<PartiesRepository>()) {
      locator.unregister<PartiesRepository>();
    }
    locator.registerSingleton<PartiesRepository>(partiesRepository);
  });

  tearDown(locator.reset);

  test(
    'init hydrates selected supplier and exposes repository errors',
    () async {
      final supplier = Party(
        id: 's1',
        name: 'Supplier',
        type: PartyType.supplier,
      );
      final initial = Driver(
        id: 'd1',
        name: 'Existing',
        employment: Responsibility.customer,
        supplierId: 's1',
      );
      when(
        () => partiesRepository.fetchById('s1'),
      ).thenAnswer((_) async => Success(supplier));

      final model = DriverFormSheetModel(
        completer: (_) {},
        request: SheetRequest(data: initial),
      );
      await model.init();
      expect(model.selectedSupplier, supplier);
      expect(model.errorMessage, isNull);

      when(() => partiesRepository.fetchById('s1')).thenAnswer(
        (_) async => const Failure(ValidationFailure('load failed')),
      );
      await model.init();
      expect(model.selectedSupplier, supplier);
      expect(model.errorMessage, 'load failed');
      model.dispose();
    },
  );

  test('selection clears supplier when employment changes to operator', () {
    final model = DriverFormSheetModel(
      completer: (_) {},
      request: SheetRequest(),
    );

    model.selectEmployment([Responsibility.customer]);
    model.selectSupplier(
      Party(id: 's1', name: 'Supplier', type: PartyType.supplier),
    );
    expect(model.employment, Responsibility.customer);
    expect(model.selectedSupplier?.id, 's1');

    model.selectEmployment([Responsibility.operator]);
    expect(model.selectedSupplier, isNull);
    model.selectSupplier(null);
    expect(model.selectedSupplier, isNull);
    model.dispose();
  });

  test(
    'submit validates customer supplier and returns trimmed driver data',
    () {
      Driver? saved;
      final model = DriverFormSheetModel(
        completer: (response) => saved = response.data as Driver?,
        request: SheetRequest(),
      );

      model.employment = Responsibility.customer;
      model.nameController.text = ' Rashid Ali ';
      model.submit();
      expect(saved, isNull);

      model.selectSupplier(
        Party(id: 's1', name: 'Supplier', type: PartyType.supplier),
      );
      model.phoneController.text = ' 050 123 ';
      model.licenceNumberController.text = ' L1 ';
      model.identityReferenceController.text = ' ID1 ';
      model.notesController.text = ' note ';
      model.submit();

      expect(saved, isNotNull);
      expect(saved!.id, isEmpty);
      expect(saved!.name, 'Rashid Ali');
      expect(saved!.phone, '050 123');
      expect(saved!.licenceNumber, 'L1');
      expect(saved!.identityReference, 'ID1');
      expect(saved!.supplierId, 's1');
      expect(saved!.notes, 'note');
      model.dispose();
    },
  );

  test('edit mode prefills fields and preserves driver id', () {
    final licenceExpiry = DateTime(2026, 8, 1);
    final identityExpiry = DateTime(2026, 9, 1);
    final initial = Driver(
      id: 'd1',
      name: 'Existing',
      phone: '050',
      licenceNumber: 'L1',
      identityReference: 'ID1',
      notes: 'old',
      employment: Responsibility.customer,
      supplierId: 's1',
      licenceExpiry: licenceExpiry,
      identityExpiry: identityExpiry,
    );
    Driver? saved;
    final model = DriverFormSheetModel(
      completer: (response) => saved = response.data as Driver?,
      request: SheetRequest(data: initial),
    );

    expect(model.isEditing, isTrue);
    expect(model.nameController.text, 'Existing');
    expect(model.phoneController.text, '050');
    expect(model.employment, Responsibility.customer);
    expect(model.licenceExpiry, licenceExpiry);
    expect(model.identityExpiry, identityExpiry);

    model.selectSupplier(
      Party(id: 's1', name: 'Supplier', type: PartyType.supplier),
    );
    model.submit();
    expect(saved!.id, 'd1');
    expect(saved!.name, 'Existing');
    model.dispose();
  });
}
