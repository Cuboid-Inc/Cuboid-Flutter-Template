import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('totalPages rounds up and handles non-positive page sizes', () {
    expect(
      const PaginatedResult<int>(
        items: [1, 2],
        pageNumber: 1,
        pageSize: 2,
        totalRecords: 5,
      ).totalPages,
      3,
    );
    expect(
      const PaginatedResult<int>(
        items: [],
        pageNumber: 1,
        pageSize: 0,
        totalRecords: 5,
      ).totalPages,
      0,
    );
  });
}
