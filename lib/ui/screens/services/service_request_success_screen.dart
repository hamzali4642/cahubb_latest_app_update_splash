import 'package:eClassify/data/model/service/car_finance_api_model.dart';
import 'package:eClassify/data/model/service/service_request_model.dart';
import 'package:eClassify/data/model/service/vehicle_service_request_model.dart';
import 'package:eClassify/ui/theme/service_theme_utils.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class ServiceRequestSuccessScreen extends StatelessWidget {
  const ServiceRequestSuccessScreen({required this.result, super.key});

  final Object result;

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => ServiceRequestSuccessScreen(result: settings.arguments!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectionColor = serviceSelectionColor(context);
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      28.vGap,
                      _SuccessMark(color: selectionColor),
                      28.vGap,
                      CustomText(
                        'Request received!',
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        textAlign: TextAlign.center,
                        color: context.color.textDefaultColor,
                      ),
                      12.vGap,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CustomText(
                          _message(result),
                          fontSize: context.font.large,
                          height: 1.5,
                          textAlign: TextAlign.center,
                          color: context.color.textLightColor,
                        ),
                      ),
                      30.vGap,
                      _RequestSummaryCard(result: result),
                      18.vGap,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectionColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selectionColor.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.support_agent_rounded,
                              color: selectionColor,
                            ),
                            12.hGap,
                            Expanded(
                              child: CustomText(
                                _supportMessage(result),
                                fontSize: context.font.normal,
                                height: 1.45,
                                color: context.color.textDefaultColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              16.vGap,
              UiUtils.buildButton(
                context,
                onPressed: () => Navigator.of(context).pop(),
                buttonTitle: 'Back to home',
                radius: 28,
                height: 58,
                buttonColor: selectionColor,
                textColor: serviceSelectionForeground(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _message(Object result) => switch (result) {
    ServiceRequestResult(:final message) => message,
    VehicleServiceRequestResult(:final message) => message,
    CarFinanceApplicationResult(:final message) => message,
    _ => 'Your request was submitted successfully.',
  };

  static String _supportMessage(Object result) =>
      result is CarFinanceApplicationResult
      ? 'Our finance team or selected banking partner will contact you about the next steps.'
      : 'Our team will contact you to confirm the request details.';
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.08),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          Icons.check_rounded,
          color: serviceSelectionForeground(context),
          size: 52,
        ),
      ),
    );
  }
}

class _RequestSummaryCard extends StatelessWidget {
  const _RequestSummaryCard({required this.result});

  final Object result;

  @override
  Widget build(BuildContext context) {
    final rows = _rows(result);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.color.borderColor),
        boxShadow: [
          BoxShadow(
            color: serviceShadow(context, alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          return Column(
            children: [
              if (index > 0) const _SummaryDivider(),
              _SummaryRow(icon: row.icon, label: row.label, value: row.value),
            ],
          );
        }),
      ),
    );
  }

  static List<_SummaryEntry> _rows(Object result) {
    final rows = <_SummaryEntry>[
      _SummaryEntry(
        icon: Icons.directions_car_filled_rounded,
        label: 'Service',
        value: _serviceName(result),
      ),
    ];
    final id = _requestId(result);
    if (id > 0) {
      rows.add(
        _SummaryEntry(
          icon: Icons.confirmation_number_outlined,
          label: 'Request ID',
          value: '#$id',
        ),
      );
    }
    rows.add(
      _SummaryEntry(
        icon: Icons.pending_actions_rounded,
        label: 'Status',
        value: _titleCase(_status(result)),
      ),
    );

    if (result case ServiceRequestResult request) {
      final appointment = _appointmentLabel(request);
      if (appointment != null) {
        rows.add(
          _SummaryEntry(
            icon: Icons.calendar_month_rounded,
            label: 'Preferred visit',
            value: appointment,
          ),
        );
      }
    } else if (result case CarFinanceApplicationResult finance) {
      rows.addAll([
        _SummaryEntry(
          icon: Icons.account_balance_outlined,
          label: 'Preferred bank',
          value: finance.bank.name,
        ),
        _SummaryEntry(
          icon: Icons.calendar_month_rounded,
          label: 'Tenure',
          value:
              '${finance.tenureYears} year${finance.tenureYears == 1 ? '' : 's'}',
        ),
      ]);
    }
    return rows;
  }

  static String _serviceName(Object result) => switch (result) {
    ServiceRequestResult(:final type) => type.displayName,
    VehicleServiceRequestResult(:final type) => type.displayName,
    CarFinanceApplicationResult() => 'Car finance',
    _ => 'Vehicle service',
  };

  static int _requestId(Object result) => switch (result) {
    ServiceRequestResult(:final id) => id,
    VehicleServiceRequestResult(:final id) => id,
    CarFinanceApplicationResult(:final id) => id,
    _ => 0,
  };

  static String _status(Object result) => switch (result) {
    ServiceRequestResult(:final status) => status,
    VehicleServiceRequestResult(:final status) => status,
    CarFinanceApplicationResult(:final status) => status,
    _ => 'pending',
  };

  static String? _appointmentLabel(ServiceRequestResult request) {
    final date = request.visitDate;
    if (date == null || date.isEmpty) return null;
    final start = _shortTime(request.visitStartTime);
    final end = _shortTime(request.visitEndTime);
    if (start == null || end == null) return date;
    return '$date  •  $start–$end';
  }

  static String? _shortTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0]}:${parts[1]}';
  }

  static String _titleCase(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _SummaryEntry {
  const _SummaryEntry({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: context.color.borderColor),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: context.color.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: serviceSelectionColor(context)),
        ),
        12.hGap,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                label,
                fontSize: context.font.small,
                color: context.color.textLightColor,
              ),
              4.vGap,
              CustomText(
                value,
                fontSize: context.font.large,
                fontWeight: FontWeight.w700,
                color: context.color.textDefaultColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
