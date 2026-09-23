// lib/presentation/camera/widgets/camera_overlay.dart
import 'package:flutter/material.dart';

class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    const String primaryFont = 'Manrope';

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth * 0.86;
        final boxHeight = constraints.maxHeight * 0.44;

        return Stack(
          children: [
            // Darkened translucent mask with cutout
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.72),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: (constraints.maxWidth - boxWidth) / 2,
                        vertical: (constraints.maxHeight - boxHeight) / 2.4,
                      ),
                      width: boxWidth,
                      height: boxHeight,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4), // Sharp geometry
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sharp illuminated rectangular bounding box with corner crosshairs
            Center(
              child: Transform.translate(
                offset: const Offset(0, -25),
                child: Container(
                  width: boxWidth,
                  height: boxHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF00E599), width: 1.5), // High-contrast phosphor green
                    borderRadius: BorderRadius.circular(4), // Sharp geometry
                  ),
                  child: Stack(
                    children: [
                      // Alignment crosshair
                      Center(
                        child: Icon(
                          Icons.add,
                          color: const Color(0xFF00E599).withOpacity(0.3),
                          size: 28,
                        ),
                      ),

                      // Bounding box instruction header
                      Positioned(
                        top: 8,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101318),
                            borderRadius: BorderRadius.circular(2), // Sharp
                            border: Border.all(color: const Color(0xFF222733)),
                          ),
                          child: const Text(
                            'ALIGN PACKAGED COMMODITY LABEL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: primaryFont,
                              color: Color(0xFF00E599),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Flat anti-glare & distortion warning banner with sharp edges
            Positioned(
              bottom: 125,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF101318),
                  borderRadius: BorderRadius.circular(4), // Sharp 4px
                  border: Border.all(color: const Color(0xFFFFAB00), width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFFFAB00), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AVOID GLARE, CURVATURE & BLUR\nEnsure MRP, Net Qty & Batch are flat & illuminated.',
                        style: TextStyle(
                          fontFamily: primaryFont,
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
