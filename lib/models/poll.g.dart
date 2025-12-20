// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poll.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PollImpl _$$PollImplFromJson(Map<String, dynamic> json) => _$PollImpl(
      pollId: json['pollId'] as String,
      hubId: json['hubId'] as String,
      createdBy: json['createdBy'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      type: $enumDecode(_$PollTypeEnumMap, json['type']),
      status: $enumDecode(_$PollStatusEnumMap, json['status']),
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      endsAt: _$JsonConverterFromJson<Object, DateTime>(
          json['endsAt'], const TimestampConverter().fromJson),
      closedAt: _$JsonConverterFromJson<Object, DateTime>(
          json['closedAt'], const TimestampConverter().fromJson),
      totalVotes: (json['totalVotes'] as num?)?.toInt() ?? 0,
      voters: (json['voters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      allowMultipleVotes: json['allowMultipleVotes'] as bool? ?? false,
      showResultsBeforeVote: json['showResultsBeforeVote'] as bool? ?? false,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$PollImplToJson(_$PollImpl instance) =>
    <String, dynamic>{
      'pollId': instance.pollId,
      'hubId': instance.hubId,
      'createdBy': instance.createdBy,
      'question': instance.question,
      'options': instance.options,
      'type': _$PollTypeEnumMap[instance.type]!,
      'status': _$PollStatusEnumMap[instance.status]!,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'endsAt': _$JsonConverterToJson<Object, DateTime>(
          instance.endsAt, const TimestampConverter().toJson),
      'closedAt': _$JsonConverterToJson<Object, DateTime>(
          instance.closedAt, const TimestampConverter().toJson),
      'totalVotes': instance.totalVotes,
      'voters': instance.voters,
      'allowMultipleVotes': instance.allowMultipleVotes,
      'showResultsBeforeVote': instance.showResultsBeforeVote,
      'isAnonymous': instance.isAnonymous,
      'description': instance.description,
    };

const _$PollTypeEnumMap = {
  PollType.singleChoice: 'singleChoice',
  PollType.multipleChoice: 'multipleChoice',
  PollType.rating: 'rating',
};

const _$PollStatusEnumMap = {
  PollStatus.active: 'active',
  PollStatus.closed: 'closed',
  PollStatus.archived: 'archived',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);

_$PollOptionImpl _$$PollOptionImplFromJson(Map<String, dynamic> json) =>
    _$PollOptionImpl(
      optionId: json['optionId'] as String,
      text: json['text'] as String,
      voteCount: (json['voteCount'] as num?)?.toInt() ?? 0,
      voters: (json['voters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$$PollOptionImplToJson(_$PollOptionImpl instance) =>
    <String, dynamic>{
      'optionId': instance.optionId,
      'text': instance.text,
      'voteCount': instance.voteCount,
      'voters': instance.voters,
      'imageUrl': instance.imageUrl,
    };

_$PollVoteImpl _$$PollVoteImplFromJson(Map<String, dynamic> json) =>
    _$PollVoteImpl(
      voteId: json['voteId'] as String,
      pollId: json['pollId'] as String,
      userId: json['userId'] as String,
      selectedOptionIds: (json['selectedOptionIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      votedAt: const TimestampConverter().fromJson(json['votedAt'] as Object),
      rating: (json['rating'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$PollVoteImplToJson(_$PollVoteImpl instance) =>
    <String, dynamic>{
      'voteId': instance.voteId,
      'pollId': instance.pollId,
      'userId': instance.userId,
      'selectedOptionIds': instance.selectedOptionIds,
      'votedAt': const TimestampConverter().toJson(instance.votedAt),
      'rating': instance.rating,
    };
