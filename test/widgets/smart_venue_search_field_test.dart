import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kattrick/widgets/input/smart_venue_search_field.dart';
import 'package:kattrick/features/venues/domain/models/venue.dart';
import 'package:kattrick/features/venues/data/repositories/venues_repository.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';

// Mock classes
class MockVenuesRepository extends Mock implements VenuesRepository {}

void main() {
  late MockVenuesRepository mockVenuesRepository;
  
  setUp(() {
    mockVenuesRepository = MockVenuesRepository();
  });
  
  Widget createWidgetUnderTest({
    required Function(Venue) onVenueSelected,
  }) {
    return ProviderScope(
      overrides: [
        venuesRepositoryProvider.overrideWithValue(mockVenuesRepository),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SmartVenueSearchField(
            onVenueSelected: onVenueSelected,
          ),
        ),
      ),
    );
  }
  
  group('SmartVenueSearchField Widget Tests', () {
    testWidgets('should display search field with label and hint', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(
        onVenueSelected: (venue) {},
      ));
      
      // Act & Assert
      expect(find.text('כתובת או שם מגרש'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
    
    testWidgets('should not show options when text is less than 2 characters', (WidgetTester tester) async {
      // Arrange
      when(() => mockVenuesRepository.searchVenuesCombined(any()))
          .thenAnswer((_) async => []);
      
      await tester.pumpWidget(createWidgetUnderTest(
        onVenueSelected: (venue) {},
      ));
      
      // Act
      await tester.enterText(find.byType(TextFormField), 'א');
      await tester.pump();
      
      // Assert
      verifyNever(() => mockVenuesRepository.searchVenuesCombined('א'));
    });
    
    testWidgets('should search when text is 2 or more characters', (WidgetTester tester) async {
      // Arrange
      final testVenue = Venue(
        venueId: 'venue1',
        hubId: 'hub1',
        name: 'מגרש טסט',
        location: const GeographicPoint(latitude: 32.0, longitude: 34.0),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      when(() => mockVenuesRepository.searchVenuesCombined(any()))
          .thenAnswer((_) async => [testVenue]);
      
      await tester.pumpWidget(createWidgetUnderTest(
        onVenueSelected: (venue) {},
      ));
      
      // Act
      await tester.enterText(find.byType(TextFormField), 'טס');
      await tester.pumpAndSettle();
      
      // Assert
      verify(() => mockVenuesRepository.searchVenuesCombined('טס')).called(greaterThan(0));
    });
    
    testWidgets('should call onVenueSelected when venue is tapped', (WidgetTester tester) async {
      // Arrange
      final testVenue = Venue(
        venueId: 'venue1',
        hubId: 'hub1',
        name: 'מגרש טסט',
        address: 'כתובת טסט',
        location: const GeographicPoint(latitude: 32.0, longitude: 34.0),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      when(() => mockVenuesRepository.searchVenuesCombined(any()))
          .thenAnswer((_) async => [testVenue]);
      
      Venue? selectedVenue;
      
      await tester.pumpWidget(createWidgetUnderTest(
        onVenueSelected: (venue) {
          selectedVenue = venue;
        },
      ));
      
      // Act
      await tester.enterText(find.byType(TextFormField), 'טס');
      await tester.pumpAndSettle();
      
      // Tap on the venue option
      await tester.tap(find.text('מגרש טסט'));
      await tester.pumpAndSettle();
      
      // Assert
      expect(selectedVenue, isNotNull);
      expect(selectedVenue!.name, equals('מגרש טסט'));
    });
    
    testWidgets('should show verified icon for venues with venueId', (WidgetTester tester) async {
      // Arrange
      final verifiedVenue = Venue(
        venueId: 'venue1', // Has ID = verified
        hubId: 'hub1',
        name: 'מגרש מאומת',
        location: const GeographicPoint(latitude: 32.0, longitude: 34.0),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      when(() => mockVenuesRepository.searchVenuesCombined(any()))
          .thenAnswer((_) async => [verifiedVenue]);
      
      await tester.pumpWidget(createWidgetUnderTest(
        onVenueSelected: (venue) {},
      ));
      
      // Act
      await tester.enterText(find.byType(TextFormField), 'מא');
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });
  });
}

