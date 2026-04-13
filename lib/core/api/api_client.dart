import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../services/token_storage_service.dart';

/// Normalize backend `message` / `error` fields (string, list of validation errors, etc.).
String? _coerceApiBodyMessage(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  if (value is List) {
    final parts =
        value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }
  final s = value.toString();
  return s.isEmpty ? null : s;
}

/// API Client for making HTTP requests
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  String _normalizeBearerToken(String rawToken) {
    final trimmed = rawToken.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed.substring(7).trim();
    }
    return trimmed;
  }

  /// Log API request (optionally via dart:developer for filterable logs)
  void _logRequest(String method, String url, Map<String, String>? headers,
      Map<String, dynamic>? body,
      {String? logTag}) {
    if (!kDebugMode && logTag == null) return;
    final sb = StringBuffer();
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('📤 API REQUEST');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('Method: $method');
    sb.writeln('URL: $url');
    if (headers != null && headers.isNotEmpty) {
      sb.writeln('Headers:');
      headers.forEach((key, value) {
        if (key.toLowerCase() == 'authorization') {
          final masked = value.length > 20 ? "${value.substring(0, 20)}..." : value;
          sb.writeln(
              '  $key: $masked');
        } else {
          sb.writeln('  $key: $value');
        }
      });
      if (!headers.containsKey('Authorization')) {
        sb.writeln('  ⚠️ WARNING: Authorization header is MISSING!');
      }
    } else {
      sb.writeln('⚠️ WARNING: No headers provided!');
    }
    if (body != null && body.isNotEmpty) {
      sb.writeln('Body:');
      try {
        sb.writeln(const JsonEncoder.withIndent('  ').convert(body));
      } catch (e) {
        sb.writeln('  $body');
      }
    }
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final msg = sb.toString();
    if (logTag != null) {
      developer.log(msg, name: logTag);
    } else if (kDebugMode) {
      print(msg);
    }
  }

  /// Log API response (optionally via dart:developer for filterable logs)
  void _logResponse(String method, String url, int statusCode,
      Map<String, dynamic>? response, String? error,
      {String? logTag}) {
    if (!kDebugMode && logTag == null) return;
    final sb = StringBuffer();
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('📥 API RESPONSE');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('Method: $method');
    sb.writeln('URL: $url');
    sb.writeln('Status Code: $statusCode');
    if (error != null) {
      sb.writeln('❌ Error: $error');
    } else if (response != null) {
      sb.writeln('Response:');
      try {
        sb.writeln(const JsonEncoder.withIndent('  ').convert(response));
      } catch (e) {
        sb.writeln('  $response');
      }
    }
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final msg = sb.toString();
    if (logTag != null) {
      developer.log(msg, name: logTag);
    } else if (kDebugMode) {
      print(msg);
    }
  }

  /// Base headers for all requests
  Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
    bool requireAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add authentication token from cache if required (like Dio interceptor)
    if (requireAuth) {
      // Always read token from cache (like Dio onRequest interceptor)
      final token = await TokenStorageService.instance.getAccessToken();

      if (kDebugMode) {
        print('🔑 Token Check (from cache):');
        print('  requireAuth: $requireAuth');
        print('  token exists: ${token != null}');
        print('  token length: ${token?.length ?? 0}');
      }

      if (token != null && token.isNotEmpty) {
        final normalizedToken = _normalizeBearerToken(token);
        headers['Authorization'] = 'Bearer $normalizedToken';
        if (kDebugMode) {
          print('  ✅ Authorization header added from cache');
          print(
              '  token preview: ${normalizedToken.length > 20 ? "${normalizedToken.substring(0, 20)}..." : normalizedToken}');
        }
      } else {
        if (kDebugMode) {
          print('  ⚠️ WARNING: No token found in cache');
          print(
              '  💡 Make sure you are logged in and token is cached correctly');
        }
      }
    } else {
      if (kDebugMode) {
        print('🔓 Auth not required for this request');
      }
    }

    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
      // If additional headers contain Authorization, it will override the one we set
      if (additionalHeaders.containsKey('Authorization')) {
        if (kDebugMode) {
          print('  ℹ️ Authorization header provided in additionalHeaders');
        }
      }
    }

    if (kDebugMode) {
      print('📋 Final headers: ${headers.keys.toList()}');
    }

    return headers;
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
    bool requireAuth = true,
    String? logTag,
  }) async {
    try {
      final finalHeaders = await _getHeaders(
        additionalHeaders: headers,
        requireAuth: requireAuth,
      );

      if (logTag != null) {
        _logRequest('GET', url, finalHeaders, null, logTag: logTag);
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: finalHeaders,
          )
          .timeout(const Duration(seconds: 45));

      final responseData = _handleResponse(response);
      if (logTag != null) {
        _logResponse('GET', url, response.statusCode, responseData, null,
            logTag: logTag);
      }
      return responseData;
    } catch (e) {
      if (logTag != null) {
        _logResponse('GET', url, 0, null, e.toString(), logTag: logTag);
      }
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool requireAuth = true,
    String? logTag,
  }) async {
    try {
      final finalHeaders = await _getHeaders(
        additionalHeaders: headers,
        requireAuth: requireAuth,
      );

      _logRequest('POST', url, finalHeaders, body, logTag: logTag);

      final response = await http
          .post(
            Uri.parse(url),
            headers: finalHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 45));

      final responseData = _handleResponse(response);
      _logResponse('POST', url, response.statusCode, responseData, null,
          logTag: logTag);
      return responseData;
    } catch (e) {
      _logResponse('POST', url, 0, null, e.toString(), logTag: logTag);
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool requireAuth = true,
    String? logTag,
  }) async {
    try {
      final finalHeaders = await _getHeaders(
        additionalHeaders: headers,
        requireAuth: requireAuth,
      );

      _logRequest('PUT', url, finalHeaders, body, logTag: logTag);

      final response = await http
          .put(
            Uri.parse(url),
            headers: finalHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 45));

      final responseData = _handleResponse(response);
      _logResponse('PUT', url, response.statusCode, responseData, null,
          logTag: logTag);
      return responseData;
    } catch (e) {
      _logResponse('PUT', url, 0, null, e.toString(), logTag: logTag);
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool requireAuth = true,
    String? logTag,
  }) async {
    try {
      final finalHeaders = await _getHeaders(
        additionalHeaders: headers,
        requireAuth: requireAuth,
      );

      _logRequest('PATCH', url, finalHeaders, body, logTag: logTag);

      final response = await http
          .patch(
            Uri.parse(url),
            headers: finalHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 45));

      final responseData = _handleResponse(response);
      _logResponse('PATCH', url, response.statusCode, responseData, null,
          logTag: logTag);
      return responseData;
    } catch (e) {
      _logResponse('PATCH', url, 0, null, e.toString(), logTag: logTag);
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, String>? headers,
    bool requireAuth = true,
    String? logTag,
  }) async {
    try {
      final finalHeaders = await _getHeaders(
        additionalHeaders: headers,
        requireAuth: requireAuth,
      );

      _logRequest('DELETE', url, finalHeaders, null, logTag: logTag);

      final response = await http
          .delete(
            Uri.parse(url),
            headers: finalHeaders,
          )
          .timeout(const Duration(seconds: 45));

      final responseData = _handleResponse(response);
      _logResponse('DELETE', url, response.statusCode, responseData, null,
          logTag: logTag);
      return responseData;
    } catch (e) {
      _logResponse('DELETE', url, 0, null, e.toString(), logTag: logTag);
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Multipart POST request for file uploads
  Future<Map<String, dynamic>> postMultipart(
    String url, {
    required Map<String, String> fields,
    required Map<String, File> files,
    bool requireAuth = true,
    String? logTag,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers (but NOT Content-Type - it will be set automatically by multipart)
      request.headers['Accept'] = 'application/json';

      // Add authentication token
      if (requireAuth) {
        final token = await TokenStorageService.instance.getAccessToken();
        if (token != null && token.isNotEmpty) {
          final normalizedToken = _normalizeBearerToken(token);
          request.headers['Authorization'] = 'Bearer $normalizedToken';
          if (kDebugMode) {
            print(
                '🔑 Avatar Upload - Token added: ${normalizedToken.length > 20 ? "${normalizedToken.substring(0, 20)}..." : normalizedToken}');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ Avatar Upload - No token found!');
          }
        }
      }

      // Add fields
      request.fields.addAll(fields);

      // Add files
      for (var entry in files.entries) {
        final file = entry.value;
        final fieldName = entry.key;
        final fileName = file.path.split(Platform.pathSeparator).last;

        if (kDebugMode) {
          print('📎 Adding file: $fieldName = $fileName (${file.path})');
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            file.path,
            filename: fileName,
          ),
        );
      }

      _logRequest(
          'POST (Multipart)',
          url,
          request.headers,
          {
            'fields': fields,
            'files': files.keys.toList(),
          },
          logTag: logTag);

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );

      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('📥 Avatar Upload Response Status: ${response.statusCode}');
        print('📥 Avatar Upload Response Body: ${response.body}');
      }

      final responseData = _handleResponse(response);
      _logResponse(
          'POST (Multipart)', url, response.statusCode, responseData, null,
          logTag: logTag);
      return responseData;
    } catch (e) {
      _logResponse('POST (Multipart)', url, 0, null, e.toString(),
          logTag: logTag);
      if (kDebugMode) {
        print('❌ Avatar Upload Error: $e');
      }
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Handle HTTP response
  /// Automatically handles 401 errors by clearing cached tokens (like Dio interceptor)
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Failed to parse JSON response: ${response.body}');
        }
        throw ApiException('Invalid JSON response: ${e.toString()}');
      }
    } else {
      String errorMessage = 'Request failed with status ${response.statusCode}';
      Map<String, dynamic>? errorData;

      try {
        errorData = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = _coerceApiBodyMessage(errorData['message']) ??
            _coerceApiBodyMessage(errorData['error']) ??
            errorMessage;
      } catch (e) {
        // Not JSON, use raw body
      }

      if (kDebugMode) {
        print('❌ Error Response Body: ${response.body}');
      }

      // Handle 401 Unauthorized - token expired or invalid (like Dio onError interceptor)
      if (response.statusCode == 401) {
        if (kDebugMode) {
          print('🔒 401 Unauthorized - Token may be expired or invalid');
        }

        // Check if it's a real token/auth error (not authorization/validation error)
        bool isAuthError = false;
        if (errorData != null) {
          final message = errorData['message']?.toString().toLowerCase() ?? '';
          // Only treat as auth error when the backend explicitly mentions token/auth problems.
          if (message.contains('token') ||
              message.contains('jwt') ||
              message.contains('unauthenticated') ||
              message.contains('authentication') ||
              message.contains('bearer')) {
            isAuthError = true;
          } else if (kDebugMode) {
            // Common case: 401 used for "not enrolled / not allowed" – keep tokens.
            print(
                '  ℹ️ 401 appears to be authorization/validation error, not token expiry. Tokens will NOT be cleared.');
          }
        }

        if (isAuthError) {
          // Clear cached tokens (like Dio _handleTokenExpiry)
          TokenStorageService.instance.clearTokens().then((_) {
            if (kDebugMode) {
              print(
                  '🗑️ Cleared cached tokens due to 401 authentication error');
            }
          });
        }
      }

      throw ApiException(errorMessage);
    }
  }
}

/// API Exception class
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
