import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/model/service/service_request_model.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class ServiceRequestSuccessScreen extends StatelessWidget {
  const ServiceRequestSuccessScreen({required this.request, super.key});

  final ServiceRequestResult request;

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => ServiceRequestSuccessScreen(
        request: settings.arguments! as ServiceRequestResult,
      ),
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.main,
      (_) => false,
      arguments: const {'from': 'service-request'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goToHome(context);
      },
      child: Scaffold(
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
                        _SuccessMark(color: context.color.territoryColor),
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
                            request.message,
                            fontSize: context.font.large,
                            height: 1.5,
                            textAlign: TextAlign.center,
                            color: context.color.textLightColor,
                          ),
                        ),
                        30.vGap,
                        _RequestSummaryCard(request: request),
                        18.vGap,
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.color.territoryColor.withValues(
                              alpha: 0.07,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: context.color.territoryColor.withValues(
                                alpha: 0.14,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.support_agent_rounded,
                                color: context.color.territoryColor,
                              ),
                              12.hGap,
                              Expanded(
                                child: CustomText(
                                  'Our team will contact you to confirm the visit details.',
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
                  onPressed: () => _goToHome(context),
                  buttonTitle: 'Back to home',
                  radius: 28,
                  height: 58,
                  buttonColor: context.color.territoryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
      ),
    );
  }
}

class _RequestSummaryCard extends StatelessWidget {
  const _RequestSummaryCard({required this.request});

  final ServiceRequestResult request;

  @override
  Widget build(BuildContext context) {
    final appointment = _appointmentLabel(request);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.color.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.directions_car_filled_rounded,
            label: 'Service',
            value: request.type.displayName,
          ),
          if (request.id > 0) ...[
            const _SummaryDivider(),
            _SummaryRow(
              icon: Icons.confirmation_number_outlined,
              label: 'Request ID',
              value: '#${request.id}',
            ),
          ],
          const _SummaryDivider(),
          _SummaryRow(
            icon: Icons.pending_actions_rounded,
            label: 'Status',
            value: _titleCase(request.status),
          ),
          if (appointment != null) ...[
            const _SummaryDivider(),
            _SummaryRow(
              icon: Icons.calendar_month_rounded,
              label: 'Preferred visit',
              value: appointment,
            ),
          ],
        ],
      ),
    );
  }

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
          child: Icon(icon, size: 20, color: context.color.territoryColor),
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
