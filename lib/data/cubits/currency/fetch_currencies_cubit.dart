import 'package:collection/collection.dart';
import 'package:eClassify/data/model/currency.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/app_session.dart';
import 'package:eClassify/utils/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchCurrenciesState {}

class FetchCurrenciesInitial extends FetchCurrenciesState {}

class FetchCurrenciesInProgress extends FetchCurrenciesState {}

class FetchCurrenciesSuccess extends FetchCurrenciesState {
  final List<Currency> currencies;

  FetchCurrenciesSuccess(this.currencies);
}

class FetchCurrenciesFailure extends FetchCurrenciesState {
  final String errorMessage;

  FetchCurrenciesFailure(this.errorMessage);
}

class FetchCurrenciesCubit extends Cubit<FetchCurrenciesState> {
  FetchCurrenciesCubit() : super(FetchCurrenciesInitial());

  List<Currency> _currencies = [];

  List<Currency> get currencies => _currencies;

  Currency? getSelectedCurrency() {
    if (_currencies.isEmpty) return null;
    // Find currency with selected = 1, or return first one
    return _currencies.firstWhereOrNull(
      (currency) => currency.selected == 1,
    ) ?? _currencies.firstOrNull;
  }

  Future<void> fetchCurrencies() async {
    try {
      emit(FetchCurrenciesInProgress());
      Map<String, dynamic> response = await Api.get(
        url: Api.getCurrenciesApi,
          queryParameters: {
            'country': ?AppSession.currentLocation?.country?.canonical
          }
      );

      // Parse currencies from response
      List<Currency> currencyList = [];
      if (response['data'] != null && response['data'] is List) {
        currencyList = (response['data'] as List)
            .map((element) => Currency.fromJson(element))
            .toList();
      }

      _currencies = currencyList;
      emit(FetchCurrenciesSuccess(_currencies));
    } catch (e, st) {
      Log.error(e.toString(), e, st);
      emit(FetchCurrenciesFailure(e.toString()));
    }
  }
}
