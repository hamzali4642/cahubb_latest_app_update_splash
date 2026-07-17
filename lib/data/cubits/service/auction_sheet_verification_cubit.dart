import 'package:eClassify/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuctionSheetVerificationState {
  final String chassisNumber;
  final String phoneNumber;
  final String? feedbackMessage;
  final int feedbackToken;

  const AuctionSheetVerificationState({
    required this.chassisNumber,
    required this.phoneNumber,
    this.feedbackMessage,
    this.feedbackToken = 0,
  });

  const AuctionSheetVerificationState.initial()
    : chassisNumber = '',
      phoneNumber = '',
      feedbackMessage = null,
      feedbackToken = 0;

  AuctionSheetVerificationState copyWith({
    String? chassisNumber,
    String? phoneNumber,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
    int? feedbackToken,
  }) {
    return AuctionSheetVerificationState(
      chassisNumber: chassisNumber ?? this.chassisNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      feedbackToken: feedbackToken ?? this.feedbackToken,
    );
  }
}

class AuctionSheetVerificationCubit
    extends Cubit<AuctionSheetVerificationState> {
  AuctionSheetVerificationCubit()
    : super(const AuctionSheetVerificationState.initial());

  void initialize() {
    if (!HiveUtils.isUserAuthenticated()) return;
    emit(state.copyWith(phoneNumber: HiveUtils.getUserDetails().mobile ?? ''));
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
    if (state.chassisNumber.trim().isEmpty) {
      _emitFeedback('Please enter chassis number.');
      return false;
    }
    return true;
  }

  bool notifyMe() {
    if (state.phoneNumber.trim().isEmpty) {
      _emitFeedback('Please enter phone number.');
      return false;
    }

    _emitFeedback(
      'Auction sheet alert saved for ${state.chassisNumber.trim()}. Backend will be connected next.',
    );
    return true;
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
