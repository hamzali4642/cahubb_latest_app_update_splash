import 'package:eClassify/data/model/car_model_model.dart';
import 'package:eClassify/data/model/location/location_node.dart' show City;
import 'package:eClassify/data/model/service/service_package_model.dart';
import 'package:eClassify/data/model/service/service_request_model.dart';
import 'package:eClassify/data/repositories/service/service_lead_repository.dart';
import 'package:eClassify/data/repositories/service/service_request_repository.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ServiceBookingFlowType { inspection, sellItForMe }

class ServiceBookingTimeSlot {
  final int startHour;
  final String label;

  const ServiceBookingTimeSlot({required this.startHour, required this.label});
}

class ServiceBookingFormState {
  final ServicePackageModel package;
  final ServiceBookingFlowType flowType;
  final bool showSelectedPackage;
  final int currentStepIndex;
  final bool isUsedCar;
  final bool isLoadingCars;
  final bool isLoadingCities;
  final bool isSubmitting;
  final String? citiesErrorMessage;
  final List<CarModelModel> carModels;
  final List<City> cities;
  final String fullName;
  final String phoneNumber;
  final String carVariant;
  final String visitArea;
  final int? selectedModelYear;
  final String? selectedRegistrationArea;
  final CarModelModel? selectedCar;
  final City? selectedLivingCity;
  final DateTime? selectedVisitDate;
  final ServiceBookingTimeSlot? selectedTimeSlot;
  final List<DateTime> availableDates;
  final List<ServiceBookingTimeSlot> timeSlots;
  final String? feedbackMessage;
  final int feedbackToken;
  final ServiceRequestResult? submissionResult;
  final int submissionToken;

  const ServiceBookingFormState({
    required this.package,
    required this.flowType,
    required this.showSelectedPackage,
    required this.currentStepIndex,
    required this.isUsedCar,
    required this.isLoadingCars,
    required this.isLoadingCities,
    required this.isSubmitting,
    required this.carModels,
    required this.cities,
    required this.fullName,
    required this.phoneNumber,
    required this.carVariant,
    required this.visitArea,
    required this.availableDates,
    required this.timeSlots,
    this.citiesErrorMessage,
    this.selectedModelYear,
    this.selectedRegistrationArea,
    this.selectedCar,
    this.selectedLivingCity,
    this.selectedVisitDate,
    this.selectedTimeSlot,
    this.feedbackMessage,
    this.feedbackToken = 0,
    this.submissionResult,
    this.submissionToken = 0,
  });

  factory ServiceBookingFormState.initial({
    required ServicePackageModel package,
    required ServiceBookingFlowType flowType,
    required bool showSelectedPackage,
  }) {
    final now = DateTime.now();
    final cachedCities = ServiceLeadRepository.cachedCities;
    return ServiceBookingFormState(
      package: package,
      flowType: flowType,
      showSelectedPackage: showSelectedPackage,
      currentStepIndex: 0,
      isUsedCar: true,
      isLoadingCars: true,
      isLoadingCities: false,
      isSubmitting: false,
      carModels: const [],
      cities: cachedCities,
      fullName: '',
      phoneNumber: '',
      carVariant: '',
      visitArea: '',
      availableDates: List.generate(
        7,
        (index) => DateTime(now.year, now.month, now.day + index),
      ),
      timeSlots: List.generate(7, (index) {
        final startHour = 10 + index;
        return ServiceBookingTimeSlot(
          startHour: startHour,
          label:
              '${ServiceBookingFormCubit.formatHour(startHour)} - ${ServiceBookingFormCubit.formatHour(startHour + 1)}',
        );
      }),
    );
  }

