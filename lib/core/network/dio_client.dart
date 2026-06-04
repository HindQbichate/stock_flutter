import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    _LogInterceptor(),
    _AuthInterceptor(),
    _ErrorInterceptor(),
  ]);

  return dio;
});

// ─── Log Interceptor ───────────────────────────────────────────────────────
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('→ [${options.method}] ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('← [${response.statusCode}] ${response.requestOptions.uri}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('✗ [${err.response?.statusCode}] ${err.message}');
    super.onError(err, handler);
  }
}

// ─── Auth Interceptor ──────────────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Firebase Auth token will be injected here if needed for external APIs
    // For Firestore SDK calls, Firebase handles auth automatically
    super.onRequest(options, handler);
  }
}

// ─── Error Interceptor ─────────────────────────────────────────────────────
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = switch (err.type) {
      DioExceptionType.connectionTimeout => 'Délai de connexion dépassé',
      DioExceptionType.receiveTimeout => 'Délai de réponse dépassé',
      DioExceptionType.connectionError => 'Pas de connexion internet',
      DioExceptionType.badResponse => _parseStatusCode(err.response?.statusCode),
      _ => err.message ?? 'Erreur inconnue',
    };

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: message,
        type: err.type,
        response: err.response,
      ),
    );
  }

  String _parseStatusCode(int? code) => switch (code) {
        400 => 'Requête invalide',
        401 => 'Non autorisé',
        403 => 'Accès interdit',
        404 => 'Ressource introuvable',
        500 => 'Erreur serveur interne',
        _ => 'Erreur HTTP $code',
      };
}
