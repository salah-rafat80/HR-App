import 'dart:async';
import 'package:dio/dio.dart';
import '../services/token_storage.dart';

class RefreshResult {
  final String? accessToken;
  final bool isAuthError;
  final DioException? networkException;

  RefreshResult({
    this.accessToken,
    this.isAuthError = false,
    this.networkException,
  });
}

class SingleFlightAuthInterceptor extends Interceptor {
  final Dio dio;
  final TokenStorage tokenStorage;
  final Future<void> Function()? onUnauthenticated;

  bool _isRefreshing = false;
  Completer<RefreshResult>? _refreshCompleter;

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

      RefreshResult result;

      if (_isRefreshing) {
        final completedResult = await _refreshCompleter?.future;
        result = completedResult ?? RefreshResult(isAuthError: true);
      } else {
        _isRefreshing = true;
        _refreshCompleter = Completer<RefreshResult>();

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

          if (response.statusCode == 200 && response.data != null) {
            final newAccessToken = response.data['access_token'] as String?;
            final newRefreshToken = response.data['refresh_token'] as String?;

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await tokenStorage.saveAccessToken(newAccessToken);
              if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                await tokenStorage.saveRefreshToken(newRefreshToken);
              }
              result = RefreshResult(accessToken: newAccessToken);
            } else {
              result = RefreshResult(isAuthError: true);
            }
          } else {
            result = RefreshResult(isAuthError: true);
          }
        } on DioException catch (refreshErr) {
          final statusCode = refreshErr.response?.statusCode;
          if (statusCode == 401 || statusCode == 403) {
            result = RefreshResult(isAuthError: true);
          } else {
            result = RefreshResult(networkException: refreshErr);
          }
        } catch (_) {
          result = RefreshResult(isAuthError: true);
        } finally {
          _isRefreshing = false;
        }

        if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(result);
        }
      }

      if (result.accessToken != null && result.accessToken!.isNotEmpty) {
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer ${result.accessToken}';
        opts.extra['_isRetry'] = true;
        try {
          final retriedResponse = await dio.fetch(opts);
          return handler.resolve(retriedResponse);
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      } else if (result.isAuthError) {
        await tokenStorage.clearAllTokens();
        if (onUnauthenticated != null) {
          await onUnauthenticated!();
        }
        return handler.next(err);
      } else if (result.networkException != null) {
        return handler.next(result.networkException!);
      }
    }

    return handler.next(err);
  }
}
