import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config.dart';

class ApiClient {
  late final Dio _dio;

  int? hourlyRemaining;
  int? dailyRemaining;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        _extractRateLimits(response);
        handler.next(response);
      },
      onError: (error, handler) {
        if (error.response != null) {
          _extractRateLimits(error.response!);
        }
        handler.next(error);
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ));
    }
  }

  void _extractRateLimits(Response response) {
    final headers = response.headers;
    final hourly = headers.value('X-RateLimit-Hourly-Remaining');
    final daily = headers.value('X-RateLimit-Daily-Remaining');
    if (hourly != null) hourlyRemaining = int.tryParse(hourly);
    if (daily != null) dailyRemaining = int.tryParse(daily);
    if (kDebugMode && (hourly != null || daily != null)) {
      debugPrint(
          '[RateLimit] Hourly: $hourlyRemaining, Daily: $dailyRemaining');
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool retry = true,
  }) async {
    int attempts = 0;
    const maxRetries = 2;

    while (true) {
      try {
        attempts++;
        final response = await _dio.get(
          path,
          queryParameters: queryParameters,
        );
        return response;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        // Don't retry for client errors
        if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          throw ApiException.fromDioError(e);
        }

        // Retry for server errors
        if (retry &&
            statusCode != null &&
            statusCode >= 500 &&
            attempts <= maxRetries) {
          final delay = Duration(milliseconds: 500 * attempts);
          if (kDebugMode) {
            debugPrint(
                '[API] Retry $attempts/$maxRetries after ${delay.inMilliseconds}ms');
          }
          await Future.delayed(delay);
          continue;
        }

        throw ApiException.fromDioError(e);
      }
    }
  }
}

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? traceId;
  final String? details;
  final String? path;
  final bool isTimeout;
  final bool isConnectionError;

  ApiException({
    this.statusCode,
    required this.message,
    this.traceId,
    this.details,
    this.path,
    this.isTimeout = false,
    this.isConnectionError = false,
  });

  factory ApiException.fromDioError(DioException error) {
    String? traceId;
    String? details;
    String? path;

    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      traceId = data['traceId'] as String?;
      details = data['details'] as String?;
      path = data['path'] as String?;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Przekroczono czas oczekiwania na odpowiedź.',
          isTimeout: true,
          traceId: traceId,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Brak połączenia z internetem.',
          isConnectionError: true,
        );
      default:
        break;
    }

    final statusCode = error.response?.statusCode;
    String message;

    switch (statusCode) {
      case 400:
        message = 'Nieprawidłowe zapytanie.';
        break;
      case 401:
        message = 'Brak autoryzacji. Sprawdź konfigurację API.';
        break;
      case 403:
        message = 'Brak dostępu do zasobu.';
        break;
      case 404:
        message = 'Nie znaleziono danych.';
        break;
      case 429:
        message = 'Przekroczono limit zapytań. Spróbuj ponownie za chwilę.';
        break;
      default:
        if (statusCode != null && statusCode >= 500) {
          message = 'Błąd serwera. Spróbuj ponownie później.';
        } else {
          message = error.message ?? 'Wystąpił nieznany błąd.';
        }
    }

    // Try to get message from API error response
    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      final apiMessage = data['message'] as String?;
      if (apiMessage != null && apiMessage.isNotEmpty) {
        message = apiMessage;
      }
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      traceId: traceId,
      details: details,
      path: path,
    );
  }

  @override
  String toString() => message;
}
