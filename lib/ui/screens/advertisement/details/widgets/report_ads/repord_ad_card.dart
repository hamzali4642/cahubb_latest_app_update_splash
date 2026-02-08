import 'dart:developer';

import 'package:eClassify/data/cubits/report/item_report_cubit.dart';
import 'package:eClassify/data/cubits/report/item_report_list_cubit.dart';
import 'package:eClassify/ui/screens/advertisement/details/widgets/report_ads/report_reason_bottom_sheet.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportAdCard extends StatefulWidget {
  const ReportAdCard({
    required this.itemId,
    required this.isReported,
    required this.onReport,
    super.key,
  });
  final int itemId;
  final bool isReported;
  final VoidCallback onReport;

  @override
  State<ReportAdCard> createState() => _ReportAdCardState();
}

class _ReportAdCardState extends State<ReportAdCard> {
  late bool isShowing = !widget.isReported;

  @override
  void initState() {
    super.initState();
    log('${widget.isReported}');
  }

  @override
  Widget build(BuildContext context) {
    if (!isShowing) {
      return const SizedBox.shrink();
    }
    return BlocListener<SubmitItemReportCubit, SubmitItemReportState>(
      listener: (context, state) {
        if (state is SubmitItemReportSuccess) {
          HelperUtils.showSnackBarMessage(context, state.message);
          context.read<ItemReportListCubit>().addItemReport(
            itemId: widget.itemId,
          );
          widget.onReport();
          setState(() {
            isShowing = false;
          });
        }
        if (state is SubmitItemReportFailure) {
          HelperUtils.showSnackBarMessage(context, state.message);
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 5,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "didYouFindAnyProblemWithThisItem".translate(context),
                fontSize: context.font.large,
              ),
              Row(
                children: [
                  Expanded(child: CustomText('ID #${widget.itemId}')),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: TextStyle(fontSize: context.font.small),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      UiUtils.checkUser(
                        onNotGuest: () {
                          ReportReasonBottomSheet.show(
                            context,
                            itemId: widget.itemId,
                          );
                        },
                        context: context,
                      );
                    },
                    child: Text('reportThisAd'.translate(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
