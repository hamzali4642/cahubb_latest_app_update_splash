import 'package:eClassify/data/model/localized_string.dart';
import 'package:eClassify/utils/json_helper.dart';

class ReportReason {
  ReportReason({required this.id, required this.reason});

  ReportReason.fromJson(Json json)
    : id = json['id'],
      reason = LocalizedString(
        canonical: json['reason'] as String,
        translated: json['translated_reason'] as String?,
      );

  final int id;
  final LocalizedString reason;
}
