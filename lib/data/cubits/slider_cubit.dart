import 'dart:developer';

import 'package:eClassify/data/model/home/home_slider.dart';
import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/data/repositories/home/slider_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SliderState {}

class SliderInitial extends SliderState {}

class SliderFetchInProgress extends SliderState {}

class SliderFetchInInternalProgress extends SliderState {}

class SliderFetchSuccess extends SliderState {
  SliderFetchSuccess(this.sliders);

  final List<HomeSlider> sliders;
}

class SliderFetchFailure extends SliderState {
  SliderFetchFailure(this.errorMessage);
  final String errorMessage;
}

class SliderCubit extends Cubit<SliderState> {
  SliderCubit() : super(SliderInitial());

  final SliderRepository _repository = SliderRepository();

  Future<void> fetchSliders({required LeafLocation? location}) async {
    try {
      emit(SliderFetchInProgress());
      final sliders = await _repository.fetchSliders(location: location);
      emit(SliderFetchSuccess(sliders));
    } catch (e, st) {
      log('$e', name: 'fetchSliders');
      log('$st', name: 'fetchSliders');
      emit(SliderFetchFailure(e.toString()));
    }
  }
}
