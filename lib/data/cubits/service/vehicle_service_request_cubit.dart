import 'package:eClassify/data/model/car_model_model.dart';
import 'package:eClassify/data/repositories/service/service_lead_repository.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VehicleServiceRequestState {
  final int currentStepIndex;
  final bool isSubmitting;
  final bool isLoadingCars;
  final List<CarModelModel> carModels;
  final String fullName;
  final String phoneNumber;
  final bool? isFiler;
  final String carVariant;
  final String registrationPlace;
  final CarModelModel? selectedCar;
  final int? selectedModelYear;
  final String? feedbackMessage;
  final int feedbackToken;

  const VehicleServiceRequestState({
    required this.currentStepIndex,
    required this.isSubmitting,
    required this.isLoadingCars,
    required this.carModels,
    required this.fullName,
    required this.phoneNumber,
    required this.carVariant,
    required this.registrationPlace,
    this.isFiler,
    this.selectedCar,
    this.selectedModelYear,
    this.feedbackMessage,
    this.feedbackToken = 0,
  });

  const VehicleServiceRequestState.initial()
    : currentStepIndex = 0,
      isSubmitting = false,
      isLoadingCars = true,
      carModels = const [],
      fullName = '',
      phoneNumber = '',
      carVariant = '',
      registrationPlace = '',
      isFiler = null,
      selectedCar = null,
      selectedModelYear = null,
      feedbackMessage = null,
      feedbackToken = 0;

  VehicleServiceRequestState copyWith({
    int? currentStepIndex,
    bool? isSubmitting,
    bool? isLoadingCars,
    List<CarModelModel>? carModels,
    String? fullName,
    String? phoneNumber,
    bool? isFiler,
    String? carVariant,
    String? registrationPlace,
    CarModelModel? selectedCar,
    int? selectedModelYear,
    String? feedbackMessage,
    bool clearSelectedCar = false,
    bool clearSelectedModelYear = false,
    bool clearFeedbackMessage = false,
    int? feedbackToken,
  }) {
    return VehicleServiceRequestState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingCars: isLoadingCars ?? this.isLoadingCars,
      carModels: carModels ?? this.carModels,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isFiler: isFiler ?? this.isFiler,
      carVariant: carVariant ?? this.carVariant,
      registrationPlace: registrationPlace ?? this.registrationPlace,
      selectedCar: clearSelectedCar ? null : (selectedCar ?? this.selectedCar),
      selectedModelYear: clearSelectedModelYear
          ? null
          : (selectedModelYear ?? this.selectedModelYear),
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      feedbackToken: feedbackToken ?? this.feedbackToken,
    );
  }
}

class VehicleServiceRequestCubit extends Cubit<VehicleServiceRequestState> {
  VehicleServiceRequestCubit({ServiceLeadRepository? repository})
    : _repository = repository ?? ServiceLeadRepository(),
      super(const VehicleServiceRequestState.initial());

  final ServiceLeadRepository _repository;

  static const List<String> registrationPlaces = [
    'Punjab',
    'KPK',
    'Sindh',
    'Balochistan',
    'AJK',
  ];

  static final List<int> modelYears = [
    for (int year = DateTime.now().year; year >= 1990; year--) year,
  ];

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

    await _loadCars();
  }

  Future<void> _loadCars() async {
    emit(state.copyWith(isLoadingCars: true));
    try {
      final carModels = await _repository.fetchCarModels();
      emit(state.copyWith(isLoadingCars: false, carModels: carModels));
    } catch (_) {
      emit(state.copyWith(isLoadingCars: false));
      _emitFeedback('Unable to load cars right now.');
    }
  }

  void updateFullName(String value) => emit(state.copyWith(fullName: value));

  void updatePhoneNumber(String value) => emit(state.copyWith(phoneNumber: value));

  void updateFiler(bool value) => emit(state.copyWith(isFiler: value));

  void updateCarVariant(String value) => emit(state.copyWith(carVariant: value));

  void updateRegistrationPlace(String value) {
    emit(state.copyWith(registrationPlace: value));
  }

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

  void selectModelYear(int year) => emit(state.copyWith(selectedModelYear: year));

  void clearFeedback() => emit(state.copyWith(clearFeedbackMessage: true));

  void goBack() {
    if (state.currentStepIndex == 0) return;
    emit(state.copyWith(currentStepIndex: state.currentStepIndex - 1));
  }

  void continueToCarInfo() {
    final errorMessage = _validateBasicInfo();
    if (errorMessage != null) {
      _emitFeedback(errorMessage);
      return;
    }
    emit(state.copyWith(currentStepIndex: 1));
  }

  Future<void> submit() async {
    final errorMessage = _validateBasicInfo() ?? _validateCarInfo();
    if (errorMessage != null) {
      _emitFeedback(errorMessage);
      return;
    }

    emit(state.copyWith(isSubmitting: true));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    emit(state.copyWith(isSubmitting: false, currentStepIndex: 2));
  }

  String? _validateBasicInfo() {
    if (state.fullName.trim().isEmpty) return 'Please enter full name.';
    if (state.phoneNumber.trim().isEmpty) return 'Please enter phone number.';
    if (state.isFiler == null) return 'Please select filer status.';
    return null;
  }

  String? _validateCarInfo() {
    if (state.selectedCar == null) return 'Please select a car.';
    if (state.selectedModelYear == null) return 'Please select model year.';
    if (state.carVariant.trim().isEmpty) return 'Please enter the car variant.';
    if (state.registrationPlace.isEmpty) {
      return 'Please select registration place.';
    }
    return null;
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
