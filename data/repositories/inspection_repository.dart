// lib/data/repositories/inspection_repository.dart
import 'dart:convert';
import 'dart:typed_data';
import '../models/inspection_record.dart';
import '../local/database_helper.dart';
import '../local/file_storage_helper.dart';
import '../../services/gemini_service.dart';
import '../../services/local_sync_service.dart';

class SyncBatchResult {
  final int totalProcessed;
  final int syncedSuccessfully;
  final int failed;
  final int unreadableDiscarded;

  SyncBatchResult({
    required this.totalProcessed,
    required this.syncedSuccessfully,
    required this.failed,
    required this.unreadableDiscarded,
  });
}

class InspectionRepository {
  static final InspectionRepository _instance = InspectionRepository._internal();
  factory InspectionRepository() => _instance;
  InspectionRepository._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final FileStorageHelper _storage = FileStorageHelper();
  final GeminiService _geminiService = GeminiService();
  final LocalSyncService _syncService = LocalSyncService();

  /// Queue an inspection record offline (Path B)
  Future<InspectionRecord> queueOfflineInspection({
    required String officerId,
    required String officerName,
    required Uint8List compressedBytes,
    required double latitude,
    required double longitude,
    required String locationAccuracy,
  }) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final id = 'INSP-${DateTime.now().millisecondsSinceEpoch}';
    final filename = '$id.jpg';

    // 1. Save image to local disk
    final localPath = await _storage.saveImageToLocalDisk(compressedBytes, filename);

    // 2. Create row in local SQLite database with sync_status = 'PENDING'
    final record = InspectionRecord(
      id: id,
      officerId: officerId,
      officerName: officerName,
      imagePath: localPath,
      latitude: latitude,
      longitude: longitude,
      locationAccuracy: locationAccuracy,
      timestamp: timestamp,
      status: 'PENDING_EVALUATION',
      summary: 'Saved to local queue. Awaiting network sync.',
      syncStatus: 'PENDING',
    );

    await _db.insertRecord(record);
    return record;
  }

  /// Process an inspection online immediately (Path A)
  Future<InspectionRecord> processOnlineInspection({
    required String officerId,
    required String officerName,
    required Uint8List compressedBytes,
    required String base64Image,
    required double latitude,
    required double longitude,
    required String locationAccuracy,
    String demoPreset = 'PASS_COMPLIANT',
  }) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final id = 'INSP-${DateTime.now().millisecondsSinceEpoch}';
    final filename = '$id.jpg';

    final localPath = await _storage.saveImageToLocalDisk(compressedBytes, filename);

    // Call Gemini Multimodal VLM
    final analysis = await _geminiService.analyzeLabel(base64Image, demoPreset: demoPreset);

    final record = InspectionRecord(
      id: id,
      officerId: officerId,
      officerName: officerName,
      imagePath: localPath,
      latitude: latitude,
      longitude: longitude,
      locationAccuracy: locationAccuracy,
      timestamp: timestamp,
      status: analysis.status,
      summary: analysis.reason,
      unreadableReason: analysis.reason,
      extractedData: analysis.extractedData,
      violations: analysis.missingFields,
      syncStatus: 'PENDING',
      vlmProvider: analysis.vlmProvider,
    );

    // Behavioral state handling:
    if (analysis.status == 'UNREADABLE') {
      // STATE: YELLOW - Discard immediately, do not sync garbage
      await _storage.deleteImage(localPath);
      return record;
    }

    // STATE: GREEN or RED - Push to laptop local server bridge
    final syncSuccess = await _syncService.syncRecordToLocalServer(record);
    if (syncSuccess) {
      record.syncStatus = 'SYNCED';
    }
    await _db.insertRecord(record);

    return record;
  }

  /// Batch sync all pending records from SQLite queue (Deferred Resolution)
  Future<SyncBatchResult> syncAllPendingRecords() async {
    final pending = await _db.getPendingRecords();
    int synced = 0;
    int failed = 0;
    int unreadable = 0;

    for (final record in pending) {
      try {
        final imageBytes = await _storage.readImage(record.imagePath);
        if (imageBytes == null) {
          failed++;
          continue;
        }

        final base64String = base64Encode(imageBytes);
        final analysis = await _geminiService.analyzeLabel(base64String);

        if (analysis.status == 'UNREADABLE') {
          // Yellow state: delete pending record from SQLite database
          await _db.deleteRecord(record.id);
          await _storage.deleteImage(record.imagePath);
          unreadable++;
        } else {
          // Pass or Fail state: update evaluation and push to laptop server
          record.status = analysis.status;
          record.summary = analysis.reason;
          record.extractedData = analysis.extractedData;
          record.violations = analysis.missingFields;

          final pushed = await _syncService.syncRecordToLocalServer(record);
          if (pushed) {
            record.syncStatus = 'SYNCED';
            synced++;
          } else {
            record.syncStatus = 'PENDING';
            failed++;
          }
          await _db.updateRecordSyncStatus(
            record.id,
            status: record.status,
            syncStatus: record.syncStatus,
            summary: record.summary,
            extractedData: record.extractedData,
            violations: record.violations,
          );
        }
      } catch (_) {
        failed++;
      }
    }

    return SyncBatchResult(
      totalProcessed: pending.length,
      syncedSuccessfully: synced,
      failed: failed,
      unreadableDiscarded: unreadable,
    );
  }

  Future<List<InspectionRecord>> getPendingRecords() => _db.getPendingRecords();
  Future<List<InspectionRecord>> getAllRecords() => _db.getAllRecords();
}
