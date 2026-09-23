// lib/services/local_sync_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../data/models/inspection_record.dart';

class LocalSyncService {
  static final LocalSyncService _instance = LocalSyncService._internal();
  factory LocalSyncService() => _instance;
  LocalSyncService._internal();

  /// Posts JSON inspection record payload to the local laptop bridge server
  Future<bool> syncRecordToLocalServer(InspectionRecord record) async {
    final endpoint = Uri.parse(ApiConstants.localServerUrl);

    try {
      final payload = record.toJson();
      final response = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      return false;
    } catch (_) {
      // Laptop server unreachable or network partitioned
      return false;
    }
  }
}
