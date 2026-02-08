import 'package:flutter_bloc/flutter_bloc.dart';

class ItemReportListCubit extends Cubit<Set<int>> {
  ItemReportListCubit() : super(Set.identity());

  void addItemReport({required int itemId}) => state.add(itemId);

  bool contains({required int itemId}) => state.contains(itemId);

  void clear() => Set.identity();
}
