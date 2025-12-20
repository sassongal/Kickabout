import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kattrick/widgets/common/premium_card.dart';

void main() {
  group('PremiumCard', () {
    testWidgets('should display child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumCard(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumCard(
              onTap: () {
                tapped = true;
              },
              child: Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PremiumCard));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('should not call onTap when null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumCard(
              child: Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PremiumCard));
      await tester.pump();

      // Should not throw
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
