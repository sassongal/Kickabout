import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/models/converters/timestamp_converter.dart';

part 'poll.freezed.dart';
part 'poll.g.dart';

/// Poll Type - סוג הסקר
enum PollType {
  singleChoice,    // בחירה אחת
  multipleChoice,  // בחירה מרובה
  rating,          // דירוג (1-5 כוכבים)
}

/// Poll Status - סטטוס הסקר
enum PollStatus {
  active,      // פעיל - ניתן להצביע
  closed,      // סגור - לא ניתן להצביע
  archived,    // בארכיון
}

/// Poll Model - מודל סקר
@freezed
class Poll with _$Poll {
  const factory Poll({
    required String pollId,
    required String hubId,
    required String createdBy,      // User ID של היוצר
    required String question,       // השאלה
    required List<PollOption> options,  // אפשרויות ההצבעה
    required PollType type,
    required PollStatus status,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() DateTime? endsAt,  // תאריך סיום (null = ללא תאריך סיום)
    @TimestampConverter() DateTime? closedAt,
    @Default(0) int totalVotes,     // סה"כ הצבעות
    @Default([]) List<String> voters,  // רשימת IDs של מי שהצביע (למניעת הצבעות כפולות)
    @Default(false) bool allowMultipleVotes,  // האם מותר להצביע יותר מפעם אחת
    @Default(false) bool showResultsBeforeVote,  // האם להציג תוצאות לפני הצבעה
    @Default(false) bool isAnonymous,  // האם ההצבעה אנונימית
    String? description,  // תיאור נוסף (אופציונלי)
  }) = _Poll;

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);
}

/// Poll Option - אפשרות בסקר
@freezed
class PollOption with _$PollOption {
  const factory PollOption({
    required String optionId,
    required String text,
    @Default(0) int voteCount,
    @Default([]) List<String> voters,  // מי הצביע לאפשרות הזו (אם לא אנונימי)
    String? imageUrl,  // תמונה לאפשרות (אופציונלי)
  }) = _PollOption;

  factory PollOption.fromJson(Map<String, dynamic> json) =>
      _$PollOptionFromJson(json);
}

/// Poll Vote - הצבעה בסקר
@freezed
class PollVote with _$PollVote {
  const factory PollVote({
    required String voteId,
    required String pollId,
    required String userId,
    required List<String> selectedOptionIds,  // יכול להיות יותר מאחד ב-multipleChoice
    @TimestampConverter() required DateTime votedAt,
    int? rating,  // דירוג (1-5) עבור poll מסוג rating
  }) = _PollVote;

  factory PollVote.fromJson(Map<String, dynamic> json) =>
      _$PollVoteFromJson(json);
}

/// Poll Summary - סיכום תוצאות סקר
class PollSummary {
  final Poll poll;
  final Map<String, int> optionVotes;  // optionId -> vote count
  final Map<String, double> optionPercentages;  // optionId -> percentage
  final List<PollOption> sortedOptions;  // sorted by votes DESC
  final PollOption? winningOption;
  final bool hasVoted;
  final List<String>? userVotes;  // אילו אפשרויות המשתמש בחר

  PollSummary({
    required this.poll,
    required this.optionVotes,
    required this.optionPercentages,
    required this.sortedOptions,
    this.winningOption,
    required this.hasVoted,
    this.userVotes,
  });

  factory PollSummary.fromPoll(Poll poll, {String? userId}) {
    // Calculate votes and percentages
    final optionVotes = <String, int>{};
    final optionPercentages = <String, double>{};
    
    for (final option in poll.options) {
      optionVotes[option.optionId] = option.voteCount;
      optionPercentages[option.optionId] = 
          poll.totalVotes > 0 ? (option.voteCount / poll.totalVotes) * 100 : 0.0;
    }

    // Sort options by votes
    final sortedOptions = List<PollOption>.from(poll.options)
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    // Find winning option
    final winningOption = sortedOptions.isNotEmpty ? sortedOptions.first : null;

    // Check if user voted
    final hasVoted = userId != null && poll.voters.contains(userId);
    
    // Get user's votes
    List<String>? userVotes;
    if (hasVoted && !poll.isAnonymous) {
      userVotes = poll.options
          .where((opt) => opt.voters.contains(userId))
          .map((opt) => opt.optionId)
          .toList();
    }

    return PollSummary(
      poll: poll,
      optionVotes: optionVotes,
      optionPercentages: optionPercentages,
      sortedOptions: sortedOptions,
      winningOption: winningOption,
      hasVoted: hasVoted,
      userVotes: userVotes,
    );
  }
}

