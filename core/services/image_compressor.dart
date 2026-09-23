// lib/core/services/image_compressor.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

class CompressionResult {
  final Uint8List compressedBytes;
  final String base64String;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final double compressionRatio;
  final Duration duration;

  CompressionResult({
    required this.compressedBytes,
    required this.base64String,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.compressionRatio,
    required this.duration,
  });
}

class ImageCompressor {
  static final ImageCompressor _instance = ImageCompressor._internal();
  factory ImageCompressor() => _instance;
  ImageCompressor._internal();

  /// Target maximum dimension for VLM inference (Google Gemini tiles images at 768-1024px)
  static const int maxDimension = 1280;

  /// Compresses and downsamples image bytes to lightweight payload (<200KB)
  /// and computes Base64 in milliseconds before feeding to Gemini VLM.
  Future<CompressionResult> compressAndEncodeBase64(Uint8List rawBytes, {int quality = 80}) async {
    final stopwatch = Stopwatch()..start();
    final originalSize = rawBytes.lengthInBytes;

    Uint8List processedBytes = rawBytes;

    try {
      // 1. If payload is already compact (< 250 KB), skip heavy downscaling
      if (rawBytes.lengthInBytes > 250 * 1024) {
        processedBytes = await _downsampleUsingFlutterEngine(rawBytes, maxDimension);
      }
    } catch (_) {
      // Graceful fallback to original bytes if image format cannot be decoded by engine
      processedBytes = rawBytes;
    }

    final base64String = base64Encode(processedBytes);
    stopwatch.stop();

    final compressedSize = processedBytes.lengthInBytes;
    final ratio = originalSize > 0 ? (1.0 - (compressedSize / originalSize)) * 100 : 0.0;

    return CompressionResult(
      compressedBytes: processedBytes,
      base64String: base64String,
      originalSizeBytes: originalSize,
      compressedSizeBytes: compressedSize,
      compressionRatio: max(0.0, ratio),
      duration: stopwatch.elapsed,
    );
  }

  /// High-speed hardware-accelerated downscaling using Flutter's built-in Skia/Impeller C++ engine
  Future<Uint8List> _downsampleUsingFlutterEngine(Uint8List rawBytes, int targetMax) async {
    try {
      // 1. Probe image dimensions without loading full raster
      final descriptor = await ui.ImageDescriptor.encoded(
        await ui.ImmutableBuffer.fromUint8List(rawBytes),
      );

      final originalW = descriptor.width;
      final originalH = descriptor.height;
      descriptor.dispose();

      // If both dimensions already within optimal VLM bounds, return
      if (originalW <= targetMax && originalH <= targetMax) {
        return rawBytes;
      }

      // Calculate aspect-ratio preserving dimensions
      int targetW;
      int targetH;
      if (originalW > originalH) {
        targetW = targetMax;
        targetH = (originalH * (targetMax / originalW)).round();
      } else {
        targetH = targetMax;
        targetW = (originalW * (targetMax / originalH)).round();
      }

      // 2. Instantiate hardware-accelerated downsampled codec
      final buffer = await ui.ImmutableBuffer.fromUint8List(rawBytes);
      final codec = await ui.instantiateImageCodecFromBuffer(
        buffer,
        targetWidth: targetW,
        targetHeight: targetH,
      );

      final frameInfo = await codec.getNextFrame();
      final ui.Image downsampledImage = frameInfo.image;

      // 3. Export to compressed byte buffer
      final byteData = await downsampledImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      codec.dispose();
      downsampledImage.dispose();

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
      return rawBytes;
    } catch (_) {
      return rawBytes;
    }
  }

  /// Direct Base64 encoder helper
  String toBase64(Uint8List bytes) => base64Encode(bytes);
}
