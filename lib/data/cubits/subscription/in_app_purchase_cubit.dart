import 'package:eClassify/data/repositories/subscription/in_app_purchase_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class InAppPurchaseState {}

class InAppPurchaseInitial extends InAppPurchaseState {}

class InAppPurchaseInProgress extends InAppPurchaseState {}

class InAppPurchaseInSuccess extends InAppPurchaseState {
  final String responseMessage;

  InAppPurchaseInSuccess(this.responseMessage);
}

class InAppPurchaseFailure extends InAppPurchaseState {
  final dynamic error;

  InAppPurchaseFailure(this.error);
}

class InAppPurchaseCubit extends Cubit<InAppPurchaseState> {
  InAppPurchaseCubit() : super(InAppPurchaseInitial());

  final InAppPurchaseRepository repository = InAppPurchaseRepository();

  void inAppPurchase({
    required String method,
    required String packageId,
    required String paymentTransactionId,
  }) {
    emit(InAppPurchaseInProgress());

    repository
        .inAppPurchases(
          method: method,
          packageId: packageId,
          paymentTransactionId: paymentTransactionId,
        )
        .then((value) {
          emit(InAppPurchaseInSuccess(value['message']));
        })
        .catchError((e) {
          emit(InAppPurchaseFailure(e.toString()));
        });
  }
}
