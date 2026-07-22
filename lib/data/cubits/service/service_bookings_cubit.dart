import 'package:eClassify/data/model/service/service_booking_model.dart';
import 'package:eClassify/data/repositories/service/service_bookings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class ServiceBookingsState {}

class ServiceBookingsInitial extends ServiceBookingsState {}

class ServiceBookingsLoading extends ServiceBookingsState {}

class ServiceBookingsLoaded extends ServiceBookingsState {
  ServiceBookingsLoaded({
    required this.bookings,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<ServiceBooking> bookings;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  ServiceBookingsLoaded copyWith({
    List<ServiceBooking>? bookings,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return ServiceBookingsLoaded(
      bookings: bookings ?? this.bookings,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

class ServiceBookingsFailed extends ServiceBookingsState {
  ServiceBookingsFailed(this.message);

  final String message;
}

class ServiceBookingsCubit extends Cubit<ServiceBookingsState> {
  ServiceBookingsCubit({ServiceBookingsRepository? repository})
    : _repository = repository ?? ServiceBookingsRepository(),
      super(ServiceBookingsInitial());

  final ServiceBookingsRepository _repository;

  Future<void> fetch() async {
    emit(ServiceBookingsLoading());
    try {
      final page = await _repository.fetchBookings(page: 1);
      emit(
        ServiceBookingsLoaded(
          bookings: page.bookings,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
        ),
      );
    } catch (error) {
      emit(ServiceBookingsFailed(error.toString()));
    }
  }

  Future<void> fetchMore() async {
    final current = state;
    if (current is! ServiceBookingsLoaded ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true, loadMoreFailed: false));
    try {
      final page = await _repository.fetchBookings(
        page: current.currentPage + 1,
      );
      emit(
        current.copyWith(
          bookings: [...current.bookings, ...page.bookings],
          currentPage: page.currentPage,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false, loadMoreFailed: true));
    }
  }
}
