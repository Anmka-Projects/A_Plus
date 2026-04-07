import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

/// Service for countries (used in registration and profile)
class CountriesService {
  CountriesService._();

  static final CountriesService instance = CountriesService._();

  Future<List<Map<String, dynamic>>> getCountries() async {
    final url = ApiEndpoints.adminCountries;
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('📤 COUNTRIES REQUEST');
      print('═══════════════════════════════════════════════════════════');
      print('  Method: GET');
      print('  URL: $url');
      print('  requireAuth: true');
      print('───────────────────────────────────────────────────────────');
    }

    final response = await ApiClient.instance.get(
      url,
      requireAuth: false,
    );

    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('📥 COUNTRIES RESPONSE');
      print('═══════════════════════════════════════════════════════════');
      print('  URL: $url');
      print('  success: ${response['success']}');
      print('  message: ${response['message']}');
      try {
        const encoder = JsonEncoder.withIndent('  ');
        print('📦 Full Response JSON:');
        print(encoder.convert(response));
      } catch (_) {
        print('📦 Raw response: $response');
      }
      print('───────────────────────────────────────────────────────────');
    }

    if (response['success'] == true && response['data'] != null) {
      return List<Map<String, dynamic>>.from(response['data'] as List);
    } else {
      throw Exception(response['message'] ?? 'Failed to fetch countries');
    }
  }
}