  ServiceBookingFormState copyWith({
    int? currentStepIndex,
    bool? isUsedCar,
    bool? isLoadingCars,
    bool? isLoadingCities,
    bool? isSubmitting,
    String? citiesErrorMessage,
    List<CarModelModel>? carModels,
    List<City>? cities,
    String? fullName,
    String? phoneNumber,
    String? carVariant,
    String? visitArea,
    int? selectedModelYear,
    String? selectedRegistrationArea,
    CarModelModel? selectedCar,
    City? selectedLivingCity,
    DateTime? selectedVisitDate,
    ServiceBookingTimeSlot? selectedTimeSlot,
    String? feedbackMessage,
    bool clearCitiesErrorMessage = false,
    bool clearSelectedModelYear = false,
    bool clearSelectedRegistrationArea = false,
    bool clearSelectedCar = false,
    bool clearSelectedLivingCity = false,
    bool clearSelectedVisitDate = false,
    bool clearSelectedTimeSlot = false,
    bool clearFeedbackMessage = false,
    int? feedbackToken,
    ServiceRequestResult? submissionResult,
    int? submissionToken,
  }) {
    return ServiceBookingFormState(
      package: package,
      flowType: flowType,
      showSelectedPackage: showSelectedPackage,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isUsedCar: isUsedCar ?? this.isUsedCar,
      isLoadingCars: isLoadingCars ?? this.isLoadingCars,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      citiesErrorMessage: clearCitiesErrorMessage
          ? null
          : (citiesErrorMessage ?? this.citiesErrorMessage),
      carModels: carModels ?? this.carModels,
      cities: cities ?? this.cities,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      carVariant: carVariant ?? this.carVariant,
      visitArea: visitArea ?? this.visitArea,
      selectedModelYear: clearSelectedModelYear
          ? null
          : (selectedModelYear ?? this.selectedModelYear),
      selectedRegistrationArea: clearSelectedRegistrationArea
          ? null
          : (selectedRegistrationArea ?? this.selectedRegistrationArea),
      selectedCar: clearSelectedCar ? null : (selectedCar ?? this.selectedCar),
      selectedLivingCity: clearSelectedLivingCity
          ? null
          : (selectedLivingCity ?? this.selectedLivingCity),
      selectedVisitDate: clearSelectedVisitDate
          ? null
          : (selectedVisitDate ?? this.selectedVisitDate),
      selectedTimeSlot: clearSelectedTimeSlot
          ? null
          : (selectedTimeSlot ?? this.selectedTimeSlot),
      availableDates: availableDates,
      timeSlots: timeSlots,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      feedbackToken: feedbackToken ?? this.feedbackToken,
      submissionResult: submissionResult ?? this.submissionResult,
      submissionToken: submissionToken ?? this.submissionToken,
    );
  }
}

class ServiceBookingFormCubit extends Cubit<ServiceBookingFormState> {
  ServiceBookingFormCubit({
    required ServicePackageModel package,
    required ServiceBookingFlowType flowType,
    required bool showSelectedPackage,
    ServiceLeadRepository? repository,
    ServiceRequestRepository? requestRepository,
  }) : _repository = repository ?? ServiceLeadRepository(),
       _requestRepository =
           requestRepository ?? const ServiceRequestRepository(),
       super(
         ServiceBookingFormState.initial(
           package: package,
           flowType: flowType,
           showSelectedPackage: showSelectedPackage,
         ),
       );

  final ServiceLeadRepository _repository;
  final ServiceRequestRepository _requestRepository;

  static const List<String> registrationAreas = [
    'Punjab',
    'KPK',
    'Sindh',
    'Balochistan',
    'AJK',
  ];

  static final List<int> modelYears = [
    for (int year = DateTime.now().year; year >= 1990; year--) year,
  ];

  static String formatHour(int hour) {
    final normalized = hour > 12 ? hour - 12 : hour;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    return '$normalized $suffix';
  }

  Future<void> initialize() async {
    if (HiveUtils.isUserAuthenticated()) {
      final user = HiveUtils.getUserDetails();
      emit(
        state.copyWith(
          fullName: user.name ?? '',
          phoneNumber: user.mobile ?? '',
        ),
      );
    }

    await Future.wait([_loadCars(), _loadCities()]);
  }

  Future<void> _loadCars() async {
    emit(state.copyWith(isLoadingCars: true));
    try {
      final carModels = await _repository.fetchCarModels();
      emit(state.copyWith(carModels: carModels, isLoadingCars: false));
    } catch (_) {
      emit(state.copyWith(isLoadingCars: false));
      _emitFeedback('Unable to load cars right now.');
    }
  }

  Future<void> _loadCities() async {
    final hasCachedCities = state.cities.isNotEmpty;
    if (!hasCachedCities) {
      emit(
        state.copyWith(isLoadingCities: true, clearCitiesErrorMessage: true),
      );
    }
    try {
      final cities = await _repository.fetchCities();
      emit(
        state.copyWith(
          cities: cities,
          isLoadingCities: false,
          clearCitiesErrorMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingCities: false,
          citiesErrorMessage: 'Unable to load cities right now.',
        ),
      );
    }
  }

  void updateFullName(String value) => emit(state.copyWith(fullName: value));

  void updatePhoneNumber(String value) =>
      emit(state.copyWith(phoneNumber: value));

  void updateCarVariant(String value) =>
      emit(state.copyWith(carVariant: value));

  void updateVisitArea(String value) => emit(state.copyWith(visitArea: value));

  void updateCarType(bool isUsedCar) =>
      emit(state.copyWith(isUsedCar: isUsedCar));

  void selectLivingCity(City city) =>
      emit(state.copyWith(selectedLivingCity: city));

  void selectCar(CarModelModel car) {
    if (car.id == state.selectedCar?.id) return;
    emit(
      state.copyWith(
        selectedCar: car,
        carVariant: '',
        clearSelectedModelYear: true,
      ),
    );
  }

  void selectModelYear(int year) =>
      emit(state.copyWith(selectedModelYear: year));

  void selectRegistrationArea(String area) {
    emit(state.copyWith(selectedRegistrationArea: area));
  }

