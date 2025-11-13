import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';

void main() {
  group('FuturisticCard', () {
    testWidgets('should display child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FuturisticCard(
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
            body: FuturisticCard(
              onTap: () {
                tapped = true;
              },
              child: Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FuturisticCard));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('should not call onTap when null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FuturisticCard(
              child: Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FuturisticCard));
      await tester.pump();

      // Should not throw
      expect(find.text('Test'), findsOneWidget);
    });
  });
}

