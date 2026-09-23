// lib/presentation/result/widgets/field_breakdown.dart
import 'package:flutter/material.dart';

class FieldBreakdown extends StatelessWidget {
  final Map<String, dynamic> extractedData;
  final List<String> missingFields;
  final bool isPass;

  const FieldBreakdown({
    super.key,
    required this.extractedData,
    required this.missingFields,
    required this.isPass,
  });

  Widget _buildFieldRow(String label, dynamic value, IconData icon, {bool isVegDot = false}) {
    const String primaryFont = 'Manrope';
    final displayVal = (value != null && value.toString().trim().isNotEmpty)
        ? value.toString()
        : 'NOT FOUND / MISSING';
    final isPresent = value != null && value.toString().trim().isNotEmpty && displayVal != 'NOT FOUND / MISSING';

    Color? dotColor;
    if (isVegDot && isPresent) {
      final lower = displayVal.toLowerCase();
      if (lower.contains('green') || lower.contains('veg')) {
        dotColor = const Color(0xFF00C853);
      } else if (lower.contains('red') || lower.contains('brown') || lower.contains('non')) {
        dotColor = const Color(0xFFD50000);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101318),
        borderRadius: BorderRadius.circular(4), // Sharp 4px geometry
        border: Border.all(
          color: isPresent ? const Color(0xFF222733) : const Color(0xFFD50000).withOpacity(0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: isPresent
                ? (isPass ? const Color(0xFF00C853) : const Color(0xFF0080FF))
                : const Color(0xFFD50000),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: primaryFont,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (isVegDot && dotColor != null) ...[
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        displayVal,
                        style: TextStyle(
                          fontFamily: primaryFont,
                          fontSize: 12,
                          color: isPresent ? Colors.white : const Color(0xFFFF5252),
                          fontWeight: isPresent ? FontWeight.w600 : FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            isPresent ? Icons.check_circle_outline : Icons.highlight_off,
            color: isPresent ? const Color(0xFF00C853) : const Color(0xFFD50000),
            size: 16,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String primaryFont = 'Manrope';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Missing Fields / Violations Section
        if (missingFields.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF280808),
              borderRadius: BorderRadius.circular(4), // Sharp 4px geometry
              border: Border.all(color: const Color(0xFFD50000)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.report_problem, color: Color(0xFFD50000), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'RULE 6 MANDATORY MISSING DECLARATIONS:',
                      style: TextStyle(
                        fontFamily: primaryFont,
                        color: Color(0xFFFF5252),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...missingFields.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontFamily: primaryFont,
                            color: Color(0xFFD50000),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            f,
                            style: const TextStyle(
                              fontFamily: primaryFont,
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Extracted Mandatory 7 Declarations
        const Text(
          'RULE 6 MANDATORY DECLARATION FIELDS',
          style: TextStyle(
            fontFamily: primaryFont,
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        _buildFieldRow(
          '1. Common / Generic Name',
          extractedData['generic_name'] ?? extractedData['commodity_name'],
          Icons.category_outlined,
        ),
        _buildFieldRow(
          '2. Maximum Retail Price (MRP)',
          extractedData['mrp'] ?? extractedData['mrp_inclusive_taxes'],
          Icons.currency_rupee,
        ),
        _buildFieldRow(
          '3. Net Quantity',
          extractedData['net_quantity'],
          Icons.scale_outlined,
        ),
        _buildFieldRow(
          '4. Mfg / Packing / Import Date',
          extractedData['mfg_pack_date'] ?? extractedData['mfg_packing_date'],
          Icons.calendar_today_outlined,
        ),
        _buildFieldRow(
          '5. Manufacturer / Packer Address',
          extractedData['manufacturer_address'] ?? extractedData['manufacturer_name_and_address'],
          Icons.business_outlined,
        ),
        _buildFieldRow(
          '6. Consumer Care Details',
          extractedData['consumer_care'] ?? extractedData['consumer_care_details'],
          Icons.support_agent,
        ),
        _buildFieldRow(
          '7. Veg / Non-Veg Indicator',
          extractedData['veg_nonveg_dot'],
          Icons.adjust,
          isVegDot: true,
        ),
      ],
    );
  }
}
