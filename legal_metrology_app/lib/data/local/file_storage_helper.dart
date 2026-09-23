// lib/data/local/file_storage_helper.dart
import 'dart:io';
import 'dart:typed_data';

class FileStorageHelper {
  static final FileStorageHelper _instance = FileStorageHelper._internal();
  factory FileStorageHelper() => _instance;
  FileStorageHelper._internal();

  /// Saves compressed image to local disk and returns the absolute file path
  Future<String> saveImageToLocalDisk(Uint8List imageBytes, String filename) async {
    try {
      final directory = Directory('${Directory.systemTemp.path}/legal_metrology_inspections');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      // Fallback relative storage
      final file = File(filename);
      await file.writeAsBytes(imageBytes);
      return file.path;
    }
  }

  /// Reads image bytes from local disk
  Future<Uint8List?> readImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Deletes local image if inspection is discarded/unreadable
  Future<void> deleteImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
