import 'package:eClassify/data/model/fuel_price_model.dart';
import 'package:eClassify/data/repositories/fuel_prices_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class FetchFuelPricesState {}

class FetchFuelPricesInitial extends FetchFuelPricesState {}

class FetchFuelPricesInProgress extends FetchFuelPricesState {}

class FetchFuelPricesSuccess extends FetchFuelPricesState {
  FetchFuelPricesSuccess(this.fuelPrices);

  final FuelPriceModel fuelPrices;
}

class FetchFuelPricesFailure extends FetchFuelPricesState {
  FetchFuelPricesFailure(this.message);

  final String message;
}

class FetchFuelPricesCubit extends Cubit<FetchFuelPricesState> {
  FetchFuelPricesCubit({FuelPricesRepository? repository})
    : _repository = repository ?? FuelPricesRepository(),
      super(FetchFuelPricesInitial());

  final FuelPricesRepository _repository;

  Future<void> fetch() async {
    emit(FetchFuelPricesInProgress());
    try {
      emit(FetchFuelPricesSuccess(await _repository.fetchLatest()));
    } catch (error) {
      emit(FetchFuelPricesFailure(error.toString()));
    }
  }
}
