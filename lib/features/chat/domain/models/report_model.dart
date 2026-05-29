import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_model.freezed.dart';
part 'report_model.g.dart';

@freezed
abstract class ReportModel with _$ReportModel {
  const factory ReportModel({
    String? id,
    @JsonKey(name: 'reporter_id') required String reporterId,
    @JsonKey(name: 'target_id') required String targetId,
    @JsonKey(name: 'target_type') required String targetType,
    required String reason,
    String? details,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    String? status,
    @JsonKey(name: 'moderation_details') String? moderationDetails,
  }) = _ReportModel;

  factory ReportModel.fromJson(Map<String, dynamic> json) =>
      _$ReportModelFromJson(json);
}
