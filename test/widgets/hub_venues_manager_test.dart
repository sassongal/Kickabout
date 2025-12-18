import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kattrick/widgets/hub/hub_venues_manager.dart';
import 'package:kattrick/models/venue.dart';
import 'package:kattrick/data/venues_repository.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock classes
class MockVenuesRepository extends Mock implements VenuesRepository {}

void main() {
  late MockVenuesRepository mockVenuesRepository;

  setUp(() {
    mockVenuesRepository = MockVenuesRepository();
  });

  final testVenue1 = Venue(
    venueId: 'venue1',
    hubId: 'hub1',
    name: 'מגרש 1',
    address: 'כתובת 1',
    location: const GeoPoint(32.0, 34.0),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testVenue2 = Venue(
    venueId: 'venue2',
    hubId: 'hub1',
    name: 'מגרש 2',
    address: 'כתובת 2',
    location: const GeoPoint(32.1, 34.1),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget createWidgetUnderTest({
    List<Venue> initialVenues = const [],
    String? initialMainVenueId,
    required Function(List<Venue>, String?) onChanged,
  }) {
    return ProviderScope(
      overrides: [
        venuesRepositoryProvider.overrideWithValue(mockVenuesRepository),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: HubVenuesManager(
            initialVenues: initialVenues,
            initialMainVenueId: initialMainVenueId,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  group('HubVenuesManager Widget Tests', () {
    testWidgets('should display title and empty state',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(
        onChanged: (venues, mainId) {},
      ));

      // Assert
      expect(find.text('מגרשי הבית (עד 3)'), findsOneWidget);
      expect(
          find.text('לא נבחרו מגרשים. הוסף מגרש כדי להתחיל.'), findsOneWidget);
    });

    testWidgets('should show search field when less than 3 venues',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(
        onChanged: (venues, mainId) {},
      ));

      // Assert
      expect(find.text('הוסף מגרש'), findsOneWidget);
    });

    testWidgets('should hide search field when 3 venues',
        (WidgetTester tester) async {
      // Arrange
      final venue3 = Venue(
        venueId: 'venue3',
        hubId: 'hub1',
        name: 'מגרש 3',
        location: const GeoPoint(32.2, 34.2),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        initialVenues: [testVenue1, testVenue2, venue3],
        onChanged: (venues, mainId) {},
      ));

      // Assert
      expect(find.text('הוסף מגרש'), findsNothing);
    });

    testWidgets('should display initial venues', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(
        initialVenues: [testVenue1, testVenue2],
        onChanged: (venues, mainId) {},
      ));

      // Assert
      expect(find.text('מגרש 1'), findsOneWidget);
      expect(find.text('מגרש 2'), findsOneWidget);
    });

    testWidgets('should mark first venue as main by default',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        initialVenues: [testVenue1],
        onChanged: (_, __) {},
      ));

      // Assert - main venue should be set to first venue
      // Note: This happens in initState, so we check via UI
      expect(find.byType(Radio<String>), findsOneWidget);
    });

    testWidgets('should call onChanged with removed venue',
        (WidgetTester tester) async {
      // Arrange
      List<Venue>? changedVenues;
      String? changedMainId;

      await tester.pumpWidget(createWidgetUnderTest(
        initialVenues: [testVenue1, testVenue2],
        initialMainVenueId: testVenue1.venueId,
        onChanged: (venues, mainId) {
          changedVenues = venues;
          changedMainId = mainId;
        },
      ));

      // Act - find and tap delete button for venue1
      final deleteButtons = find.byIcon(Icons.delete);
      expect(deleteButtons, findsNWidgets(2));
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Assert
      expect(changedVenues, isNotNull);
      expect(changedVenues!.length, equals(1));
      expect(changedVenues!.first.venueId, equals('venue2'));
      expect(changedMainId, equals('venue2'));
    });

    testWidgets('should show helper text about main venue',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(
        initialVenues: [testVenue1],
        onChanged: (venues, mainId) {},
      ));

      // Assert
      expect(
          find.text('* המגרש המסומן הוא המגרש הראשי של ה-Hub'), findsOneWidget);
    });
  });
}
