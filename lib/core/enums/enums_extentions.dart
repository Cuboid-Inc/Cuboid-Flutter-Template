import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart' show IconData;

extension EnumLabel on Enum {
  String get label {
    final words = name
        .split(RegExp(r'(?<=[a-z0-9])(?=[A-Z])|[_\s]+'))
        .where((word) => word.isNotEmpty);

    return words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String toJson() => name
      .replaceAllMapped(
        RegExp(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Za-z])(?=\d)'),
        (_) => '_',
      )
      .toLowerCase();
}

T enumFromJson<T extends Enum>(String value, List<T> values) =>
    values.firstWhere(
      (item) => item.toJson() == value,
      orElse: () =>
          throw ArgumentError.value(value, 'value', 'Unknown enum wire value'),
    );

T? enumFromJsonOrNull<T extends Enum>(String? value, List<T> values) {
  if (value == null) return null;
  for (final item in values) {
    if (item.toJson() == value) return item;
  }
  return null;
}

extension MoneySegmentMeta on MoneySegment {
  IconData get icon => switch (this) {
    MoneySegment.invoices => CupertinoIcons.doc_text,
    MoneySegment.statements => CupertinoIcons.doc_plaintext,
    MoneySegment.settlements => CupertinoIcons.arrow_2_squarepath,
    MoneySegment.payments => CupertinoIcons.creditcard,
    MoneySegment.expenses => CupertinoIcons.cart,
    MoneySegment.balances => CupertinoIcons.building_2_fill,
  };
}

extension VehicleClassLabel on VehicleClass {
  String get label => switch (this) {
    VehicleClass.threeTon => '3-Ton',
    VehicleClass.sevenTon => '7-Ton',
    VehicleClass.tenTon => '10-Ton',
    VehicleClass.flatbed => 'Flatbed',
    VehicleClass.thirtySeatBus => '30-seat bus',
    VehicleClass.trailer => 'Trailer',
    VehicleClass.pickup => 'Pickup',
    VehicleClass.custom => 'Custom',
  };
}
