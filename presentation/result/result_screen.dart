// lib/presentation/result/result_screen.dart
import 'package:flutter/material.dart';
import '../../data/models/inspection_record.dart';
import 'widgets/field_breakdown.dart';

class ResultScreen extends StatelessWidget {
  final InspectionRecord record;

  const ResultScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    const String primaryFont = 'Manrope';
    final status = record.status.toUpperCase();
    final isPass = status == 'PASS';
    final isFail = status == 'FAIL';
    final isUnreadable = status == 'UNREADABLE';

    // Flat high-contrast primary tones
    Color primaryColor;
    Color flatCardBg;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    if (isPass) {
      primaryColor = const Color(0xFF00C853); // Signal Green
      flatCardBg = const Color(0xFF092314);
      statusIcon = Icons.check_circle_outline;
      statusTitle = 'LEGAL METROLOGY COMPLIANT';
      statusSubtitle = 'All mandatory 2011 declarations verified & present.';
    } else if (isFail) {
      primaryColor = const Color(0xFFD50000); // Signal Red
      flatCardBg = const Color(0xFF280808);
      statusIcon = Icons.gavel_rounded;
      statusTitle = 'LEGAL METROLOGY VIOLATION';
      statusSubtitle = 'Packaging fails mandatory declarations under 2011 Rules.';
    } else {
      // Yellow State
      primaryColor = const Color(0xFFFFAB00); // Industrial Amber
      flatCardBg = const Color(0xFF261A00);
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = 'UNREADABLE / RETAKE PHOTO';
      statusSubtitle = 'Label obscured by glare or blur. Retake photo.';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF08090C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101318),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF222733), width: 1),
        ),
        title: Text(
          isPass
              ? 'STATE: GREEN (COMPLIANT)'
              : isFail
                  ? 'STATE: RED (VIOLATION)'
                  : 'STATE: YELLOW (UNREADABLE)',
          style: TextStyle(
            fontFamily: primaryFont,
            color: primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Flat Hero Status Banner (Sharp 4px geometry, high-contrast, no fuzzy gradient)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: flatCardBg,
                borderRadius: BorderRadius.circular(4), // Sharp geometry
                border: Border.all(color: primaryColor, width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(statusIcon, size: 54, color: primaryColor),
                  const SizedBox(height: 10),
                  Text(
                    statusTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: primaryFont,
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: primaryFont,
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dispatch badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101318),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: const Color(0xFF222733)),
                    ),
                    child: Text(
                      isUnreadable
                          ? 'REJECTED • RECORD DELETED FROM SQLITE'
                          : (record.syncStatus == 'SYNCED')
                              ? 'SILENTLY SYNCED TO LOCAL BRIDGE'
                              : 'QUEUED FOR TRANSMISSION',
                      style: TextStyle(
                        fontFamily: primaryFont,
                        color: isUnreadable ? const Color(0xFFFFAB00) : const Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (isUnreadable) ...[
              // Yellow State Action Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF101318),
                  borderRadius: BorderRadius.circular(4), // Sharp geometry
                  border: Border.all(color: const Color(0xFFFFAB00)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFFFAB00), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'OPTICAL QUALITY FAILURE',
                          style: TextStyle(
                            fontFamily: primaryFont,
                            color: Color(0xFFFFAB00),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.unreadableReason ??
                          'Label obscured by glare or blur. Retake photo.',
                      style: const TextStyle(
                        fontFamily: primaryFont,
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const Divider(color: Color(0xFF222733), height: 20),
                    const Text(
                      'Action Required: Align label flat inside the bounding box and retake.',
                      style: TextStyle(fontFamily: primaryFont, color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFAB00),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Sharp geometry
                ),
                icon: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                label: const Text(
                  'RETAKE PHOTO NOW',
                  style: TextStyle(fontFamily: primaryFont, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ] else ...[
              // Green or Red State: Field breakdown
              FieldBreakdown(
                extractedData: record.extractedData,
                violations: record.violations,
                isPass: isPass,
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPass ? const Color(0xFF00C853) : const Color(0xFFD50000),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Sharp geometry
                ),
                icon: const Icon(Icons.check, size: 20),
                label: Text(
                  isPass ? 'COMPLETE INSPECTION' : 'LOG VIOLATION NOTICE',
                  style: const TextStyle(
                    fontFamily: primaryFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
