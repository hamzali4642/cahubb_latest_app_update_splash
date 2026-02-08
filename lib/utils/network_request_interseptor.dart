import 'package:dio/dio.dart';
import 'package:eClassify/utils/log.dart';

class NetworkRequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Log.info(
      '${options.method} ${options.uri.path} ${options.queryParameters.isNotEmpty ? options.queryParameters : ''}',
    );
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Log.error(
      '${err.requestOptions.method} ${err.requestOptions.uri.path}\n${err.response?.statusCode} ${err.response?.statusMessage}',
      err.error,
      err.stackTrace,
    );

    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }
}
