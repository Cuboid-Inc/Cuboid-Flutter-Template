import 'package:cuboid_flutter/cuboid_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SwipeBackConfiguration defaults', () {
    test('enable the gesture overall, with iOS on and Android off', () {
      const config = SwipeBackConfiguration();

      expect(config.enabled, isTrue);
      expect(config.enabledOnAndroid, isFalse);
    });

    test('use sensible threshold, velocity, and duration values', () {
      const config = SwipeBackConfiguration();

      expect(config.completionThreshold, greaterThan(0));
      expect(config.completionThreshold, lessThanOrEqualTo(1));
      expect(config.minFlingVelocity, greaterThan(0));
      expect(config.transitionDuration, greaterThan(Duration.zero));
    });
  });

  group('isEnabledFor', () {
    test('iOS is enabled by default', () {
      expect(
        const SwipeBackConfiguration().isEnabledFor(TargetPlatform.iOS),
        isTrue,
      );
    });

    test('Android is disabled by default', () {
      expect(
        const SwipeBackConfiguration().isEnabledFor(TargetPlatform.android),
        isFalse,
      );
    });

    test('Android can be explicitly enabled', () {
      const config = SwipeBackConfiguration(enabledOnAndroid: true);

      expect(config.isEnabledFor(TargetPlatform.android), isTrue);
      expect(config.isEnabledFor(TargetPlatform.iOS), isTrue);
    });

    test(
      'enabled: false disables every platform, even with enabledOnAndroid',
      () {
        const config = SwipeBackConfiguration(
          enabled: false,
          enabledOnAndroid: true,
        );

        expect(config.isEnabledFor(TargetPlatform.iOS), isFalse);
        expect(config.isEnabledFor(TargetPlatform.android), isFalse);
      },
    );

    test('desktop and other platforms are never enabled', () {
      const config = SwipeBackConfiguration(enabledOnAndroid: true);

      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(config.isEnabledFor(platform), isFalse);
      }
    });
  });

  test('SwipeBackConfiguration.disabled turns the gesture off everywhere', () {
    expect(
      SwipeBackConfiguration.disabled.isEnabledFor(TargetPlatform.iOS),
      isFalse,
    );
    expect(
      SwipeBackConfiguration.disabled.isEnabledFor(TargetPlatform.android),
      isFalse,
    );
  });
}
