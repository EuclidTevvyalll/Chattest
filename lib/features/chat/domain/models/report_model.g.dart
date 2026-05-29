// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReportModel _$ReportModelFromJson(Map<String, dynamic> json) => _ReportModel(
  id: json['id'] as String?,
  reporterId: json['reporter_id'] as String,
  targetId: json['target_id'] as String,
  targetType: json['target_type'] as String,
  reason: json['reason'] as String,
  details: json['details'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  status: json['status'] as String?,
  moderationDetails: json['moderation_details'] as String?,
);

Map<String, dynamic> _$ReportModelToJson(_ReportModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reporter_id': instance.reporterId,
      'target_id': instance.targetId,
      'target_type': instance.targetType,
      'reason': instance.reason,
      'details': instance.details,
      'created_at': instance.createdAt?.toIso8601String(),
      'status': instance.status,
      'moderation_details': instance.moderationDetails,
    };
