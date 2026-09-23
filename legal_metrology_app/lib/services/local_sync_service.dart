// lib/services/local_sync_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../data/models/inspection_record.dart';

class LocalSyncService {
  static final LocalSyncService _instance = LocalSyncService._internal();
  factory LocalSyncService() => _instance;
  LocalSyncService._internal();

  /// Posts JSON inspection record payload to the local laptop bridge server.
  /// Automatically tries:
  /// 1. Configured LAN IP (for physical phone over Wi-Fi)
  /// 2. 10.0.2.2:8080 (for Android Emulator host loopback)
  /// 3. 127.0.0.1:8080 (for Windows Desktop / Flutter Web testing)
  Future<bool> syncRecordToLocalServer(InspectionRecord record) async {
    final endpointsToTry = [
      ApiConstants.localServerUrl,
      'http://10.0.2.2:${ApiConstants.localServerPort}/api/inspection',
      'http://127.0.0.1:${ApiConstants.localServerPort}/api/inspection',
    ];

    final payload = record.toJson();

    for (final endpointStr in endpointsToTry) {
      try {
        final endpoint = Uri.parse(endpointStr);
        final response = await http.post(
          endpoint,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        ).timeout(const Duration(milliseconds: 2500));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return true;
        }
      } catch (_) {
        // Continue to fallback endpoint
      }
    }
    return false;
  }
}
