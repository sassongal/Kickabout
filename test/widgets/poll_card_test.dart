import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kattrick/models/poll.dart';
import 'package:kattrick/models/user.dart';
import 'package:kattrick/routing/app_router.dart';
import 'package:kattrick/widgets/polls/poll_card.dart';

void main() {
  group('PollCard Widget Tests', () {
    late Poll testPoll;
    late User testUser;

    setUp(() {
      testUser = User(
        uid: 'user1',
        name: 'Test User',
        email: 'test@test.com',
        photoUrl: null,
        hubIds: ['hub1'],
        createdAt: DateTime.now(),
      );

      testPoll = Poll(
        pollId: 'poll1',
        hubId: 'hub1',
        createdBy: 'creator1',
        question: 'Where should we play?',
        options: [
          const PollOption(
            optionId: 'opt1',
            text: 'Park A',
            voteCount: 5,
            voters: ['user2', 'user3'],
          ),
          const PollOption(
            optionId: 'opt2',
            text: 'Park B',
            voteCount: 10,
            voters: ['user4', 'user5'],
          ),
          const PollOption(
            optionId: 'opt3',
            text: 'Park C',
            voteCount: 3,
            voters: [],
          ),
        ],
        type: PollType.singleChoice,
        status: PollStatus.active,
        createdAt: DateTime.now(),
        totalVotes: 18,
        voters: ['user2', 'user3', 'user4', 'user5'],
      );
    });

    testWidgets('displays poll question', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => Stream.value(testUser),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PollCard(
                poll: testPoll,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Where should we play?'), findsOneWidget);
    });

    testWidgets('displays poll type chip', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => Stream.value(testUser),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PollCard(
                poll: testPoll,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('בחירה אחת'), findsOneWidget);
    });

    testWidgets('displays total votes count', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => Stream.value(testUser),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PollCard(
                poll: testPoll,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('18 הצבעות'), findsOneWidget);
    });

    testWidgets('shows "הצבעת" chip when user voted', (tester) async {
      final votedPoll = testPoll.copyWith(
        voters: ['user1', 'user2'], // user1 voted
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => Stream.value(testUser),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PollCard(
                poll: votedPoll,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('הצבעת'), findsOneWidget);
    });

    testWidgets('shows "סגור" chip when poll is closed', (tester) async {
      final closedPoll = testPoll.copyWith(
        status: PollStatus.closed,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => Stream.value(testUser),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PollCard(
                poll: closedPoll,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('סגור'), findsOneWidget);
    });

    testWidgets('displays winning option when showResultsBeforeVote',
        (tester) async {
      final pollWithResults = testPoll.copyWith(
        showResultsBeforeVote: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => Stream.value(testUser),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PollCard(
                poll: pollWithResults,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Park B has 10 votes (highest)
      expect(find.text('Park B'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => Stream.value(testUser),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PollCard(
                poll: testPoll,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('displays end date when set', (tester) async {
      final endsAt = DateTime(2025, 12, 15, 18, 0);
      final pollWithEndDate = testPoll.copyWith(
        endsAt: endsAt,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => Stream.value(testUser),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PollCard(
                poll: pollWithEndDate,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('עד'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('shows "הסתיים" when poll ended', (tester) async {
      final endsAt = DateTime.now().subtract(const Duration(days: 1));
      final endedPoll = testPoll.copyWith(
        endsAt: endsAt,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => Stream.value(testUser),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PollCard(
                poll: endedPoll,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('הסתיים'), findsOneWidget);
    });
  });
}