  void selectVisitDate(DateTime date) {
    emit(state.copyWith(selectedVisitDate: date, clearSelectedTimeSlot: true));
  }

  void selectTimeSlot(ServiceBookingTimeSlot slot) {
    emit(state.copyWith(selectedTimeSlot: slot));
  }

  void clearFeedback() => emit(state.copyWith(clearFeedbackMessage: true));

  void goBackStep() {
    if (state.currentStepIndex == 0) return;
    emit(state.copyWith(currentStepIndex: 0));
  }

  void continueToVisitStep() {
    final errorMessage = _validateBasicInfo();
    if (errorMessage != null) {
      _emitFeedback(errorMessage);
      return;
    }
    emit(state.copyWith(currentStepIndex: 1));
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;

    final errorMessage = _validateBasicInfo() ?? _validateVisitInfo();
    if (errorMessage != null) {
      _emitFeedback(errorMessage);
      return;
    }

    emit(state.copyWith(isSubmitting: true));
    try {
      final result = await _requestRepository.submit(_buildPayload());
      emit(
        state.copyWith(
          isSubmitting: false,
          submissionResult: result,
          submissionToken: state.submissionToken + 1,
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(isSubmitting: false));
      _emitFeedback(error.errorMessage.toString());
    } catch (_) {
      emit(state.copyWith(isSubmitting: false));
      _emitFeedback('Unable to submit the service request. Please try again.');
    }
  }

  String? _validateBasicInfo() {
    final expectedPackageType =
        state.flowType == ServiceBookingFlowType.inspection
        ? 'car_inspection'
        : 'sell_for_me';
    if (state.package.id > 0 && state.package.type != expectedPackageType) {
      return 'The selected package does not match this service.';
    }
    if (state.fullName.trim().isEmpty) return 'Full name is required.';
    if (state.fullName.trim().length > 150) {
      return 'Full name must not exceed 150 characters.';
    }
    if (state.phoneNumber.trim().isEmpty) return 'Phone number is required.';
    if (state.phoneNumber.trim().length > 30) {
      return 'Phone number must not exceed 30 characters.';
    }
    if (state.selectedLivingCity == null) return 'Please select your city.';
    if (state.selectedCar == null) return 'Please select a car.';
    if (state.selectedModelYear == null) return 'Please select model year.';
    if (state.selectedModelYear! < 1990 ||
        state.selectedModelYear! > DateTime.now().year) {
      return 'Please select a valid model year.';
    }
    if (state.carVariant.trim().isEmpty) return 'Please enter the car variant.';
    if (state.carVariant.trim().length > 150) {
      return 'Car variant must not exceed 150 characters.';
    }
    if (state.flowType == ServiceBookingFlowType.sellItForMe &&
        state.selectedRegistrationArea == null) {
      return 'Please select the vehicle registration area.';
    }
    if (state.selectedRegistrationArea != null &&
        !registrationAreas.contains(state.selectedRegistrationArea)) {
      return 'Please select a valid vehicle registration area.';
    }
    return null;
  }

  String? _validateVisitInfo() {
    if (state.visitArea.trim().isEmpty) return 'Please enter area.';
    if (state.visitArea.trim().length > 255) {
      return 'Area must not exceed 255 characters.';
    }
    if (state.selectedVisitDate == null) return 'Please select a visit date.';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visitDate = state.selectedVisitDate!;
    if (DateTime(
      visitDate.year,
      visitDate.month,
      visitDate.day,
    ).isBefore(today)) {
      return 'Visit date cannot be in the past.';
    }
    if (state.selectedTimeSlot == null) return 'Please select a time slot.';
    if (state.selectedTimeSlot!.startHour < 10 ||
        state.selectedTimeSlot!.startHour > 16) {
      return 'Please select a valid time slot.';
    }
    return null;
  }

  ServiceRequestPayload _buildPayload() {
    final date = state.selectedVisitDate!;
    final startHour = state.selectedTimeSlot!.startHour;
    return ServiceRequestPayload(
      type: state.flowType == ServiceBookingFlowType.inspection
          ? ServiceRequestType.carInspection
          : ServiceRequestType.sellForMe,
      servicePackageId: state.package.id > 0 ? state.package.id : null,
      fullName: state.fullName,
      phoneNumber: state.phoneNumber,
      cityId: state.selectedLivingCity!.id,
      carModelId: state.selectedCar!.id,
      modelYear: state.selectedModelYear!,
      carVariant: state.carVariant,
      carCondition: state.isUsedCar ? 'used' : 'new',
      registrationArea: state.selectedRegistrationArea,
      visitArea: state.visitArea,
      visitDate: _formatDate(date),
      visitStartTime: _formatTime(startHour),
      visitEndTime: _formatTime(startHour + 1),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatTime(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00:00';
  }

  void _emitFeedback(String message) {
    emit(
      state.copyWith(
        feedbackMessage: message,
        feedbackToken: state.feedbackToken + 1,
      ),
    );
  }
}
