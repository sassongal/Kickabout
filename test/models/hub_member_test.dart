import 'package:flutter_test/flutter_test.dart';
import 'package:kattrick/features/hubs/domain/models/hub_member.dart';

void main() {
  group('HubMember', () {
    final now = DateTime.now();

    group('isVeteran', () {
      test('returns true when veteranSince is set', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 70)),
          role: HubMemberRole.veteran,
          status: HubMemberStatus.active,
          veteranSince: now.subtract(Duration(days: 10)),
        );

        expect(member.isVeteran, isTrue);
      });

      test('returns false when veteranSince is null', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 30)),
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
        );

        expect(member.isVeteran, isFalse);
      });

      test('returns false for newly joined member', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
        );

        expect(member.isVeteran, isFalse);
      });
    });

    group('daysSinceJoined', () {
      test('calculates correct days for recent join', () {
        final joinDate = now.subtract(Duration(days: 5));
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: joinDate,
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
        );

        expect(member.daysSinceJoined, greaterThanOrEqualTo(5));
        expect(member.daysSinceJoined, lessThanOrEqualTo(6)); // Account for test execution time
      });

      test('calculates correct days for old member', () {
        final joinDate = now.subtract(Duration(days: 100));
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: joinDate,
          role: HubMemberRole.veteran,
          status: HubMemberStatus.active,
          veteranSince: now.subtract(Duration(days: 40)),
        );

        expect(member.daysSinceJoined, greaterThanOrEqualTo(100));
        expect(member.daysSinceJoined, lessThanOrEqualTo(101));
      });

      test('returns 0 for member joined today', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
        );

        expect(member.daysSinceJoined, equals(0));
      });
    });

    group('isActive', () {
      test('returns true for active status', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
        );

        expect(member.isActive, isTrue);
      });

      test('returns false for left status', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 30)),
          role: HubMemberRole.member,
          status: HubMemberStatus.left,
        );

        expect(member.isActive, isFalse);
      });

      test('returns false for banned status', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 10)),
          role: HubMemberRole.member,
          status: HubMemberStatus.banned,
          statusReason: 'Violation of rules',
        );

        expect(member.isActive, isFalse);
      });
    });

    group('canPromoteToVeteran', () {
      test('returns true for eligible member', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 65)),
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
        );

        expect(member.canPromoteToVeteran, isTrue);
      });

      test('returns false if already veteran', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 70)),
          role: HubMemberRole.veteran,
          status: HubMemberStatus.active,
          veteranSince: now.subtract(Duration(days: 10)),
        );

        expect(member.canPromoteToVeteran, isFalse);
      });

      test('returns false if veteranSince is already set', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 65)),
          role: HubMemberRole.member, // Still member role but has veteranSince
          status: HubMemberStatus.active,
          veteranSince: now,
        );

        expect(member.canPromoteToVeteran, isFalse);
      });

      test('returns false if not active', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 70)),
          role: HubMemberRole.member,
          status: HubMemberStatus.left,
        );

        expect(member.canPromoteToVeteran, isFalse);
      });

      test('returns false if role is moderator', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 70)),
          role: HubMemberRole.moderator,
          status: HubMemberStatus.active,
        );

        expect(member.canPromoteToVeteran, isFalse);
      });

      test('returns false if role is manager', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 70)),
          role: HubMemberRole.manager,
          status: HubMemberStatus.active,
        );

        expect(member.canPromoteToVeteran, isFalse);
      });
    });

    group('audit trail fields', () {
      test('stores updatedAt and updatedBy', () {
        final updatedAt = now;
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 5)),
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
          updatedAt: updatedAt,
          updatedBy: 'admin123',
        );

        expect(member.updatedAt, equals(updatedAt));
        expect(member.updatedBy, equals('admin123'));
      });

      test('stores statusReason for bans', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 10)),
          role: HubMemberRole.member,
          status: HubMemberStatus.banned,
          statusReason: 'Repeated violations of community guidelines',
          updatedBy: 'manager123',
        );

        expect(member.status, HubMemberStatus.banned);
        expect(member.statusReason, equals('Repeated violations of community guidelines'));
        expect(member.updatedBy, equals('manager123'));
      });
    });

    group('managerRating field', () {
      test('stores custom rating from manager', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
          managerRating: 7.5,
        );

        expect(member.managerRating, equals(7.5));
      });

      test('defaults to 0.0 when not set', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
        );

        expect(member.managerRating, equals(0.0));
      });
    });

    group('lastActiveAt tracking', () {
      test('stores last activity timestamp', () {
        final lastActive = now.subtract(Duration(hours: 2));
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 30)),
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
          lastActiveAt: lastActive,
        );

        expect(member.lastActiveAt, equals(lastActive));
      });

      test('can be null for never-active member', () {
        final member = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
        );

        expect(member.lastActiveAt, isNull);
      });
    });
  });

  group('HubMemberRole', () {
    group('fromString', () {
      test('parses all valid role strings', () {
        expect(HubMemberRole.fromString('manager'), HubMemberRole.manager);
        expect(HubMemberRole.fromString('moderator'), HubMemberRole.moderator);
        expect(HubMemberRole.fromString('veteran'), HubMemberRole.veteran);
        expect(HubMemberRole.fromString('member'), HubMemberRole.member);
      });

      test('defaults to member for invalid string', () {
        expect(HubMemberRole.fromString('invalid'), HubMemberRole.member);
        expect(HubMemberRole.fromString(''), HubMemberRole.member);
        expect(HubMemberRole.fromString('MANAGER'), HubMemberRole.member); // Case sensitive
      });
    });

    group('fromFirestore', () {
      test('parses all valid role strings', () {
        expect(HubMemberRole.fromFirestore('manager'), HubMemberRole.manager);
        expect(HubMemberRole.fromFirestore('moderator'), HubMemberRole.moderator);
        expect(HubMemberRole.fromFirestore('veteran'), HubMemberRole.veteran);
        expect(HubMemberRole.fromFirestore('member'), HubMemberRole.member);
      });

      test('handles legacy admin role', () {
        expect(HubMemberRole.fromFirestore('admin'), HubMemberRole.manager);
      });

      test('defaults to guest (via HubRole) for invalid string', () {
        // Note: HubMemberRole doesn't have 'guest', guest is handled by HubRole
        // Invalid strings default to member in HubMemberRole
        expect(HubMemberRole.fromFirestore('invalid'), HubMemberRole.member);
        expect(HubMemberRole.fromFirestore(''), HubMemberRole.member);
      });
    });

    group('firestoreValue', () {
      test('returns correct string for each role', () {
        expect(HubMemberRole.manager.firestoreValue, 'manager');
        expect(HubMemberRole.moderator.firestoreValue, 'moderator');
        expect(HubMemberRole.veteran.firestoreValue, 'veteran');
        expect(HubMemberRole.member.firestoreValue, 'member');
      });
    });

    group('displayName', () {
      test('returns Hebrew display name for each role', () {
        expect(HubMemberRole.manager.displayName, 'מנהל');
        expect(HubMemberRole.moderator.displayName, 'מנחה');
        expect(HubMemberRole.veteran.displayName, 'שחקן ותיק');
        expect(HubMemberRole.member.displayName, 'חבר');
      });
    });

    group('isAtLeast', () {
      test('manager is at least any role', () {
        expect(HubMemberRole.manager.isAtLeast(HubMemberRole.manager), isTrue);
        expect(HubMemberRole.manager.isAtLeast(HubMemberRole.moderator), isTrue);
        expect(HubMemberRole.manager.isAtLeast(HubMemberRole.veteran), isTrue);
        expect(HubMemberRole.manager.isAtLeast(HubMemberRole.member), isTrue);
      });

      test('moderator hierarchy', () {
        expect(HubMemberRole.moderator.isAtLeast(HubMemberRole.manager), isFalse);
        expect(HubMemberRole.moderator.isAtLeast(HubMemberRole.moderator), isTrue);
        expect(HubMemberRole.moderator.isAtLeast(HubMemberRole.veteran), isTrue);
        expect(HubMemberRole.moderator.isAtLeast(HubMemberRole.member), isTrue);
      });

      test('veteran hierarchy', () {
        expect(HubMemberRole.veteran.isAtLeast(HubMemberRole.manager), isFalse);
        expect(HubMemberRole.veteran.isAtLeast(HubMemberRole.moderator), isFalse);
        expect(HubMemberRole.veteran.isAtLeast(HubMemberRole.veteran), isTrue);
        expect(HubMemberRole.veteran.isAtLeast(HubMemberRole.member), isTrue);
      });

      test('member hierarchy', () {
        expect(HubMemberRole.member.isAtLeast(HubMemberRole.manager), isFalse);
        expect(HubMemberRole.member.isAtLeast(HubMemberRole.moderator), isFalse);
        expect(HubMemberRole.member.isAtLeast(HubMemberRole.veteran), isFalse);
        expect(HubMemberRole.member.isAtLeast(HubMemberRole.member), isTrue);
      });
    });
  });

  group('HubMemberStatus', () {
    group('fromString', () {
      test('parses all valid status strings', () {
        expect(HubMemberStatus.fromString('active'), HubMemberStatus.active);
        expect(HubMemberStatus.fromString('left'), HubMemberStatus.left);
        expect(HubMemberStatus.fromString('banned'), HubMemberStatus.banned);
      });

      test('defaults to active for invalid string', () {
        expect(HubMemberStatus.fromString('invalid'), HubMemberStatus.active);
        expect(HubMemberStatus.fromString(''), HubMemberStatus.active);
      });
    });

    group('firestoreValue', () {
      test('returns correct string for each status', () {
        expect(HubMemberStatus.active.firestoreValue, 'active');
        expect(HubMemberStatus.left.firestoreValue, 'left');
        expect(HubMemberStatus.banned.firestoreValue, 'banned');
      });
    });

    group('displayName', () {
      test('returns Hebrew display name for each status', () {
        expect(HubMemberStatus.active.displayName, 'פעיל');
        expect(HubMemberStatus.left.displayName, 'עזב');
        expect(HubMemberStatus.banned.displayName, 'חסום');
      });
    });
  });
}
