// lib/services/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/constants/prompt_templates.dart';

class GeminiAnalysisResult {
  final String status; // 'PASS', 'FAIL', or 'UNREADABLE'
  final String summary;
  final String? unreadableReason;
  final Map<String, dynamic> extractedData;
  final List<String> violations;
  final String rawResponse;

  GeminiAnalysisResult({
    required this.status,
    required this.summary,
    this.unreadableReason,
    required this.extractedData,
    required this.violations,
    required this.rawResponse,
  });

  factory GeminiAnalysisResult.fromMap(Map<String, dynamic> map, String raw) {
    final statusStr = (map['status'] ?? 'FAIL').toString().toUpperCase();
    String normalizedStatus;
    if (statusStr.contains('PASS')) {
      normalizedStatus = 'PASS';
    } else if (statusStr.contains('UNREADABLE')) {
      normalizedStatus = 'UNREADABLE';
    } else {
      normalizedStatus = 'FAIL';
    }

    Map<String, dynamic> extracted = {};
    if (map['extracted_data'] is Map) {
      extracted = Map<String, dynamic>.from(map['extracted_data']);
    }

    List<String> violationsList = [];
    if (map['violations'] is List) {
      violationsList = (map['violations'] as List).map((e) => e.toString()).toList();
    }

    return GeminiAnalysisResult(
      status: normalizedStatus,
      summary: map['summary'] ?? '',
      unreadableReason: map['unreadable_reason'],
      extractedData: extracted,
      violations: violationsList,
      rawResponse: raw,
    );
  }
}

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  /// Executes Multimodal VLM inference on the Base64-encoded image
  Future<GeminiAnalysisResult> analyzeLabel(String base64Image, {String? customApiKey}) async {
    final apiKey = (customApiKey != null && customApiKey.isNotEmpty)
        ? customApiKey
        : ApiConstants.geminiApiKey;

    // If API key is not yet set, provide helpful prompt or demo simulation
    if (apiKey.isEmpty) {
      return _generateFallbackResult(base64Image);
    }

    final url = Uri.parse(ApiConstants.geminiUrl(apiKey));
    final payload = {
      'contents': [
        {
          'parts': [
            {
              'text': PromptTemplates.legalMetrology2011SystemPrompt,
            },
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'temperature': 0.1,
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final candidates = decoded['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          final text = parts[0]['text'] as String;

          // Clean markdown wrappers if any
          final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
          final parsedJson = jsonDecode(cleaned) as Map<String, dynamic>;
          return GeminiAnalysisResult.fromMap(parsedJson, text);
        }
      }
      
      return GeminiAnalysisResult(
        status: 'UNREADABLE',
        summary: 'Gemini API Error: Status ${response.statusCode}',
        unreadableReason: 'API request failed: ${response.body}',
        extractedData: {},
        violations: ['API Communication error'],
        rawResponse: response.body,
      );
    } catch (e) {
      return GeminiAnalysisResult(
        status: 'UNREADABLE',
        summary: 'Error contacting Gemini VLM: $e',
        unreadableReason: 'Network error or timeout while calling Gemini API',
        extractedData: {},
        violations: [e.toString()],
        rawResponse: e.toString(),
      );
    }
  }

  /// Demo fallback for when user is testing offline or hasn't pasted API key yet
  GeminiAnalysisResult _generateFallbackResult(String base64Image) {
    return GeminiAnalysisResult(
      status: 'PASS',
      summary: 'Compliant with Legal Metrology (Packaged Commodities) Rules, 2011 (Demo Mode - Please set Gemini API Key in api_constants.dart)',
      extractedData: {
        'manufacturer_name_and_address': 'Kisan Agro Foods Pvt. Ltd., G.T. Road, Karnal, Haryana - 132001',
        'country_of_origin': 'India',
        'commodity_name': 'Premium Tomato Ketchup',
        'net_quantity': '500 g',
        'mfg_packing_date': '08/2026',
        'mrp_inclusive_taxes': '₹125.00 (Incl. of all taxes)',
        'consumer_care_details': 'Care Officer: 1800-11-2026, care@kisanagro.gov.in',
      },
      violations: [],
      rawResponse: '{"status": "PASS", "demo": true}',
    );
  }
}
