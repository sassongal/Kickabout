import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kattrick/features/hubs/domain/services/hub_permissions_service.dart';
import 'package:kattrick/models/hub.dart';
import 'package:kattrick/models/hub_member.dart';
import 'package:kattrick/models/hub_role.dart';
import '../helpers/mock_firestore.dart';

void main() {
  group('HubMemberRolePermissions', () {
    group('canCreateGames', () {
      test('all roles can create games', () {
        expect(HubMemberRole.manager.canCreateGames, isTrue);
        expect(HubMemberRole.moderator.canCreateGames, isTrue);
        expect(HubMemberRole.veteran.canCreateGames, isTrue);
        expect(HubMemberRole.member.canCreateGames, isTrue);
      });
    });

    group('canCreateEvents', () {
      test('only manager and moderator can create events', () {
        expect(HubMemberRole.manager.canCreateEvents, isTrue);
        expect(HubMemberRole.moderator.canCreateEvents, isTrue);
        expect(HubMemberRole.veteran.canCreateEvents, isFalse);
        expect(HubMemberRole.member.canCreateEvents, isFalse);
      });
    });

    group('canRecordResults', () {
      test('manager, moderator, and veteran can record results', () {
        expect(HubMemberRole.manager.canRecordResults, isTrue);
        expect(HubMemberRole.moderator.canRecordResults, isTrue);
        expect(HubMemberRole.veteran.canRecordResults, isTrue);
        expect(HubMemberRole.member.canRecordResults, isFalse);
      });
    });

    group('canInvitePlayers', () {
      test('manager, moderator, and veteran can invite players', () {
        expect(HubMemberRole.manager.canInvitePlayers, isTrue);
        expect(HubMemberRole.moderator.canInvitePlayers, isTrue);
        expect(HubMemberRole.veteran.canInvitePlayers, isTrue);
        expect(HubMemberRole.member.canInvitePlayers, isFalse);
      });
    });

    group('canViewAnalytics', () {
      test('manager, moderator, and veteran can view analytics', () {
        expect(HubMemberRole.manager.canViewAnalytics, isTrue);
        expect(HubMemberRole.moderator.canViewAnalytics, isTrue);
        expect(HubMemberRole.veteran.canViewAnalytics, isTrue);
        expect(HubMemberRole.member.canViewAnalytics, isFalse);
      });
    });

    group('canManageMembers', () {
      test('only manager and moderator can manage members', () {
        expect(HubMemberRole.manager.canManageMembers, isTrue);
        expect(HubMemberRole.moderator.canManageMembers, isTrue);
        expect(HubMemberRole.veteran.canManageMembers, isFalse);
        expect(HubMemberRole.member.canManageMembers, isFalse);
      });
    });

    group('canManageRoles', () {
      test('only manager can manage roles', () {
        expect(HubMemberRole.manager.canManageRoles, isTrue);
        expect(HubMemberRole.moderator.canManageRoles, isFalse);
        expect(HubMemberRole.veteran.canManageRoles, isFalse);
        expect(HubMemberRole.member.canManageRoles, isFalse);
      });
    });

    group('canManageSettings', () {
      test('only manager can manage settings', () {
        expect(HubMemberRole.manager.canManageSettings, isTrue);
        expect(HubMemberRole.moderator.canManageSettings, isFalse);
        expect(HubMemberRole.veteran.canManageSettings, isFalse);
        expect(HubMemberRole.member.canManageSettings, isFalse);
      });
    });

    group('isAtLeast', () {
      test('role hierarchy comparison works correctly', () {
        // Manager is at least everything
        expect(HubMemberRole.manager.isAtLeast(HubMemberRole.manager), isTrue);
        expect(HubMemberRole.manager.isAtLeast(HubMemberRole.moderator), isTrue);
        expect(HubMemberRole.manager.isAtLeast(HubMemberRole.veteran), isTrue);
        expect(HubMemberRole.manager.isAtLeast(HubMemberRole.member), isTrue);

        // Moderator is at least moderator, veteran, member
        expect(HubMemberRole.moderator.isAtLeast(HubMemberRole.manager), isFalse);
        expect(HubMemberRole.moderator.isAtLeast(HubMemberRole.moderator), isTrue);
        expect(HubMemberRole.moderator.isAtLeast(HubMemberRole.veteran), isTrue);
        expect(HubMemberRole.moderator.isAtLeast(HubMemberRole.member), isTrue);

        // Veteran is at least veteran, member
        expect(HubMemberRole.veteran.isAtLeast(HubMemberRole.manager), isFalse);
        expect(HubMemberRole.veteran.isAtLeast(HubMemberRole.moderator), isFalse);
        expect(HubMemberRole.veteran.isAtLeast(HubMemberRole.veteran), isTrue);
        expect(HubMemberRole.veteran.isAtLeast(HubMemberRole.member), isTrue);

        // Member is only at least member
        expect(HubMemberRole.member.isAtLeast(HubMemberRole.manager), isFalse);
        expect(HubMemberRole.member.isAtLeast(HubMemberRole.moderator), isFalse);
        expect(HubMemberRole.member.isAtLeast(HubMemberRole.veteran), isFalse);
        expect(HubMemberRole.member.isAtLeast(HubMemberRole.member), isTrue);
      });
    });
  });

  group('HubPermissions', () {
    late Hub testHub;
    final now = DateTime.now();

    setUp(() {
      testHub = Hub(
        hubId: 'hub123',
        name: 'Test Hub',
        createdBy: 'creator123',
        createdAt: now,
        memberCount: 5,
      );
    });

    group('effectiveRole', () {
      test('hub creator is always manager regardless of membership', () {
        // Without membership
        final permissions = HubPermissions(
          hub: testHub,
          userId: 'creator123',
          membership: null,
        );
        expect(permissions.effectiveRole, HubMemberRole.manager);
        expect(permissions.isManager, isTrue);

        // With member membership (should still be manager)
        final memberMembership = HubMember(
          hubId: 'hub123',
          userId: 'creator123',
          joinedAt: now,
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
        );
        final permissionsWithMembership = HubPermissions(
          hub: testHub,
          userId: 'creator123',
          membership: memberMembership,
        );
        expect(permissionsWithMembership.effectiveRole, HubMemberRole.manager);
      });

      test('non-creator with no membership defaults to member role', () {
        final permissions = HubPermissions(
          hub: testHub,
          userId: 'user456',
          membership: null,
        );
        expect(permissions.effectiveRole, HubMemberRole.member);
        expect(permissions.isActive, isFalse); // Not active without membership
      });

      test('non-creator with active membership uses membership role', () {
        final membership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.moderator,
          status: HubMemberStatus.active,
        );
        final permissions = HubPermissions(
          hub: testHub,
          userId: 'user456',
          membership: membership,
        );
        expect(permissions.effectiveRole, HubMemberRole.moderator);
        expect(permissions.isModerator, isTrue);
      });

      test('inactive membership (left) defaults to member role', () {
        final leftMembership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.moderator,
          status: HubMemberStatus.left,
        );
        final permissions = HubPermissions(
          hub: testHub,
          userId: 'user456',
          membership: leftMembership,
        );
        expect(permissions.isActive, isFalse);
        expect(permissions.isGuest, isTrue);
      });

      test('banned membership is not active', () {
        final bannedMembership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.member,
          status: HubMemberStatus.banned,
        );
        final permissions = HubPermissions(
          hub: testHub,
          userId: 'user456',
          membership: bannedMembership,
        );
        expect(permissions.isActive, isFalse);
        expect(permissions.canCreateGames, isFalse);
      });
    });

    group('permissions with active check', () {
      test('inactive member has no permissions', () {
        final inactiveMembership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.manager, // Even manager role
          status: HubMemberStatus.left,
        );
        final permissions = HubPermissions(
          hub: testHub,
          userId: 'user456',
          membership: inactiveMembership,
        );

        expect(permissions.canCreateGames, isFalse);
        expect(permissions.canCreateEvents, isFalse);
        expect(permissions.canRecordResults, isFalse);
        expect(permissions.canManageMembers, isFalse);
      });

      test('active member has appropriate permissions', () {
        final membership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
        );
        final permissions = HubPermissions(
          hub: testHub,
          userId: 'user456',
          membership: membership,
        );

        expect(permissions.canCreateGames, isTrue);
        expect(permissions.canCreateEvents, isFalse);
        expect(permissions.canRecordResults, isFalse);
        expect(permissions.canManageMembers, isFalse);
      });

      test('active veteran has veteran permissions', () {
        final veteranMembership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 70)),
          role: HubMemberRole.veteran,
          status: HubMemberStatus.active,
          veteranSince: now.subtract(Duration(days: 10)),
        );
        final permissions = HubPermissions(
          hub: testHub,
          userId: 'user456',
          membership: veteranMembership,
        );

        expect(permissions.canCreateGames, isTrue);
        expect(permissions.canRecordResults, isTrue);
        expect(permissions.canInvitePlayers, isTrue);
        expect(permissions.canViewAnalytics, isTrue);
        expect(permissions.canCreateEvents, isFalse);
        expect(permissions.canManageMembers, isFalse);
        expect(permissions.isVeteran, isTrue);
      });

      test('creator always has all permissions', () {
        final permissions = HubPermissions(
          hub: testHub,
          userId: 'creator123',
          membership: null,
        );

        expect(permissions.isActive, isTrue);
        expect(permissions.canCreateGames, isTrue);
        expect(permissions.canCreateEvents, isTrue);
        expect(permissions.canRecordResults, isTrue);
        expect(permissions.canManageMembers, isTrue);
        expect(permissions.canManageRoles, isTrue);
        expect(permissions.canManageSettings, isTrue);
      });
    });

    group('custom permission overrides', () {
      test('custom canCreateEvents permission overrides role', () {
        final hubWithCustomPerms = Hub(
          hubId: 'hub123',
          name: 'Test Hub',
          createdBy: 'creator123',
          createdAt: now,
          memberCount: 5,
          permissions: {
            'canCreateEvents': ['user456'],
          },
        );

        final memberMembership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
        );

        final permissions = HubPermissions(
          hub: hubWithCustomPerms,
          userId: 'user456',
          membership: memberMembership,
        );

        // Member normally can't create events, but custom permission allows it
        expect(permissions.canCreateEvents, isTrue);
        expect(permissions.canCreateGames, isTrue);
      });

      test('custom canCreatePosts permission overrides role', () {
        final hubWithCustomPerms = Hub(
          hubId: 'hub123',
          name: 'Test Hub',
          createdBy: 'creator123',
          createdAt: now,
          memberCount: 5,
          permissions: {
            'canCreatePosts': ['user789'],
          },
        );

        final memberMembership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.member,
          status: HubMemberStatus.active,
        );

        final permissionsAllowed = HubPermissions(
          hub: hubWithCustomPerms,
          userId: 'user789',
          membership: memberMembership,
        );
        expect(permissionsAllowed.canCreatePosts, isTrue);

        final permissionsDefault = HubPermissions(
          hub: hubWithCustomPerms,
          userId: 'user456',
          membership: memberMembership,
        );
        expect(permissionsDefault.canCreatePosts, isFalse);
      });
    });

    group('backward compatibility', () {
      test('userRole maps HubMemberRole to HubRole', () {
        final managerMembership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.manager,
          status: HubMemberStatus.active,
        );
        final managerPerms = HubPermissions(
          hub: testHub,
          userId: 'user456',
          membership: managerMembership,
        );
        expect(managerPerms.userRole, HubRole.manager);

        final moderatorMembership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.moderator,
          status: HubMemberStatus.active,
        );
        final moderatorPerms = HubPermissions(
          hub: testHub,
          userId: 'user456',
          membership: moderatorMembership,
        );
        expect(moderatorPerms.userRole, HubRole.moderator);

        final veteranMembership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.veteran,
          status: HubMemberStatus.active,
        );
        final veteranPerms = HubPermissions(
          hub: testHub,
          userId: 'user456',
          membership: veteranMembership,
        );
        expect(veteranPerms.userRole, HubRole.veteran);
      });

      test('inactive user maps to guest', () {
        final permissions = HubPermissions(
          hub: testHub,
          userId: 'user456',
          membership: null,
        );
        expect(permissions.userRole, HubRole.guest);
      });
    });

    group('toDebugInfo', () {
      test('returns comprehensive debug information', () {
        final veteranMembership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now.subtract(Duration(days: 70)),
          role: HubMemberRole.veteran,
          status: HubMemberStatus.active,
          veteranSince: now.subtract(Duration(days: 10)),
        );
        final permissions = HubPermissions(
          hub: testHub,
          userId: 'user456',
          membership: veteranMembership,
        );

        final debug = permissions.toDebugInfo();

        expect(debug['userId'], 'user456');
        expect(debug['hubId'], 'hub123');
        expect(debug['effectiveRole'], 'veteran');
        expect(debug['isActive'], isTrue);
        expect(debug['isCreator'], isFalse);
        expect(debug['membershipStatus'], 'active');
        expect(debug['isVeteran'], isTrue);
        expect(debug['veteranSince'], isNotNull);
      });
    });
  });

  group('HubPermissionsService', () {
    late HubPermissionsService service;
    late MockFirebaseFirestore mockFirestore;
    late MockDocumentReference mockMemberRef;
    late MockDocumentSnapshot mockMemberDoc;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockMemberRef = MockDocumentReference();
      mockMemberDoc = MockDocumentSnapshot();
      service = HubPermissionsService(mockFirestore);
    });

    group('getMembership', () {
      test('returns null when member document does not exist', () async {
        // Arrange
        when(() => mockFirestore.doc('hubs/hub123/members/user456'))
            .thenReturn(mockMemberRef);
        when(() => mockMemberRef.get()).thenAnswer((_) async => mockMemberDoc);
        when(() => mockMemberDoc.exists).thenReturn(false);

        // Act
        final result = await service.getMembership('hub123', 'user456');

        // Assert
        expect(result, isNull);
      });

      test('returns HubMember when document exists', () async {
        // Arrange
        final now = DateTime.now();
        final memberData = {
          'hubId': 'hub123',
          'userId': 'user456',
          'joinedAt': Timestamp.fromDate(now),
          'role': 'member',
          'status': 'active',
          'managerRating': 5.0,
        };

        when(() => mockFirestore.doc('hubs/hub123/members/user456'))
            .thenReturn(mockMemberRef);
        when(() => mockMemberRef.get()).thenAnswer((_) async => mockMemberDoc);
        when(() => mockMemberDoc.exists).thenReturn(true);
        when(() => mockMemberDoc.data()).thenReturn(memberData);

        // Act
        final result = await service.getMembership('hub123', 'user456');

        // Assert
        expect(result, isNotNull);
        expect(result!.hubId, 'hub123');
        expect(result.userId, 'user456');
        expect(result.role, HubMemberRole.member);
        expect(result.status, HubMemberStatus.active);
      });

      test('handles parsing errors gracefully', () async {
        // Arrange
        final invalidData = {
          'hubId': 'hub123',
          'userId': 'user456',
          // Missing required joinedAt field
        };

        when(() => mockFirestore.doc('hubs/hub123/members/user456'))
            .thenReturn(mockMemberRef);
        when(() => mockMemberRef.get()).thenAnswer((_) async => mockMemberDoc);
        when(() => mockMemberDoc.exists).thenReturn(true);
        when(() => mockMemberDoc.data()).thenReturn(invalidData);

        // Act & Assert
        expect(
          () => service.getMembership('hub123', 'user456'),
          throwsA(isA<Error>()), // Will throw during fromJson
        );
      });
    });

    group('createPermissions', () {
      test('creates HubPermissions from provided data', () {
        // Arrange
        final now = DateTime.now();
        final hub = Hub(
          hubId: 'hub123',
          name: 'Test Hub',
          createdBy: 'creator123',
          createdAt: now,
          memberCount: 5,
        );
        final membership = HubMember(
          hubId: 'hub123',
          userId: 'user456',
          joinedAt: now,
          role: HubMemberRole.moderator,
          status: HubMemberStatus.active,
        );

        // Act
        final permissions = service.createPermissions(hub, membership, 'user456');

        // Assert
        expect(permissions.effectiveRole, HubMemberRole.moderator);
        expect(permissions.canCreateEvents, isTrue);
        expect(permissions.isModerator, isTrue);
      });

      test('handles null membership', () {
        // Arrange
        final now = DateTime.now();
        final hub = Hub(
          hubId: 'hub123',
          name: 'Test Hub',
          createdBy: 'creator123',
          createdAt: now,
          memberCount: 5,
        );

        // Act
        final permissions = service.createPermissions(hub, null, 'user456');

        // Assert
        expect(permissions.isActive, isFalse);
        expect(permissions.isGuest, isTrue);
      });
    });
  });
}
