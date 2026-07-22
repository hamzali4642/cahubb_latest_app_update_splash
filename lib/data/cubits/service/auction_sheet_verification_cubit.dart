import 'package:eClassify/data/model/service/auction_sheet_verification_model.dart';
import 'package:eClassify/data/repositories/service/auction_sheet_verification_repository.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/pakistan_phone_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuctionSheetVerificationState {
  const AuctionSheetVerificationState({
    required this.chassisNumber,
    required this.phoneNumber,
    required this.isPriceLoading,
    required this.isSubmitting,
    required this.feedbackToken,
    this.price,
    this.priceErrorMessage,
    this.feedbackMessage,
    this.result,
  });

  const AuctionSheetVerificationState.initial()
    : chassisNumber = '',
      phoneNumber = '',
      isPriceLoading = true,
      isSubmitting = false,
      price = null,
      priceErrorMessage = null,
      feedbackMessage = null,
      feedbackToken = 0,
      result = null;

  final String chassisNumber;
  final String phoneNumber;
  final bool isPriceLoading;
  final bool isSubmitting;
  final AuctionSheetVerificationPrice? price;
  final String? priceErrorMessage;
  final String? feedbackMessage;
  final int feedbackToken;
  final AuctionSheetVerificationResult? result;

  AuctionSheetVerificationState copyWith({
    String? chassisNumber,
    String? phoneNumber,
    bool? isPriceLoading,
    bool? isSubmitting,
    AuctionSheetVerificationPrice? price,
    String? priceErrorMessage,
    String? feedbackMessage,
    int? feedbackToken,
    AuctionSheetVerificationResult? result,
    bool clearPriceErrorMessage = false,
    bool clearFeedbackMessage = false,
  }) {
    return AuctionSheetVerificationState(
      chassisNumber: chassisNumber ?? this.chassisNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPriceLoading: isPriceLoading ?? this.isPriceLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      price: price ?? this.price,
      priceErrorMessage: clearPriceErrorMessage
          ? null
          : (priceErrorMessage ?? this.priceErrorMessage),
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      feedbackToken: feedbackToken ?? this.feedbackToken,
      result: result ?? this.result,
    );
  }
}

class AuctionSheetVerificationCubit
    extends Cubit<AuctionSheetVerificationState> {
  AuctionSheetVerificationCubit({
    AuctionSheetVerificationRepository? repository,
  }) : _repository = repository ?? const AuctionSheetVerificationRepository(),
       super(const AuctionSheetVerificationState.initial());

  final AuctionSheetVerificationRepository _repository;

  Future<void> initialize() async {
    if (HiveUtils.isUserAuthenticated()) {
      emit(
        state.copyWith(
          phoneNumber: PakistanPhoneUtils.localNumber(
            HiveUtils.getUserDetails().mobile ?? '',
          ),
        ),
      );
    }
    await fetchPrice();
  }

  Future<void> fetchPrice() async {
    if (state.isPriceLoading && state.price != null) return;
    emit(state.copyWith(isPriceLoading: true, clearPriceErrorMessage: true));
    try {
      final price = await _repository.fetchPrice();
      emit(
        state.copyWith(
          isPriceLoading: false,
          price: price,
          clearPriceErrorMessage: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          isPriceLoading: false,
          priceErrorMessage: error.errorMessage.toString(),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isPriceLoading: false,
          priceErrorMessage: 'Unable to load the verification price.',
        ),
      );
    }
  }

  void updateChassisNumber(String value) {
    emit(state.copyWith(chassisNumber: value));
  }

  void updatePhoneNumber(String value) {
    emit(state.copyWith(phoneNumber: value));
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedbackMessage: true));
  }

  bool requestVerification() {
    final error = _validateChassisNumber();
    if (error != null) {
      _emitFeedback(error);
      return false;
    }
    return true;
  }

  Future<bool> notifyMe() async {
    if (state.isSubmitting) return false;
    final error = _validateChassisNumber() ?? _validatePhoneNumber();
    if (error != null) {
      _emitFeedback(error);
      return false;
    }

    final normalizedChassis = _normalizeChassisNumber(state.chassisNumber);
    final phoneNumber = PakistanPhoneUtils.normalize(state.phoneNumber);
    emit(
      state.copyWith(
        chassisNumber: normalizedChassis,
        phoneNumber: phoneNumber,
        isSubmitting: true,
      ),
    );
    try {
      final result = await _repository.submitRequest(
        chassisNumber: normalizedChassis,
        phoneNumber: phoneNumber,
      );
      emit(
        state.copyWith(
          chassisNumber: '',
          phoneNumber: '',
          isSubmitting: false,
          result: result,
        ),
      );
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isSubmitting: false));
      _emitFeedback(error.errorMessage.toString());
      return false;
    } catch (_) {
      emit(state.copyWith(isSubmitting: false));
      _emitFeedback(
        'Unable to submit the auction sheet verification request. Please try again.',
      );
      return false;
    }
  }

  String? _validateChassisNumber() {
    final chassisNumber = _normalizeChassisNumber(state.chassisNumber);
    if (chassisNumber.isEmpty) return 'Please enter chassis number.';
    if (chassisNumber.length > 50) {
      return 'Chassis number must not exceed 50 characters.';
    }
    if (!RegExp(r'^[A-Z0-9]+(?:-[A-Z0-9]+)*$').hasMatch(chassisNumber) ||
        !RegExp(r'[A-Z]').hasMatch(chassisNumber) ||
        !RegExp(r'[0-9]').hasMatch(chassisNumber)) {
      return 'Please enter a valid Japanese chassis number.';
    }
    return null;
  }

  String? _validatePhoneNumber() {
    final phoneNumber = state.phoneNumber.trim();
    if (phoneNumber.isEmpty) return 'Please enter phone number.';
    if (!PakistanPhoneUtils.isValid(phoneNumber)) {
      return 'Please enter a valid 10-digit phone number.';
    }
    return null;
  }

  static String _normalizeChassisNumber(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[‐‑‒–—―−]'), '-')
        .replaceAll(RegExp(r'\s+'), '');
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
