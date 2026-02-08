import 'package:eClassify/data/model/report/report_reason.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/json_helper.dart';
import 'package:eClassify/utils/log.dart';

class ReportItemRepository {
  factory ReportItemRepository() => _instance;

  ReportItemRepository._internal();

  static final ReportItemRepository _instance =
      ReportItemRepository._internal();

  Future<List<ReportReason>> fetchReportReasons() async {
    try {
      final response = await Api.get(url: Api.getReportReasonsApi);

      final reasons = JsonHelper.parseList(
        response['data']['data'] as List?,
        ReportReason.fromJson,
      );

      return reasons;
    } on Exception catch (e, st) {
      Log.error(e.toString(), e, st);
      throw ApiException(e.toString());
    }
  }

  Future<Map> reportItem({
    required int itemId,
    int? reasonId,
    String? message,
  }) async {
    try {
      final response = await Api.post(
        url: Api.addReportsApi,
        parameter: {
          Api.itemId: itemId,
          Api.reportReasonId: ?reasonId,
          Api.otherMessage: ?message,
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
