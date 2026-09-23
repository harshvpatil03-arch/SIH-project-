// lib/presentation/camera/camera_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/network_info.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/image_compressor.dart';
import '../../data/repositories/inspection_repository.dart';
import '../result/result_screen.dart';
import 'widgets/camera_overlay.dart';

class CameraScreen extends StatefulWidget {
  final String officerId;
  final String officerName;
  final GpsResult gpsResult;

  const CameraScreen({
    super.key,
    required this.officerId,
    required this.officerName,
    required this.gpsResult,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final NetworkInfo _networkInfo = NetworkInfo();
  final ImageCompressor _compressor = ImageCompressor();
  final InspectionRepository _repository = InspectionRepository();
  final ImagePicker _imagePicker = ImagePicker();

  // Camera Controller State
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  bool _isCameraInitialized = false;
  bool _isInitializingCamera = true;
  String? _cameraErrorMessage;
  int _selectedCameraIndex = 0;

  bool _isProcessing = false;
  String _processingMessage = '';

  // Preset demo test samples for pitch and live demonstration
  String _selectedDemoPreset = 'PASS_COMPLIANT';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(controller.description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializingCamera = true;
      _cameraErrorMessage = null;
    });

    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        // Prefer rear/back camera for packaged commodity label inspection
        int cameraIndex = _availableCameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        if (cameraIndex == -1) cameraIndex = 0;
        _selectedCameraIndex = cameraIndex;

        await _startCamera(_availableCameras[cameraIndex]);
      } else {
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = false;
          _isInitializingCamera = false;
          _cameraErrorMessage = 'No physical camera hardware detected on device.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = false;
        _isInitializingCamera = false;
        _cameraErrorMessage = 'Camera hardware access error: $e';
      });
    }
  }

  Future<void> _startCamera(CameraDescription description) async {
    final previousController = _cameraController;
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await previousController?.dispose();

    if (!mounted) return;
    _cameraController = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _isInitializingCamera = false;
        _cameraErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = false;
        _isInitializingCamera = false;
        _cameraErrorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) return;
    final nextIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    _selectedCameraIndex = nextIndex;
    await _startCamera(_availableCameras[nextIndex]);
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        await _handleCapture(directBytes: bytes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF101318),
          content: Text('Gallery pick error: $e', style: const TextStyle(fontFamily: 'Manrope')),
        ),
      );
    }
  }

  Uint8List _generateSimulatedLabelBytes(String mode) {
    final sampleString = 'LEGAL_METROLOGY_LABEL_BUFFER_MODE_$mode';
    return Uint8List.fromList(utf8.encode(sampleString));
  }

  Future<void> _handleCapture({Uint8List? directBytes}) async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Capturing commodity package image...';
    });

    Uint8List? rawBytes = directBytes;

    // 1. If direct bytes not supplied, attempt hardware camera snap
    if (rawBytes == null) {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        try {
          final xFile = await _cameraController!.takePicture();
          rawBytes = await xFile.readAsBytes();
        } catch (e) {
          print('[CAMERA] Hardware capture exception: $e');
        }
      }
    }

    // 2. Fallback to demo simulated label buffer if no hardware photo captured
    if (rawBytes == null || rawBytes.isEmpty) {
      rawBytes = _generateSimulatedLabelBytes(_selectedDemoPreset);
    }

    setState(() {
      _processingMessage = 'Compressing image to lightweight JPEG...';
    });

    final compressionResult = await _compressor.compressAndEncodeBase64(rawBytes);
    final isOnline = await _networkInfo.isConnected();

    if (!mounted) return;

    if (isOnline) {
      // PATH A: ONLINE - INSTANT
      setState(() {
        _processingMessage = 'Online (Path A): Sending Base64 to Gemini VLM...';
      });

      final record = await _repository.processOnlineInspection(
        officerId: widget.officerId,
        officerName: widget.officerName,
        compressedBytes: compressionResult.compressedBytes,
        base64Image: compressionResult.base64String,
        latitude: widget.gpsResult.latitude,
        longitude: widget.gpsResult.longitude,
        locationAccuracy: widget.gpsResult.accuracyMode,
        demoPreset: _selectedDemoPreset,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(record: record),
        ),
      );
    } else {
      // PATH B: OFFLINE - QUEUED
      setState(() {
        _processingMessage = 'Offline (Path B): Saving to local SQLite queue...';
      });

      final record = await _repository.queueOfflineInspection(
        officerId: widget.officerId,
        officerName: widget.officerName,
        compressedBytes: compressionResult.compressedBytes,
        latitude: widget.gpsResult.latitude,
        longitude: widget.gpsResult.longitude,
        locationAccuracy: widget.gpsResult.accuracyMode,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF101318),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFFFFAB00)),
          ),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.offline_pin_rounded, color: Color(0xFFFFAB00), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Record ${record.id} queued in SQLite!\nsync_status = PENDING (offline)',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const String primaryFont = 'Manrope';

    return Scaffold(
      backgroundColor: const Color(0xFF08090C),
      body: Stack(
        children: [
          // 1. LIVE CAMERA STREAM OR VIEWPORT PLACEHOLDER
          Positioned.fill(
            child: _buildCameraViewport(primaryFont),
          ),

          // 2. Translucent Overlay & Bounding Box with Glare Warning
          const CameraOverlay(),

          // 3. Top Header Bar
          Positioned(
            top: 42,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF101318),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: Color(0xFF222733)),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101318),
                    borderRadius: BorderRadius.circular(4), // Sharp geometry
                    border: Border.all(
                      color: (widget.gpsResult.accuracyMode == 'NETWORK_COARSE_FALLBACK')
                          ? const Color(0xFFFFAB00)
                          : const Color(0xFF222733),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (widget.gpsResult.accuracyMode == 'NETWORK_COARSE_FALLBACK')
                            ? Icons.warning_amber_rounded
                            : Icons.gps_fixed,
                        color: (widget.gpsResult.accuracyMode == 'NETWORK_COARSE_FALLBACK')
                            ? const Color(0xFFFFAB00)
                            : const Color(0xFF00E599),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (widget.gpsResult.accuracyMode == 'NETWORK_COARSE_FALLBACK')
                            ? '${widget.gpsResult.latitude.toStringAsFixed(4)}, ${widget.gpsResult.longitude.toStringAsFixed(4)} (Coarse)'
                            : '${widget.gpsResult.latitude.toStringAsFixed(4)}, ${widget.gpsResult.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontFamily: primaryFont,
                          color: (widget.gpsResult.accuracyMode == 'NETWORK_COARSE_FALLBACK')
                              ? const Color(0xFFFFAB00)
                              : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Coarse GPS Fallback Warning Banner
          if (widget.gpsResult.accuracyMode == 'NETWORK_COARSE_FALLBACK')
            Positioned(
              top: 92,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF261D00),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFFAB00)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFFFAB00), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.gpsResult.warningMessage ??
                            'GPS satellite lock timed out. Applied approximate jurisdiction coarse fallback.',
                        style: const TextStyle(
                          fontFamily: primaryFont,
                          color: Color(0xFFFFAB00),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Pitch / Demo Mode Preset Selector
          Positioned(
            bottom: 185,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF101318),
                borderRadius: BorderRadius.circular(4), // Sharp 4px
                border: Border.all(color: const Color(0xFF222733)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: Color(0xFF0080FF), size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Demo Label Mode:',
                    style: TextStyle(
                      fontFamily: primaryFont,
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _selectedDemoPreset,
                    dropdownColor: const Color(0xFF101318),
                    underline: const SizedBox(),
                    style: const TextStyle(
                      fontFamily: primaryFont,
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PASS_COMPLIANT', child: Text('Green (Compliant)')),
                      DropdownMenuItem(value: 'FAIL_VIOLATION', child: Text('Red (Violation)')),
                      DropdownMenuItem(value: 'UNREADABLE_GLARE', child: Text('Yellow (Glare/Blur)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDemoPreset = val);
                    },
                  ),
                ],
              ),
            ),
          ),

          // 6. Bottom Controls: Gallery + Middle Down Shutter + Camera Switch
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Button 1: Gallery Upload
                GestureDetector(
                  onTap: _isProcessing ? null : _pickFromGallery,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF101318),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF222733)),
                        ),
                        child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'GALLERY',
                        style: TextStyle(
                          fontFamily: primaryFont,
                          color: Colors.white60,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Button 2: PhonePe-Style Middle Down Shutter Button
                GestureDetector(
                  onTap: _isProcessing ? null : () => _handleCapture(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0080FF),
                          borderRadius: BorderRadius.circular(6), // Sharp modern geometry
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0080FF).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'SNAP COMMODITY',
                        style: TextStyle(
                          fontFamily: primaryFont,
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Button 3: Switch Camera (Front/Rear)
                GestureDetector(
                  onTap: (_isProcessing || _availableCameras.length < 2) ? null : _switchCamera,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF101318),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF222733)),
                        ),
                        child: Icon(
                          Icons.flip_camera_ios_outlined,
                          color: _availableCameras.length > 1 ? Colors.white : Colors.white24,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'FLIP',
                        style: TextStyle(
                          fontFamily: primaryFont,
                          color: Colors.white60,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 7. Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF0080FF)),
                    const SizedBox(height: 18),
                    Text(
                      _processingMessage,
                      style: const TextStyle(
                        fontFamily: primaryFont,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraViewport(String primaryFont) {
    if (_isCameraInitialized && _cameraController != null) {
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 1080,
              height: _cameraController!.value.previewSize?.width ?? 1920,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      );
    }

    if (_isInitializingCamera) {
      return Container(
        color: const Color(0xFF0E1117),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(color: Color(0xFF0080FF), strokeWidth: 2),
              ),
              const SizedBox(height: 16),
              Text(
                'INITIALIZING CAMERA SENSOR...',
                style: TextStyle(
                  fontFamily: primaryFont,
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback: If hardware camera is blocked or not detected
    return Container(
      color: const Color(0xFF0E1117),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_outlined, color: Colors.white.withOpacity(0.2), size: 80),
            const SizedBox(height: 12),
            Text(
              'LIVE CAMERA PREVIEW STANDBY',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: primaryFont,
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _cameraErrorMessage ?? 'Live camera unavailable. You can snap or pick from Gallery.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: primaryFont,
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _initializeCamera,
                  icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF0080FF)),
                  label: const Text('Retry Camera', style: TextStyle(fontFamily: 'Manrope', fontSize: 11, color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0080FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library, size: 14, color: Colors.white),
                  label: const Text('Upload Photo', style: TextStyle(fontFamily: 'Manrope', fontSize: 11, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0080FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
