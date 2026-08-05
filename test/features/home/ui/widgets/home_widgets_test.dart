import 'package:fleetgo/features/home/ui/widgets/attention_action_tile.dart';
import 'package:fleetgo/features/home/ui/widgets/dashboard_metric_card.dart';
import 'package:fleetgo/features/home/ui/widgets/quick_action_grid.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('AttentionActionTile renders count and handles tap', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      app(
        AttentionActionTile(
          count: 2,
          labelText: 'Open invoices',
          subtitleText: 'Need review',
          onTap: () => tapped = true,
        ),
      ),
    );
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Open invoices'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.chevron_forward), findsOneWidget);
    await tester.tap(find.text('Open invoices'));
    expect(tapped, isTrue);

    await tester.pumpWidget(
      app(
        const AttentionActionTile(
          count: 0,
          labelText: 'Nothing due',
          subtitleText: 'All clear',
          isLast: true,
        ),
      ),
    );
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('DashboardMetricCard covers regular and profit hero layouts', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Column(
          children: [
            DashboardMetricCard(
              name: 'Revenue',
              amount: 'AED 100',
              periodLabel: 'This month',
              recordCount: 4,
              recordCountLabel: 'invoices',
              onTap: () {},
            ),
            const DashboardMetricCard(
              name: 'Profit',
              amount: 'AED 50',
              periodLabel: 'This month',
              isProfitHero: true,
            ),
          ],
        ),
      ),
    );
    expect(find.text('REVENUE · This month'), findsOneWidget);
    expect(find.text('4 invoices'), findsOneWidget);
    expect(find.text('AED 50'), findsOneWidget);
    expect(find.text('0 items'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
  });

  testWidgets('QuickActionGrid filters actions and handles callbacks', (
    tester,
  ) async {
    var newTrip = 0;
    var paymentIn = 0;
    var expense = 0;
    var paymentOut = 0;
    await tester.pumpWidget(
      app(
        QuickActionGrid(
          hasOperations: true,
          hasMoney: true,
          onNewTrip: () => newTrip++,
          onPaymentIn: () => paymentIn++,
          onAddExpense: () => expense++,
          onPaymentOut: () => paymentOut++,
        ),
      ),
    );
    expect(find.text('New trip'), findsOneWidget);
    expect(find.text('Payment in'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Payment out'), findsOneWidget);
    await tester.tap(find.text('New trip'));
    await tester.tap(find.text('Payment in'));
    await tester.tap(find.text('Expense'));
    await tester.tap(find.text('Payment out'));
    expect(newTrip, 1);
    expect(paymentIn, 1);
    expect(expense, 1);
    expect(paymentOut, 1);

    await tester.pumpWidget(
      app(
        const QuickActionGrid(
          hasOperations: false,
          hasMoney: false,
          onNewTrip: _noop,
          onPaymentIn: _noop,
          onAddExpense: _noop,
          onPaymentOut: _noop,
        ),
      ),
    );
    expect(find.byType(SizedBox), findsOneWidget);
  });
}

void _noop() {}
