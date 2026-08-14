import 'dart:async';
import 'package:dio/dio.dart';
import '../services/token_storage.dart';

class SingleFlightAuthInterceptor extends Interceptor {
  final Dio dio;
  final TokenStorage tokenStorage;
  final Future<void> Function()? onUnauthenticated;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

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

      String? newAccessToken;

      if (_isRefreshing) {
        // Wait for existing in-flight refresh
        newAccessToken = await _refreshCompleter?.future;
      } else {
        _isRefreshing = true;
        _refreshCompleter = Completer<String?>();

        try {
          final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
          final response = await refreshDio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200 && response.data != null) {
            newAccessToken = response.data['access_token'] as String?;
            final newRefreshToken = response.data['refresh_token'] as String?;

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await tokenStorage.saveAccessToken(newAccessToken);
              if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                await tokenStorage.saveRefreshToken(newRefreshToken);
              }
              _refreshCompleter?.complete(newAccessToken);
            } else {
              _refreshCompleter?.complete(null);
            }
          } else {
            _refreshCompleter?.complete(null);
          }
        } catch (_) {
          _refreshCompleter?.complete(null);
        } finally {
          _isRefreshing = false;
        }
      }

      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';
        opts.extra['_isRetry'] = true;
        try {
          final retriedResponse = await dio.fetch(opts);
          return handler.resolve(retriedResponse);
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      } else {
        // Refresh failed with 401/error -> clear tokens and end session
        await tokenStorage.clearAllTokens();
        if (onUnauthenticated != null) {
          await onUnauthenticated!();
        }
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
