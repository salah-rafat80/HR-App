import 'dart:async';
import 'package:dio/dio.dart';
import '../services/token_storage.dart';

enum RefreshStatus {
  success,
  authFailure,
  networkOrServerError,
}

class RefreshCycleResult {
  final RefreshStatus status;
  final String? accessToken;
  final DioException? dioException;

  RefreshCycleResult({
    required this.status,
    this.accessToken,
    this.dioException,
  });
}

class SingleFlightAuthInterceptor extends Interceptor {
  final Dio dio;
  final TokenStorage tokenStorage;
  final Future<void> Function()? onUnauthenticated;

  bool _isRefreshing = false;
  Completer<RefreshCycleResult>? _refreshCompleter;

  SingleFlightAuthInterceptor({
    required this.dio,
    required this.tokenStorage,
    this.onUnauthenticated,
  });

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Exclude auth endpoints from attaching stale headers
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh')) {
      options.headers.remove('Authorization');
      return handler.next(options);
    }

    final token = await tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.contains('/auth/login') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/me');

    final isRetry = err.requestOptions.extra['_isRetry'] == true;

    if (err.response?.statusCode == 401 && !isAuthEndpoint && !isRetry) {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await tokenStorage.clearAllTokens();
        if (onUnauthenticated != null) {
          await onUnauthenticated!();
        }
        return handler.next(err);
      }

      RefreshCycleResult cycleResult;

      if (_isRefreshing) {
        final waiterResult = await _refreshCompleter?.future;
        cycleResult = waiterResult ??
            RefreshCycleResult(status: RefreshStatus.networkOrServerError);
      } else {
        _isRefreshing = true;
        _refreshCompleter = Completer<RefreshCycleResult>();

        try {
          final refreshDio = Dio(BaseOptions(
            baseUrl: dio.options.baseUrl,
            connectTimeout: dio.options.connectTimeout,
            receiveTimeout: dio.options.receiveTimeout,
          ));
          refreshDio.httpClientAdapter = dio.httpClientAdapter;

          final response = await refreshDio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200 && response.data is Map) {
            final dataMap = response.data as Map;
            final newAccessToken = dataMap['access_token'] as String?;
            final newRefreshToken = dataMap['refresh_token'] as String?;

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await tokenStorage.saveAccessToken(newAccessToken);
              if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                await tokenStorage.saveRefreshToken(newRefreshToken);
              }
              cycleResult = RefreshCycleResult(
                status: RefreshStatus.success,
                accessToken: newAccessToken,
              );
            } else {
              cycleResult = RefreshCycleResult(
                status: RefreshStatus.networkOrServerError,
                dioException: DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  error: 'Malformed refresh response: missing access_token',
                ),
              );
            }
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            await tokenStorage.clearAllTokens();
            if (onUnauthenticated != null) {
              await onUnauthenticated!();
            }
            cycleResult = RefreshCycleResult(status: RefreshStatus.authFailure);
          } else {
            cycleResult = RefreshCycleResult(
              status: RefreshStatus.networkOrServerError,
              dioException: DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: 'Server error during refresh: ${response.statusCode}',
              ),
            );
          }
        } on DioException catch (refreshErr) {
          final statusCode = refreshErr.response?.statusCode;
          if (statusCode == 401 || statusCode == 403) {
            await tokenStorage.clearAllTokens();
            if (onUnauthenticated != null) {
              await onUnauthenticated!();
            }
            cycleResult = RefreshCycleResult(status: RefreshStatus.authFailure);
          } else {
            cycleResult = RefreshCycleResult(
              status: RefreshStatus.networkOrServerError,
              dioException: refreshErr,
            );
          }
        } catch (e) {
          cycleResult = RefreshCycleResult(
            status: RefreshStatus.networkOrServerError,
            dioException: DioException(
              requestOptions: err.requestOptions,
              error: e,
            ),
          );
        } finally {
          _isRefreshing = false;
        }

        if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(cycleResult);
        }
      }

      if (cycleResult.status == RefreshStatus.success &&
          cycleResult.accessToken != null &&
          cycleResult.accessToken!.isNotEmpty) {
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer ${cycleResult.accessToken}';
        opts.extra['_isRetry'] = true;
        try {
          final retriedResponse = await dio.fetch(opts);
          return handler.resolve(retriedResponse);
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      } else if (cycleResult.status == RefreshStatus.authFailure) {
        return handler.next(err);
      } else {
        final finalErr = cycleResult.dioException ?? err;
        return handler.next(finalErr);
      }
    }

    return handler.next(err);
  }
}
