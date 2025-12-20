// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_audit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameAuditImpl _$$GameAuditImplFromJson(Map<String, dynamic> json) =>
    _$GameAuditImpl(
      auditLog: (json['auditLog'] as List<dynamic>?)
              ?.map((e) => GameAuditEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$GameAuditImplToJson(_$GameAuditImpl instance) =>
    <String, dynamic>{
      'auditLog': instance.auditLog,
    };
