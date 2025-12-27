import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Architecture tests to enforce layer boundaries
///
/// These tests ensure that:
/// 1. Domain layer doesn't import infrastructure
/// 2. Domain layer doesn't import Firebase
/// 3. All models use value objects instead of primitives
void main() {
  group('Layer Boundary Tests', () {
    test('Domain layer must not import cloud_firestore', () {
      final violations = <String>[];

      // Check all domain layer files
      final domainDirs = [
        'lib/features/hubs/domain',
        'lib/features/games/domain',
        'lib/features/profile/domain',
        'lib/features/venues/domain',
        'lib/features/social/domain',
        'lib/shared/domain',
      ];

      for (final dir in domainDirs) {
        final directory = Directory(dir);
        if (!directory.existsSync()) continue;

        final files = directory
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => !file.path.contains('.g.dart'))
            .where((file) => !file.path.contains('.freezed.dart'));

        for (final file in files) {
          final content = file.readAsStringSync();

          // Check for forbidden imports
          if (content.contains("import 'package:cloud_firestore/")) {
            violations.add('${file.path}: imports cloud_firestore (FORBIDDEN in domain)');
          }

          if (content.contains("import 'package:firebase_")) {
            violations.add('${file.path}: imports firebase package (FORBIDDEN in domain)');
          }
        }
      }

      if (violations.isNotEmpty) {
        fail('Domain layer violations found:\n${violations.join('\n')}');
      }
    });

    test('Domain models use GeographicPoint instead of GeoPoint', () {
      final violations = <String>[];

      final modelFiles = [
        'lib/features/hubs/domain/models/hub.dart',
        'lib/features/games/domain/models/game.dart',
        'lib/features/profile/domain/models/user.dart',
        'lib/features/venues/domain/models/venue.dart',
        'lib/features/hubs/domain/models/hub_event.dart',
      ];

      for (final filePath in modelFiles) {
        final file = File(filePath);
        if (!file.existsSync()) continue;

        final content = file.readAsStringSync();

        // Check for GeoPoint usage (should use GeographicPoint)
        if (content.contains('GeoPoint') &&
            !content.contains('GeographicPoint') &&
            !content.contains('// ignore')) {
          violations.add('$filePath: Uses GeoPoint instead of GeographicPoint');
        }
      }

      if (violations.isNotEmpty) {
        fail('Domain models use infrastructure types:\n${violations.join('\n')}');
      }
    });

    test('Infrastructure converters isolated to infrastructure layer', () {
      final violations = <String>[];

      // Converters should only be in infrastructure layer
      final converterDirs = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('_converter.dart'))
          .where((file) => !file.path.contains('infrastructure'));

      for (final file in converterDirs) {
        violations.add('${file.path}: Converter outside infrastructure layer');
      }

      if (violations.isNotEmpty) {
        fail('Converters must be in infrastructure layer:\n${violations.join('\n')}');
      }
    });

    test('Value objects are in shared/domain/models/value_objects', () {
      final violations = <String>[];

      final valueObjectFiles = [
        'lib/shared/domain/models/value_objects/geographic_point.dart',
        'lib/shared/domain/models/value_objects/entity_id.dart',
        'lib/shared/domain/models/value_objects/time_range.dart',
        'lib/shared/domain/models/value_objects/user_location.dart',
      ];

      for (final filePath in valueObjectFiles) {
        final file = File(filePath);
        if (!file.existsSync()) {
          violations.add('$filePath: Value object missing');
        }
      }

      if (violations.isNotEmpty) {
        fail('Value objects missing:\n${violations.join('\n')}');
      }
    });

    test('Repositories use dependency injection (no direct instantiation)', () {
      final violations = <String>[];

      // Check presentation layer for Service Locator pattern
      final presentationDirs = [
        'lib/features/hubs/presentation',
        'lib/features/games/presentation',
        'lib/features/profile/presentation',
        'lib/screens',
        'lib/widgets',
      ];

      final repositoryPattern = RegExp(r'=\s*\w+Repository\s*\(');

      for (final dir in presentationDirs) {
        final directory = Directory(dir);
        if (!directory.existsSync()) continue;

        final files = directory
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => !file.path.contains('.g.dart'))
            .where((file) => !file.path.contains('.freezed.dart'));

        for (final file in files) {
          final content = file.readAsStringSync();
          final lines = content.split('\n');

          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];

            // Skip provider definitions
            if (line.contains('@riverpod') ||
                line.contains('Provider(') ||
                line.contains('ref.watch') ||
                line.contains('ref.read')) {
              continue;
            }

            if (repositoryPattern.hasMatch(line)) {
              violations.add('${file.path}:${i + 1}: Direct repository instantiation (use DI)');
            }
          }
        }
      }

      if (violations.isNotEmpty) {
        fail('Service Locator violations found:\n${violations.join('\n')}');
      }
    });
  });

  group('Value Object Tests', () {
    test('GeographicPoint has required business logic methods', () {
      final file = File('lib/shared/domain/models/value_objects/geographic_point.dart');
      expect(file.existsSync(), isTrue, reason: 'GeographicPoint must exist');

      final content = file.readAsStringSync();

      // Check for required methods
      expect(content, contains('distanceToKm'), reason: 'Must have distanceToKm method');
      expect(content, contains('isWithinRadius'), reason: 'Must have isWithinRadius method');
      expect(content, contains('bearingTo'), reason: 'Must have bearingTo method');
      expect(content, contains('isValid'), reason: 'Must have isValid getter');
    });

    test('TimeRange has required business logic methods', () {
      final file = File('lib/shared/domain/models/value_objects/time_range.dart');
      expect(file.existsSync(), isTrue, reason: 'TimeRange must exist');

      final content = file.readAsStringSync();

      // Check for required methods
      expect(content, contains('overlaps'), reason: 'Must have overlaps method');
      expect(content, contains('duration'), reason: 'Must have duration getter');
      expect(content, contains('isActive'), reason: 'Must have isActive getter');
      expect(content, contains('contains'), reason: 'Must have contains method');
    });

    test('Entity IDs have type safety', () {
      final file = File('lib/shared/domain/models/value_objects/entity_id.dart');
      expect(file.existsSync(), isTrue, reason: 'EntityId must exist');

      final content = file.readAsStringSync();

      // Check for typed IDs
      expect(content, contains('class HubId'), reason: 'Must have HubId');
      expect(content, contains('class GameId'), reason: 'Must have GameId');
      expect(content, contains('class UserId'), reason: 'Must have UserId');
      expect(content, contains('class EventId'), reason: 'Must have EventId');
      expect(content, contains('class VenueId'), reason: 'Must have VenueId');
    });
  });

  group('Documentation Tests', () {
    test('Architecture documentation exists', () {
      final architectureDoc = File('docs/ARCHITECTURE.md');
      expect(architectureDoc.existsSync(), isTrue,
        reason: 'ARCHITECTURE.md must exist');

      final content = architectureDoc.readAsStringSync();
      expect(content.length, greaterThan(1000),
        reason: 'Architecture doc must be comprehensive');
    });

    test('Migration documentation exists', () {
      final migrationDoc = File('docs/MIGRATION_COMPLETE.md');
      expect(migrationDoc.existsSync(), isTrue,
        reason: 'MIGRATION_COMPLETE.md must exist');
    });
  });
}
