// lib/presentation/result/widgets/field_breakdown.dart
import 'package:flutter/material.dart';

class FieldBreakdown extends StatelessWidget {
  final Map<String, dynamic> extractedData;
  final List<String> violations;
  final bool isPass;

  const FieldBreakdown({
    super.key,
    required this.extractedData,
    required this.violations,
    required this.isPass,
  });

  Widget _buildFieldRow(String label, dynamic value, IconData icon) {
    const String primaryFont = 'Manrope';
    final displayVal = (value != null && value.toString().trim().isNotEmpty)
        ? value.toString()
        : 'NOT FOUND / MISSING';
    final isPresent = value != null && value.toString().trim().isNotEmpty && displayVal != 'NOT FOUND / MISSING';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101318),
        borderRadius: BorderRadius.circular(4), // Sharp geometry
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
                Text(
                  displayVal,
                  style: TextStyle(
                    fontFamily: primaryFont,
                    fontSize: 12,
                    color: isPresent ? Colors.white : const Color(0xFFFF5252),
                    fontWeight: isPresent ? FontWeight.w600 : FontWeight.w800,
                  ),
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
        // Violations Section if any exist
        if (violations.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF280808),
              borderRadius: BorderRadius.circular(4), // Sharp 4px
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
                      'LEGAL METROLOGY 2011 BREACHES:',
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
                ...violations.map(
                  (v) => Padding(
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
                            v,
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

        // Extracted Mandatory Declarations Header
        const Text(
          'MANDATORY 2011 DECLARATION FIELDS',
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
          'Commodity Generic Name',
          extractedData['commodity_name'],
          Icons.category_outlined,
        ),
        _buildFieldRow(
          'Maximum Retail Price (MRP)',
          extractedData['mrp_inclusive_taxes'],
          Icons.currency_rupee,
        ),
        _buildFieldRow(
          'Net Quantity',
          extractedData['net_quantity'],
          Icons.scale_outlined,
        ),
        _buildFieldRow(
          'Mfg / Packing / Import Date',
          extractedData['mfg_packing_date'],
          Icons.calendar_today_outlined,
        ),
        _buildFieldRow(
          'Manufacturer Name & Address',
          extractedData['manufacturer_name_and_address'],
          Icons.business_outlined,
        ),
        _buildFieldRow(
          'Country of Origin',
          extractedData['country_of_origin'],
          Icons.public,
        ),
        _buildFieldRow(
          'Consumer Care Details',
          extractedData['consumer_care_details'],
          Icons.support_agent,
        ),
      ],
    );
  }
}
