import 'package:eClassify/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Base state for API keys
abstract class GetApiKeysState {}

class GetApiKeysInitial extends GetApiKeysState {}

class GetApiKeysInProgress extends GetApiKeysState {}

class GetApiKeysFail extends GetApiKeysState {
  final String error;
  GetApiKeysFail(this.error);
}

/// Success state containing all payment gateway settings
class GetApiKeysSuccess extends GetApiKeysState {
  // Bank transfer details
  final String? bankAccountHolder;
  final String? bankAccountNumber;
  final String? bankName;
  final String? bankIfscSwiftCode;

  final int bankTransferStatus;

  GetApiKeysSuccess({
    this.bankAccountHolder,
    this.bankAccountNumber,
    this.bankName,
    this.bankIfscSwiftCode,
    this.bankTransferStatus = 0,
  });
}

/// Cubit responsible for managing payment API keys and settings
class GetApiKeysCubit extends Cubit<GetApiKeysState> {
  GetApiKeysCubit() : super(GetApiKeysInitial());

  /// Fetches payment API keys and settings from the server
  Future<void> fetch() async {
    try {
      emit(GetApiKeysInProgress());

      final result = await Api.get(url: Api.getPaymentSettingsApi);
      final data = result['data'] ?? {};

      emit(
        GetApiKeysSuccess(
          bankAccountHolder: _getData(
            data,
            Api.bankTransfer,
            Api.accountHolderName,
          ),
          bankAccountNumber: _getData(
            data,
            Api.bankTransfer,
            Api.accountNumber,
          ),
          bankName: _getData(data, Api.bankTransfer, Api.bankName),
          bankIfscSwiftCode: _getData(
            data,
            Api.bankTransfer,
            Api.ifscSwiftCode,
          ),
          bankTransferStatus: _getIntData(data, Api.bankTransfer, Api.status),
        ),
      );
    } catch (e) {
      emit(GetApiKeysFail(e.toString()));
    }
  }

  /// Gets string data from nested map with default value
  ///
  /// [data] - The data map to search in
  /// [type] - The payment gateway type
  /// [key] - The key to look up
  /// [defaultValue] - Default value if key is not found
  String _getData(
    Map<String, dynamic> data,
    String type,
    String key, {
    String defaultValue = '',
  }) => data[type]?[key]?.toString() ?? defaultValue;

  /// Gets integer data from nested map with default value
  ///
  /// [data] - The data map to search in
  /// [type] - The payment gateway type
  /// [key] - The key to look up
  /// [defaultValue] - Default value if key is not found
  int _getIntData(
    Map<String, dynamic> data,
    String type,
    String key, {
    int defaultValue = 0,
  }) =>
      int.tryParse(
        _getData(data, type, key, defaultValue: defaultValue.toString()),
      ) ??
      defaultValue;
}
