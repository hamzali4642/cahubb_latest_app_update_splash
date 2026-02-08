import 'dart:io';

import 'package:eClassify/data/cubits/report/item_report_cubit.dart';
import 'package:eClassify/data/cubits/report/report_reason_cubit.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/lib/build_context.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/extensions/lib/translate.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

abstract class ReportReasonBottomSheet {
  static void show(BuildContext context, {required int itemId}) {
    UiUtils.showBottomSheet(
      context,
      child: BlocProvider.value(
        value: context.read<SubmitItemReportCubit>(),
        child: SafeArea(
          bottom: Platform.isAndroid,
          child: _ReasonsList(itemId: itemId),
        ),
      ),
    );
  }
}

class _ReasonsList extends StatefulWidget {
  const _ReasonsList({required this.itemId});
  final int itemId;

  @override
  State<_ReasonsList> createState() => _ReasonsListState();
}

class _ReasonsListState extends State<_ReasonsList>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final ValueNotifier<int?> _selected = ValueNotifier(-1);
  late final _sizeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _selected.dispose();
    super.dispose();
  }

  Widget _listTile(String title, int? reasonId) {
    return ValueListenableBuilder(
      valueListenable: _selected,
      builder: (context, value, child) {
        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          onTap: () async {
            setState(() {
              _selected.value = reasonId;
            });
            if (reasonId == null) {
              _sizeController.forward();
              await Future.delayed(const Duration(milliseconds: 300));
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            } else {
              if (_sizeController.isCompleted) {
                _sizeController.reverse();
              }
            }
          },
          selected: value == reasonId,
          selectedColor: context.color.secondaryColor,
          selectedTileColor: context.color.territoryColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: context.color.textLightColor),
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(title),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportReasonCubit, ReportReasonState>(
      builder: (context, state) {
        if (state is ReportReasonInitial) {
          context.read<ReportReasonCubit>().getReasons();
        }
        if (state is ReportReasonFailure) {
          HelperUtils.showSnackBarMessage(context, state.errorMessage);
          Navigator.of(context).pop();
        }
        if (state is ReportReasonSuccess) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                CustomText(
                  'reportItem'.translate(context),
                  fontSize: context.font.larger,
                  fontWeight: FontWeight.bold,
                ),
                Expanded(
                  child: Material(
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: state.reasons.length + 1,
                      itemBuilder: (context, index) {
                        if (index == state.reasons.length) {
                          return Column(
                            children: [
                              _listTile('other'.translate(context), null),
                              SizeTransition(
                                sizeFactor: _sizeController,
                                axis: Axis.vertical,
                                axisAlignment: -1,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: TextField(
                                    controller: _controller,
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: context.color.territoryColor,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      hintText: 'writeReasonHere'.translate(
                                        context,
                                      ),
                                      hintStyle: TextStyle(
                                        fontSize: context.font.normal,
                                      ),
                                      constraints: BoxConstraints(
                                        maxHeight: 100,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          final reason = state.reasons[index];
                          return _listTile(reason.reason.localized, reason.id);
                        }
                      },
                      separatorBuilder: (_, _) => 5.vGap,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.color.territoryColor,
                    foregroundColor: context.color.secondaryColor,
                    minimumSize: Size.fromHeight(40),
                    fixedSize: Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    context.read<SubmitItemReportCubit>().report(
                      itemId: widget.itemId,
                      reasonId: _selected.value,
                      message: _controller.text.trim(),
                    );
                  },
                  child:
                      BlocConsumer<
                        SubmitItemReportCubit,
                        SubmitItemReportState
                      >(
                        listener: (context, state) {
                          if (state is SubmitItemReportSuccess) {
                            Navigator.of(context).pop();
                          }
                          if (state is SubmitItemReportFailure) {
                            Navigator.of(context).pop();
                          }
                        },
                        builder: (context, state) {
                          return state is SubmitItemReportLoading
                              ? UiUtils.progress(
                                  color: context.color.secondaryColor,
                                )
                              : Text('submitBtnLbl'.translate(context));
                        },
                      ),
                ),
              ],
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.color.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
                  highlightColor: Theme.of(
                    context,
                  ).colorScheme.shimmerHighlightColor,
                  child: SizedBox(
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: context.color.textLightColor),
                      ),
                    ),
                  ),
                );
              },
              itemCount: 5,
            ),
          ),
        );
      },
    );
  }
}
