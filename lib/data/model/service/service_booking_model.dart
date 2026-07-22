class ServiceBookingSchedule {
  const ServiceBookingSchedule({
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  final String date;
  final String startTime;
  final String endTime;

  factory ServiceBookingSchedule.fromJson(Map<String, dynamic> json) {
    return ServiceBookingSchedule(
      date: json['date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
    );
  }
}

class ServiceBooking {
  const ServiceBooking({
    required this.bookingKey,
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.details,
    this.schedule,
  });

  final String bookingKey;
  final int id;
  final String type;
  final String title;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ServiceBookingSchedule? schedule;
  final Map<String, dynamic> details;

  factory ServiceBooking.fromJson(Map<String, dynamic> json) {
    final rawSchedule = json['schedule'];
    final rawDetails = json['details'];
    return ServiceBooking(
      bookingKey: json['booking_key']?.toString() ?? '',
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Service Booking',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      schedule: rawSchedule is Map
          ? ServiceBookingSchedule.fromJson(
              Map<String, dynamic>.from(rawSchedule),
            )
          : null,
      details: rawDetails is Map
          ? Map<String, dynamic>.from(rawDetails)
          : const <String, dynamic>{},
    );
  }
}

class ServiceBookingsPage {
  const ServiceBookingsPage({
    required this.bookings,
    required this.currentPage,
    required this.hasMore,
  });

  final List<ServiceBooking> bookings;
  final int currentPage;
  final bool hasMore;

  factory ServiceBookingsPage.fromJson(Map<String, dynamic> json) {
    final rawBookings = json['bookings'];
    final rawPagination = json['pagination'];
    final pagination = rawPagination is Map
        ? Map<String, dynamic>.from(rawPagination)
        : const <String, dynamic>{};

    return ServiceBookingsPage(
      bookings: rawBookings is List
          ? rawBookings
                .whereType<Map>()
                .map(
                  (booking) => ServiceBooking.fromJson(
                    Map<String, dynamic>.from(booking),
                  ),
                )
                .toList()
          : const <ServiceBooking>[],
      currentPage:
          int.tryParse(pagination['current_page']?.toString() ?? '') ?? 1,
      hasMore: pagination['has_more'] == true,
    );
  }
}
