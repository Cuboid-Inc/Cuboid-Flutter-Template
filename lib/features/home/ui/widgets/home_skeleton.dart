import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// Placeholder shaped like the loaded home screen (greeting, hero metrics
/// card, cash card, quick actions, receivables/payables, attention list).
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SkeletonPulse(
    child: ListView(
      padding: const EdgeInsets.only(
        left: s16,
        right: s16,
        top: s16,
        bottom: 100,
      ),
      children: [
        Row(
          children: [
            const SkeletonBox(width: 40, height: 40, borderRadius: 13),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 120, height: 16),
                  SizedBox(height: 6),
                  SkeletonBox(width: 160, height: 12),
                ],
              ),
            ),
            const SkeletonBox(width: 90, height: 32, borderRadius: radiusSm),
          ],
        ),
        const SizedBox(height: 16),
        _card(
          padding: 18,
          radius: radiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 140, height: 12),
              const SizedBox(height: 10),
              const SkeletonBox(width: 180, height: 32),
              const SizedBox(height: 8),
              const SkeletonBox(width: 200, height: 12),
              const Divider(height: 22),
              Row(children: [_heroStat(), _heroStat(), _heroStat()]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          padding: 16,
          radius: radiusMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 120, height: 11),
              const SizedBox(height: 10),
              const SkeletonBox(width: 100, height: 24),
              const SizedBox(height: 8),
              const SkeletonBox(width: 220, height: 12),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(child: _cashStat()),
                  const SizedBox(width: 16),
                  Expanded(child: _cashStat()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _quickActionTile()),
            const SizedBox(width: s12),
            Expanded(child: _quickActionTile()),
          ],
        ),
        const SizedBox(height: s12),
        Row(
          children: [
            Expanded(child: _quickActionTile()),
            const SizedBox(width: s12),
            Expanded(child: _quickActionTile()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _metricCard()),
            const SizedBox(width: 10),
            Expanded(child: _metricCard()),
          ],
        ),
        const SizedBox(height: 16),
        const SkeletonBox(width: 130, height: 12),
        const SizedBox(height: 8),
        _card(
          padding: 0,
          radius: radiusMd,
          child: Column(
            children: [
              _attentionRow(),
              const Divider(height: 1, color: AppColors.border),
              _attentionRow(),
              const Divider(height: 1, color: AppColors.border),
              _attentionRow(isLast: true),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _card({
    required double padding,
    required double radius,
    required Widget child,
  }) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );

  Widget _heroStat() => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: 60, height: 11),
        SizedBox(height: 6),
        SkeletonBox(width: 45, height: 15),
      ],
    ),
  );

  Widget _cashStat() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      SkeletonBox(width: 80, height: 11),
      SizedBox(height: 6),
      SkeletonBox(width: 55, height: 15),
    ],
  );

  Widget _quickActionTile() => Container(
    padding: const EdgeInsets.symmetric(vertical: s12, horizontal: s12),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(radiusMd),
    ),
    child: Row(
      children: [
        const SkeletonBox(width: 38, height: 38, borderRadius: radiusSm),
        const SizedBox(width: s12),
        const Expanded(child: SkeletonBox(height: 13)),
      ],
    ),
  );

  Widget _metricCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(radiusMd),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: 90, height: 10),
        SizedBox(height: 8),
        SkeletonBox(width: 70, height: 19),
        SizedBox(height: 6),
        SkeletonBox(width: 60, height: 11),
      ],
    ),
  );

  Widget _attentionRow({bool isLast = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    child: Row(
      children: [
        const SkeletonBox(width: 36, height: 36, borderRadius: 10),
        const SizedBox(width: s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 140, height: 13),
              SizedBox(height: 6),
              SkeletonBox(width: 180, height: 11),
            ],
          ),
        ),
      ],
    ),
  );
}
