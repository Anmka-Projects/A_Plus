import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stable device fingerprint for single-device login (see backend spec).
class DeviceIdService {
  DeviceIdService._();

  static const _prefsKey = 'app_device_fingerprint_v1';

  /// Returns a stable string per app install / device, sent on login & register.
  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    String raw;
    final plugin = DeviceInfoPlugin();
    if (kIsWeb) {
      raw = 'web_${DateTime.now().millisecondsSinceEpoch}';
    } else if (Platform.isAndroid) {
      final a = await plugin.androidInfo;
      raw = 'android_${a.id}';
    } else if (Platform.isIOS) {
      final i = await plugin.iosInfo;
      raw = 'ios_${i.identifierForVendor ?? 'unknown'}';
    } else {
      raw = 'other_${DateTime.now().millisecondsSinceEpoch}';
    }

    await prefs.setString(_prefsKey, raw);
    return raw;
  }
}
