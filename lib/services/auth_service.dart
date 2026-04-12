import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/notification_service/notification_service.dart';
import '../models/auth_response.dart';
import 'device_id_service.dart';
import 'token_storage_service.dart';

/// [ApiClient] already puts the server `message` in [ApiException.message] for non-2xx
/// responses. Use that text for the user; only parse JSON when the message is a raw body.
String _userMessageFromApiException(ApiException e, String fallback) {
  final raw = e.message.trim();
  if (raw.isEmpty) return fallback;
  if (raw.startsWith('{')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final m = decoded['message'] ?? decoded['error'];
        if (m != null) {
          if (m is String && m.isNotEmpty) return m;
          if (m is List && m.isNotEmpty) {
            return m.map((x) => x.toString()).where((s) => s.isNotEmpty).join('\n');
          }
        }
      }
    } catch (_) {}
    return fallback;
  }
  return raw;
}

/// Authentication Service
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// Login with unique learner [code] only.
  Future<AuthResponse> login({
    required String code,
  }) async {
    try {
      final deviceId = await DeviceIdService.getOrCreateDeviceId();
      final Map<String, dynamic> requestBody = {
        'code': code.trim(),
        'device_id': deviceId,
      };

      final response = await ApiClient.instance.post(
        ApiEndpoints.login,
        body: requestBody,
        requireAuth: false, // Login doesn't need auth
      );

      // Print full response for debugging
      if (kDebugMode) {
        print('📦 Full Login Response:');
        print('  Response: $response');
        print('  Response Type: ${response.runtimeType}');
        print('  Response Keys: ${response.keys.toList()}');
        response.forEach((key, value) {
          print('    $key: $value (${value.runtimeType})');
        });
      }

      if (response['success'] == true) {
        // Debug: Print raw response to see structure
        if (kDebugMode) {
          print('🔍 Raw Login Response:');
          print('  response keys: ${response.keys.toList()}');
          if (response['data'] != null) {
            final data = response['data'] as Map<String, dynamic>;
            print('  data keys: ${data.keys.toList()}');
            print('  token in data: ${data.containsKey('token')}');
            final tokenStr = data['token']?.toString() ?? 'NULL';
            final tokenPreview = tokenStr != 'NULL' && tokenStr.length > 20
                ? '${tokenStr.substring(0, 20)}...'
                : tokenStr;
            print('  token value: $tokenPreview');
            print(
                '  refresh_token in data: ${data.containsKey('refresh_token')}');
          }
        }

        final authResponse = AuthResponse.fromJson(response);

        print('🔐 Login successful - Parsing tokens...');
        print(
            '  Token from model: ${authResponse.token.isNotEmpty ? "${authResponse.token.substring(0, authResponse.token.length > 20 ? 20 : authResponse.token.length)}..." : "EMPTY"}');
        print('  Token length: ${authResponse.token.length}');
        print('  Refresh token length: ${authResponse.refreshToken.length}');

        if (authResponse.token.isEmpty) {
          print('❌ ERROR: Token is EMPTY after parsing!');
          print('💡 Check if API response contains token in data.token');
          throw Exception('Token is empty in response');
        }

        // Save tokens to cache (like Dio setTokenIntoHeaderAfterLogin)
        print('💾 Saving tokens to cache...');
        await TokenStorageService.instance.saveTokens(
          accessToken: authResponse.token,
          refreshToken: authResponse.refreshToken,
        );
        await TokenStorageService.instance.saveUserRole(authResponse.user.role);

        // Verify token was saved to cache
        print('🔍 Verifying token was saved to cache...');
        final savedToken = await TokenStorageService.instance.getAccessToken();
        if (savedToken != null && savedToken.isNotEmpty) {
          if (savedToken == authResponse.token) {
            print('✅ Token cached successfully');
            print('  Cached token length: ${savedToken.length}');
            print('  💡 Token is now available for all API requests');
          } else {
            print('❌ Token mismatch in cache!');
            print(
                '  Original: ${authResponse.token.substring(0, authResponse.token.length > 20 ? 20 : authResponse.token.length)}...');
            print(
                '  Cached: ${savedToken.substring(0, savedToken.length > 20 ? 20 : savedToken.length)}...');
          }
        } else {
          print('❌ Token cache verification failed');
          print('  savedToken is null: ${savedToken == null}');
          print('  savedToken is empty: ${savedToken?.isEmpty ?? true}');
          throw Exception('Failed to cache token after login');
        }

        return authResponse;
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is ApiException) {
        throw Exception(_userMessageFromApiException(
          e,
          'فشل تسجيل الدخول. تحقق من بيانات الاعتماد',
        ));
      }
      rethrow;
    }
  }

  /// Register student: quad name, national ID, code, phone, faculty → section → grade, device binding.
  Future<AuthResponse> register({
    required String nameFirst,
    required String nameFather,
    required String nameGrandfather,
    required String nameFamily,
    required String nationalId,
    required String code,
    required String phone,
    required String facultyId,
    required String sectionId,
    required String gradeId,
  }) async {
    try {
      final f = nameFirst.trim();
      final fa = nameFather.trim();
      final g = nameGrandfather.trim();
      final fam = nameFamily.trim();
      final fullName = '$f $fa $g $fam'.trim();

      final body = <String, dynamic>{
        'name': fullName,
        'name_first': f,
        'name_father': fa,
        'name_grandfather': g,
        'name_family': fam,
        'national_id': nationalId.trim(),
        'code': code.trim(),
        'phone': phone.trim(),
        'faculty_id': facultyId,
        'section_id': sectionId,
        'grade_id': gradeId,
        'device_id': await DeviceIdService.getOrCreateDeviceId(),
      };

      final response = await ApiClient.instance.post(
        ApiEndpoints.register,
        body: body,
        requireAuth: false, // Register doesn't need auth
      );

      // Print full response for debugging
      if (kDebugMode) {
        print('📦 Full Register Response:');
        print('  Response: $response');
        print('  Response Type: ${response.runtimeType}');
        print('  Response Keys: ${response.keys.toList()}');
        response.forEach((key, value) {
          print('    $key: $value (${value.runtimeType})');
        });
      }

      if (response['success'] == true) {
        // Debug: Print raw response to see structure
        if (kDebugMode) {
          print('🔍 Raw Register Response:');
          print('  response keys: ${response.keys.toList()}');
          if (response['data'] != null) {
            final data = response['data'] as Map<String, dynamic>;
            print('  data keys: ${data.keys.toList()}');
            print('  token in data: ${data.containsKey('token')}');
            final tokenStr = data['token']?.toString() ?? 'NULL';
            final tokenPreview = tokenStr != 'NULL' && tokenStr.length > 20
                ? '${tokenStr.substring(0, 20)}...'
                : tokenStr;
            print('  token value: $tokenPreview');
            print(
                '  refresh_token in data: ${data.containsKey('refresh_token')}');
          }
        }

        // Check if user status is PENDING (waiting for admin approval)
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final status = data['status'] as String?;

        if (status == 'PENDING') {
          print('⏳ Registration successful but account is PENDING approval');
          print('  Status: $status');
          print(
              '  Message: ${response['message'] ?? 'في انتظار موافقة المدير'}');
          print('  💡 Token will be provided after admin approval');

          // Throw a specific exception for pending status
          throw Exception(response['message']?.toString() ??
              'تم إنشاء الحساب بنجاح، في انتظار موافقة المدير');
        }

        final authResponse = AuthResponse.fromJson(response);

        print('🔐 Registration successful - Parsing tokens...');
        print(
            '  Token from model: ${authResponse.token.isNotEmpty ? "${authResponse.token.substring(0, authResponse.token.length > 20 ? 20 : authResponse.token.length)}..." : "EMPTY"}');
        print('  Token length: ${authResponse.token.length}');
        print('  Refresh token length: ${authResponse.refreshToken.length}');

        if (authResponse.token.isEmpty) {
          print('❌ ERROR: Token is EMPTY after parsing!');
          print('💡 Check if API response contains token in data.token');
          print('💡 This might be a PENDING account - check status field');
          throw Exception(response['message']?.toString() ??
              'تم إنشاء الحساب بنجاح، لكن لا يمكن تسجيل الدخول الآن. يرجى انتظار موافقة المدير');
        }

        // Save tokens to cache (like Dio setTokenIntoHeaderAfterLogin)
        print('💾 Saving tokens to cache...');
        await TokenStorageService.instance.saveTokens(
          accessToken: authResponse.token,
          refreshToken: authResponse.refreshToken,
        );
        await TokenStorageService.instance.saveUserRole(authResponse.user.role);

        // Verify token was saved to cache
        print('🔍 Verifying token was saved to cache...');
        final savedToken = await TokenStorageService.instance.getAccessToken();
        if (savedToken != null && savedToken.isNotEmpty) {
          if (savedToken == authResponse.token) {
            print('✅ Token cached successfully');
            print('  Cached token length: ${savedToken.length}');
            print('  💡 Token is now available for all API requests');
          } else {
            print('❌ Token mismatch in cache!');
            print(
                '  Original: ${authResponse.token.substring(0, authResponse.token.length > 20 ? 20 : authResponse.token.length)}...');
            print(
                '  Cached: ${savedToken.substring(0, savedToken.length > 20 ? 20 : savedToken.length)}...');
          }
        } else {
          print('❌ Token cache verification failed');
          print('  savedToken is null: ${savedToken == null}');
          print('  savedToken is empty: ${savedToken?.isEmpty ?? true}');
          throw Exception('Failed to cache token after registration');
        }

        return authResponse;
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e is ApiException) {
        throw Exception(_userMessageFromApiException(
          e,
          'فشل إنشاء الحساب. يرجى المحاولة مرة أخرى',
        ));
      }
      rethrow;
    }
  }

  /// Refresh access token
  Future<AuthResponse> refreshAccessToken() async {
    try {
      final refreshToken = await TokenStorageService.instance.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('لا يوجد refresh token');
      }

      final response = await ApiClient.instance.post(
        ApiEndpoints.refreshToken,
        body: {
          'refreshToken': refreshToken,
          'device_id': await DeviceIdService.getOrCreateDeviceId(),
        },
        requireAuth: false, // Refresh doesn't need access token
      );

      if (response['success'] == true) {
        final authResponse = AuthResponse.fromJson(response);

        if (authResponse.token.isEmpty) {
          throw Exception('Token is empty in refresh response');
        }

        // Save new tokens to cache
        await TokenStorageService.instance.saveTokens(
          accessToken: authResponse.token,
          refreshToken: authResponse.refreshToken,
        );

        if (kDebugMode) {
          print('✅ Access token refreshed successfully');
          print('  New token length: ${authResponse.token.length}');
        }

        return authResponse;
      } else {
        throw Exception(response['message'] ?? 'فشل تجديد الـ access token');
      }
    } catch (e) {
      if (e is ApiException) {
        throw Exception(_userMessageFromApiException(
          e,
          'فشل تجديد الـ access token. يرجى تسجيل الدخول مرة أخرى',
        ));
      }
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Use requireAuth: true to automatically add token from cache
      await ApiClient.instance.post(
        ApiEndpoints.logout,
        requireAuth: true,
      );
    } catch (e) {
      // Even if API call fails, clear cached tokens
      print('Logout API error: $e');
    } finally {
      // Always clear cached tokens (like _handleTokenExpiry)
      print('🗑️ Clearing cached tokens...');
      await TokenStorageService.instance.clearTokens();
      print('✅ Cached tokens cleared');
    }
  }

  /// Forgot password - Send reset link to email
  Future<void> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.forgotPassword,
        body: {
          'email': email,
        },
        requireAuth: false, // Forgot password doesn't need auth
      );

      if (response['success'] != true) {
        throw Exception(
            response['message'] ?? 'فشل إرسال رابط إعادة تعيين كلمة المرور');
      }
    } catch (e) {
      if (e is ApiException) {
        throw Exception(_userMessageFromApiException(
          e,
          'فشل إرسال رابط إعادة تعيين كلمة المرور. يرجى المحاولة مرة أخرى',
        ));
      }
      rethrow;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await TokenStorageService.instance.isLoggedIn();
  }

  /// Google sign-in with API integration
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Step 1: Get Google credentials
      GoogleSignIn googleSignIn;

      // Try to initialize GoogleSignIn - on Android it requires OAuth client ID
      // If oauth_client is empty in google-services.json, this will fail
      try {
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
      } catch (e) {
        if (kDebugMode) {
          print('❌ GoogleSignIn initialization error: $e');
        }
        throw Exception(
            'خطأ في إعدادات Google Sign-In. يرجى التحقق من إعدادات Firebase Console وإضافة OAuth Client ID');
      }

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('تم إلغاء تسجيل الدخول بواسطة المستخدم');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw Exception('فشل الحصول على بيانات المصادقة من جوجل');
      }

      // Step 2: Get FCM token
      String? fcmToken = FirebaseNotification.fcmToken;
      if (fcmToken == null || fcmToken.isEmpty) {
        // Try to get token if not available
        await FirebaseNotification.getFcmToken();
        fcmToken = FirebaseNotification.fcmToken ?? '';
      }

      // Step 3: Get device info
      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'unknown';

      // Step 4: Build request body
      final requestBody = {
        'provider': 'google',
        'id_token': googleAuth.idToken,
        'access_token': googleAuth.accessToken,
        'fcm_token': fcmToken,
        'device': {
          'platform': platform,
          'model': 'Unknown', // Can be enhanced with device_info_plus package
          'app_version': '1.0.0',
        },
      };

      if (kDebugMode) {
        print('🔐 Google Social Login Request:');
        print('  provider: google');
        print('  id_token: ${googleAuth.idToken?.substring(0, 20)}...');
        print('  access_token: ${googleAuth.accessToken?.substring(0, 20)}...');
        print(
            '  fcm_token: ${fcmToken.isNotEmpty ? "${fcmToken.substring(0, 20)}..." : "EMPTY"}');
        print('  platform: $platform');
      }

      // Step 5: Send request to API
      final response = await ApiClient.instance.post(
        ApiEndpoints.socialLogin,
        body: requestBody,
        requireAuth: false, // Social login doesn't need auth
      );

      if (response['success'] == true) {
        final authResponse = AuthResponse.fromJson(response);

        if (kDebugMode) {
          print('🔐 Google Social Login successful - Saving tokens...');
          print('  Token length: ${authResponse.token.length}');
          print('  Refresh token length: ${authResponse.refreshToken.length}');
        }

        // Save tokens to cache
        await TokenStorageService.instance.saveTokens(
          accessToken: authResponse.token,
          refreshToken: authResponse.refreshToken,
        );
        await TokenStorageService.instance.saveUserRole(authResponse.user.role);

        // Verify token was cached
        final savedToken = await TokenStorageService.instance.getAccessToken();
        if (savedToken != null &&
            savedToken.isNotEmpty &&
            savedToken == authResponse.token) {
          if (kDebugMode) {
            print('✅ Token cached successfully (length: ${savedToken.length})');
          }
        } else {
          if (kDebugMode) {
            print('❌ Token cache verification failed');
          }
          throw Exception('Failed to cache token after Google login');
        }

        return authResponse;
      } else {
        throw Exception(response['message'] ?? 'فشل تسجيل الدخول عبر جوجل');
      }
    } catch (e) {
      // Handle PlatformException specifically for Google Sign-In errors
      if (e.toString().contains('PlatformException') ||
          e.toString().contains('sign_in_failed') ||
          e.toString().contains('ApiException')) {
        if (kDebugMode) {
          print('❌ Google Sign-In PlatformException: $e');
        }

        // Check for common OAuth configuration errors
        if (e.toString().contains('oauth_client') ||
            e.toString().contains('Api10') ||
            e.toString().contains('SIGN_IN_REQUIRED') ||
            e.toString().contains('DEVELOPER_ERROR')) {
          throw Exception('خطأ في إعدادات Google Sign-In:\n'
              'يرجى التأكد من:\n'
              '1. تفعيل Google Sign-In في Firebase Console\n'
              '2. إضافة OAuth Client ID للـ Android app\n'
              '3. تحميل ملف google-services.json المحدث\n'
              '4. التأكد من تطابق package_name مع applicationId');
        }

        // Generic Google Sign-In error
        throw Exception('فشل تسجيل الدخول عبر Google. يرجى التحقق من:\n'
            '- اتصال الإنترنت\n'
            '- إعدادات Google Sign-In في Firebase Console\n'
            '- ملف google-services.json يحتوي على OAuth Client IDs');
      }

      if (e is ApiException) {
        throw Exception(_userMessageFromApiException(
          e,
          'فشل تسجيل الدخول عبر جوجل. يرجى المحاولة مرة أخرى',
        ));
      }

      // Re-throw if it's already a user-friendly Exception
      final errorString = e.toString();
      if (e is Exception &&
          (errorString.contains('خطأ') ||
              errorString.contains('تم إلغاء') ||
              errorString.contains('فشل'))) {
        rethrow;
      }

      // Generic error fallback
      throw Exception('فشل تسجيل الدخول عبر Google: ${e.toString()}');
    }
  }

  /// Apple sign-in with API integration
  Future<AuthResponse> signInWithApple() async {
    try {
      // Step 1: Generate nonce for Apple sign-in
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Step 2: Get Apple credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (appleCredential.identityToken == null) {
        throw Exception('فشل الحصول على بيانات المصادقة من Apple');
      }

      // Step 3: Get FCM token
      String? fcmToken = FirebaseNotification.fcmToken;
      if (fcmToken == null || fcmToken.isEmpty) {
        // Try to get token if not available
        await FirebaseNotification.getFcmToken();
        fcmToken = FirebaseNotification.fcmToken ?? '';
      }

      // Step 4: Get device info
      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'unknown';

      // Step 5: Build request body
      final requestBody = {
        'provider': 'apple',
        'id_token': appleCredential.identityToken,
        'nonce': rawNonce,
        'fcm_token': fcmToken,
        'device': {
          'platform': platform,
          'model': 'Unknown', // Can be enhanced with device_info_plus package
          'app_version': '1.0.0',
        },
      };

      if (kDebugMode) {
        print('🔐 Apple Social Login Request:');
        print('  provider: apple');
        print(
            '  id_token: ${appleCredential.identityToken?.substring(0, 20)}...');
        print('  nonce: ${rawNonce.substring(0, 20)}...');
        print(
            '  fcm_token: ${fcmToken.isNotEmpty ? "${fcmToken.substring(0, 20)}..." : "EMPTY"}');
        print('  platform: $platform');
      }

      // Step 6: Send request to API
      final response = await ApiClient.instance.post(
        ApiEndpoints.socialLogin,
        body: requestBody,
        requireAuth: false, // Social login doesn't need auth
      );

      if (response['success'] == true) {
        final authResponse = AuthResponse.fromJson(response);

        if (kDebugMode) {
          print('🔐 Apple Social Login successful - Saving tokens...');
          print('  Token length: ${authResponse.token.length}');
          print('  Refresh token length: ${authResponse.refreshToken.length}');
        }

        // Save tokens to cache
        await TokenStorageService.instance.saveTokens(
          accessToken: authResponse.token,
          refreshToken: authResponse.refreshToken,
        );
        await TokenStorageService.instance.saveUserRole(authResponse.user.role);

        // Verify token was cached
        final savedToken = await TokenStorageService.instance.getAccessToken();
        if (savedToken != null &&
            savedToken.isNotEmpty &&
            savedToken == authResponse.token) {
          if (kDebugMode) {
            print('✅ Token cached successfully (length: ${savedToken.length})');
          }
        } else {
          if (kDebugMode) {
            print('❌ Token cache verification failed');
          }
          throw Exception('Failed to cache token after Apple login');
        }

        return authResponse;
      } else {
        throw Exception(response['message'] ?? 'فشل تسجيل الدخول عبر Apple');
      }
    } catch (e) {
      if (e is ApiException) {
        throw Exception(_userMessageFromApiException(
          e,
          'فشل تسجيل الدخول عبر Apple. يرجى المحاولة مرة أخرى',
        ));
      }
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
