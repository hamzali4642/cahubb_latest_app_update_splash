import 'package:eClassify/data/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ResetPasswordState {}

class ResetPasswordInitial extends ResetPasswordState {}

class ResetPasswordInProgress extends ResetPasswordState {}

class ResetPasswordSuccess extends ResetPasswordState {}

class ResetPasswordFailure extends ResetPasswordState {
  final String errorMessage;

  ResetPasswordFailure(this.errorMessage);
}

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  final AuthRepository _authRepository = AuthRepository();

  ResetPasswordCubit() : super(ResetPasswordInitial());

  Future<void> resetPassword({
    required String phoneNumber,
    required String countryCode,
    required String newPassword,
  }) async {
    try {
      emit(ResetPasswordInProgress());

      await _authRepository.resetPassword(
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        newPassword: newPassword,
      );

      emit(ResetPasswordSuccess());
    } catch (e) {
      emit(ResetPasswordFailure(e.toString()));
    }
  }
}
