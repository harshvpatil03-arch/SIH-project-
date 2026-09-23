// lib/data/models/inspection_record.dart
import 'dart:convert';

class InspectionRecord {
  final String id;
  final String officerId;
  final String officerName;
  final String imagePath;
  final String? imageBase64;
  final double latitude;
  final double longitude;
  final String locationAccuracy;
  final String timestamp;
  
  /// Inspection status: 'PASS', 'FAIL', 'UNREADABLE', or 'PENDING_EVALUATION'
  String status;
  
  /// Summary description from Legal Metrology evaluation
  String summary;

  /// Reason if status is UNREADABLE (e.g., glare, blur, curvature)
  String? unreadableReason;

  /// Extracted mandatory declarations under Legal Metrology 2011 Rules
  Map<String, dynamic> extractedData;

  /// Specific missing or non-compliant declarations
  List<String> violations;

  /// Sync state: 'PENDING' (in offline queue) or 'SYNCED' (pushed to laptop bridge)
  String syncStatus;

  InspectionRecord({
    required this.id,
    required this.officerId,
    required this.officerName,
    required this.imagePath,
    this.imageBase64,
    required this.latitude,
    required this.longitude,
    required this.locationAccuracy,
    required this.timestamp,
    required this.status,
    this.summary = '',
    this.unreadableReason,
    this.extractedData = const {},
    this.violations = const [],
    this.syncStatus = 'PENDING',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'officer_id': officerId,
      'officer_name': officerName,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy': locationAccuracy,
      'timestamp': timestamp,
      'status': status,
      'summary': summary,
      'unreadable_reason': unreadableReason,
      'extracted_data': jsonEncode(extractedData),
      'violations': jsonEncode(violations),
      'sync_status': syncStatus,
    };
  }

  factory InspectionRecord.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedExtractedData = {};
    if (map['extracted_data'] != null) {
      if (map['extracted_data'] is String) {
        try {
          parsedExtractedData = jsonDecode(map['extracted_data']);
        } catch (_) {}
      } else if (map['extracted_data'] is Map) {
        parsedExtractedData = Map<String, dynamic>.from(map['extracted_data']);
      }
    }

    List<String> parsedViolations = [];
    if (map['violations'] != null) {
      if (map['violations'] is String) {
        try {
          final decoded = jsonDecode(map['violations']);
          if (decoded is List) {
            parsedViolations = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      } else if (map['violations'] is List) {
        parsedViolations = List<String>.from(map['violations']);
      }
    }

    return InspectionRecord(
      id: map['id'] ?? '',
      officerId: map['officer_id'] ?? 'LMO-884920',
      officerName: map['officer_name'] ?? 'Officer R. Sharma',
      imagePath: map['image_path'] ?? '',
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : 0.0,
      locationAccuracy: map['location_accuracy'] ?? 'SATELLITE_HIGH_ACCURACY',
      timestamp: map['timestamp'] ?? '',
      status: map['status'] ?? 'PENDING',
      summary: map['summary'] ?? '',
      unreadableReason: map['unreadable_reason'],
      extractedData: parsedExtractedData,
      violations: parsedViolations,
      syncStatus: map['sync_status'] ?? 'PENDING',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'officer_id': officerId,
      'officer_name': officerName,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy': locationAccuracy,
      'timestamp': timestamp,
      'status': status,
      'summary': summary,
      'unreadable_reason': unreadableReason,
      'extracted_data': extractedData,
      'violations': violations,
      'sync_status': syncStatus,
    };
  }

  factory InspectionRecord.fromJson(Map<String, dynamic> json) => InspectionRecord.fromMap(json);
}
