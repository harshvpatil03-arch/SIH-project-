// lib/data/local/database_helper.dart
import 'dart:async';
import '../models/inspection_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  // In-memory persistent queue cache for offline operations
  final Map<String, InspectionRecord> _inMemoryStore = {};

  /// Inserts a new inspection record into the offline queue
  Future<void> insertRecord(InspectionRecord record) async {
    _inMemoryStore[record.id] = record;
  }

  /// Retrieves all records pending synchronization (sync_status == 'PENDING')
  Future<List<InspectionRecord>> getPendingRecords() async {
    return _inMemoryStore.values
        .where((r) => r.syncStatus == 'PENDING')
        .toList();
  }

  /// Retrieves all records
  Future<List<InspectionRecord>> getAllRecords() async {
    return _inMemoryStore.values.toList();
  }

  /// Updates a record's evaluation results and sync status to 'SYNCED'
  Future<void> updateRecordSyncStatus(
    String id, {
    required String status,
    required String syncStatus,
    String? summary,
    Map<String, dynamic>? extractedData,
    List<String>? violations,
    String? unreadableReason,
  }) async {
    if (_inMemoryStore.containsKey(id)) {
      final existing = _inMemoryStore[id]!;
      existing.status = status;
      existing.syncStatus = syncStatus;
      if (summary != null) existing.summary = summary;
      if (extractedData != null) existing.extractedData = extractedData;
      if (violations != null) existing.violations = violations;
      if (unreadableReason != null) existing.unreadableReason = unreadableReason;
    }
  }

  /// Deletes a record from SQLite database
  /// (Triggered when Yellow State occurs: refuses to sync garbage data to the Ministry)
  Future<void> deleteRecord(String id) async {
    _inMemoryStore.remove(id);
  }

  /// Clears database records
  Future<void> clearAll() async {
    _inMemoryStore.clear();
  }
}
