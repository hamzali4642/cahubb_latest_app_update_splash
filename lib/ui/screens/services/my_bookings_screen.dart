import 'package:eClassify/data/cubits/service/service_bookings_cubit.dart';
import 'package:eClassify/data/model/service/service_booking_model.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/theme/service_theme_utils.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => BlocProvider(
        create: (_) => ServiceBookingsCubit()..fetch(),
        child: const MyBookingsScreen(),
      ),
    );
  }

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreIfNeeded);
  }

  void _loadMoreIfNeeded() {
    if (_scrollController.position.extentAfter < 300) {
      context.read<ServiceBookingsCubit>().fetchMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: 'My Bookings',
      ),
      body: SafeArea(
        child: BlocBuilder<ServiceBookingsCubit, ServiceBookingsState>(
          builder: (context, state) {
            if (state is ServiceBookingsInitial ||
                state is ServiceBookingsLoading) {
              return Center(child: UiUtils.progress());
            }
            if (state is ServiceBookingsFailed) {
              return _BookingsError(
                message: state.message,
                onRetry: context.read<ServiceBookingsCubit>().fetch,
              );
            }
            if (state is ServiceBookingsLoaded) {
              if (state.bookings.isEmpty) {
                return RefreshIndicator(
                  color: context.color.territoryColor,
                  onRefresh: context.read<ServiceBookingsCubit>().fetch,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      NoDataFound(
                        mainMessage: 'No bookings yet',
                        subMessage:
                            'Your service requests will appear here after you submit them.',
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: context.color.territoryColor,
                onRefresh: context.read<ServiceBookingsCubit>().fetch,
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  itemCount: state.bookings.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == state.bookings.length) {
                      return _PaginationFooter(state: state);
                    }
                    return ServiceBookingCard(booking: state.bookings[index]);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class ServiceBookingCard extends StatelessWidget {
  const ServiceBookingCard({required this.booking, super.key});

  final ServiceBooking booking;

  @override
  Widget build(BuildContext context) {
    final summaryRows = _summaryRows(booking);
    return Container(
      key: ValueKey(booking.bookingKey),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: serviceSurface(context, lightAlpha: 0.035, darkAlpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: serviceFieldBorder(context)),
        boxShadow: [
          BoxShadow(
            color: serviceShadow(context),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: serviceAccentSurface(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _serviceIcon(booking.type),
                  color: context.color.territoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      booking.title,
                      fontSize: context.font.large,
                      fontWeight: FontWeight.w700,
                      color: context.color.textDefaultColor,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      'Request #${booking.id}${_createdLabel(booking.createdAt)}',
                      fontSize: context.font.small,
                      color: context.color.textLightColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _BookingStatusChip(status: booking.status),
            ],
          ),
          if (summaryRows.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: context.color.borderColor),
            const SizedBox(height: 12),
            ...summaryRows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _BookingInfoRow(row: row),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingInfo {
  const _BookingInfo(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _BookingInfoRow extends StatelessWidget {
  const _BookingInfoRow({required this.row});

  final _BookingInfo row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(row.icon, size: 18, color: context.color.textLightColor),
        const SizedBox(width: 10),
        SizedBox(
          width: 82,
          child: CustomText(
            row.label,
            fontSize: context.font.small,
            color: context.color.textLightColor,
          ),
        ),
        Expanded(
          child: CustomText(
            row.value,
            fontSize: context.font.small,
            fontWeight: FontWeight.w600,
            color: context.color.textDefaultColor,
          ),
        ),
      ],
    );
  }
}

class _BookingStatusChip extends StatelessWidget {
  const _BookingStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkTheme(context) ? 0.24 : 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: CustomText(
        _readable(status),
        fontSize: context.font.smaller,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.state});

  final ServiceBookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: UiUtils.progress()),
      );
    }
    if (state.loadMoreFailed) {
      return Center(
        child: TextButton(
          onPressed: context.read<ServiceBookingsCubit>().fetchMore,
          child: const Text('Retry loading more'),
        ),
      );
    }
    return const SizedBox(height: 4);
  }
}

class _BookingsError extends StatelessWidget {
  const _BookingsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: context.color.textLightColor,
            ),
            const SizedBox(height: 14),
            CustomText(
              message == 'no-internet'
                  ? 'Please check your internet connection.'
                  : 'Unable to load your bookings.',
              textAlign: TextAlign.center,
              fontWeight: FontWeight.w600,
              color: context.color.textDefaultColor,
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

List<_BookingInfo> _summaryRows(ServiceBooking booking) {
  final rows = <_BookingInfo>[];
  final schedule = booking.schedule;
  if (schedule != null && schedule.date.isNotEmpty) {
    rows.add(
      _BookingInfo(Icons.event_outlined, 'Visit', _scheduleLabel(schedule)),
    );
  }

  final details = booking.details;
  final modelYear = _detail(details, 'model_year');
  final variant = _detail(details, 'car_variant');
  if (modelYear != null || variant != null) {
    rows.add(
      _BookingInfo(
        Icons.directions_car_outlined,
        'Vehicle',
        [modelYear, variant].whereType<String>().join(' · '),
      ),
    );
  }

  final location =
      _detail(details, 'registration_place') ??
      _detail(details, 'visit_area') ??
      _detail(details, 'city');
  if (location != null) {
    rows.add(_BookingInfo(Icons.location_on_outlined, 'Location', location));
  }

  final chassis = _detail(details, 'chassis_number');
  if (chassis != null) {
    rows.add(_BookingInfo(Icons.tag_outlined, 'Chassis', chassis));
  }

  final financeType = _detail(details, 'finance_type');
  if (financeType != null) {
    rows.add(
      _BookingInfo(
        Icons.account_balance_outlined,
        'Finance',
        _readable(financeType),
      ),
    );
  }
  return rows.take(3).toList();
}

String? _detail(Map<String, dynamic> details, String key) {
  final value = details[key]?.toString().trim();
  return value == null || value.isEmpty || value == 'null' ? null : value;
}

String _scheduleLabel(ServiceBookingSchedule schedule) {
  final parsedDate = DateTime.tryParse(schedule.date);
  final date = parsedDate == null
      ? schedule.date
      : DateFormat('d MMM yyyy').format(parsedDate);
  final start = _formatTime(schedule.startTime);
  final end = _formatTime(schedule.endTime);
  final time = [start, end].where((value) => value.isNotEmpty).join(' – ');
  return time.isEmpty ? date : '$date · $time';
}

String _formatTime(String value) {
  for (final pattern in ['HH:mm:ss', 'HH:mm']) {
    try {
      return DateFormat('h:mm a').format(DateFormat(pattern).parse(value));
    } catch (_) {}
  }
  return value;
}

String _createdLabel(DateTime? date) {
  if (date == null) return '';
  return ' · ${DateFormat('d MMM yyyy').format(date.toLocal())}';
}

String _readable(String value) {
  if (value.isEmpty) return value;
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

IconData _serviceIcon(String type) {
  return switch (type) {
    'car_inspection' => Icons.car_repair_outlined,
    'sell_for_me' => Icons.sell_outlined,
    'car_registration' => Icons.app_registration_outlined,
    'car_ownership_transfer' => Icons.swap_horiz_rounded,
    'auction_sheet_verification' => Icons.fact_check_outlined,
    'car_finance' => Icons.account_balance_outlined,
    _ => Icons.receipt_long_outlined,
  };
}

Color _statusColor(BuildContext context, String status) {
  return switch (status) {
    'completed' => const Color(0xFF2EAD72),
    'in_progress' =>
      isDarkTheme(context) ? const Color(0xFF82B7FF) : const Color(0xFF2368B5),
    'canceled' => const Color(0xFFE05A5A),
    _ =>
      isDarkTheme(context) ? const Color(0xFFFFC95C) : const Color(0xFFB47700),
  };
}
