import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test(
    'vehicle operations return guard failures without Supabase config',
    () async {
      final repository = VehicleRepository(MockAuthRepository());
      final vehicle = Vehicle(
        id: '',
        plateNumber: 'A-1',
        label: 'Truck',
        vehicleClass: VehicleClass.threeTon,
        ownership: VehicleOwnership.owned,
      );

      expect(await repository.fetchVehicles(), isA<Failure<List<Vehicle>>>());
      expect(
        await repository.fetchVehiclesPage(pageNumber: 1),
        isA<Failure<PaginatedResult<Vehicle>>>(),
      );
      expect(
        await repository.fetchVehiclesPage(
          pageNumber: 2,
          pageSize: 10,
          search: 'Truck',
        ),
        isA<Failure<PaginatedResult<Vehicle>>>(),
      );
      expect(await repository.addVehicle(vehicle), isA<Failure<Vehicle>>());
      expect(
        await repository.addVehicle(
          Vehicle(
            id: 'vehicle',
            plateNumber: 'A-1',
            label: 'Truck',
            vehicleClass: VehicleClass.sevenTon,
            ownership: VehicleOwnership.external,
          ),
        ),
        isA<Failure<Vehicle>>(),
      );
      expect(await repository.archiveVehicle('vehicle'), isA<Failure<void>>());
      repository.invalidateCache();
    },
  );
}
