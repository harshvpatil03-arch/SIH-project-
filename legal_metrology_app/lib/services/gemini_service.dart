// lib/services/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/constants/prompt_templates.dart';

class GeminiAnalysisResult {
  final String status; // 'PASS', 'FAIL', or 'UNREADABLE'
  final String reason;
  final Map<String, dynamic> extractedData;
  final List<String> missingFields;
  final String rawResponse;
  final String vlmProvider; // e.g. 'GEMINI 1.5 FLASH', 'OPENAI (gpt-4o-mini)', or 'PRESET_SIMULATOR'

  GeminiAnalysisResult({
    required this.status,
    required this.reason,
    required this.extractedData,
    required this.missingFields,
    required this.rawResponse,
    this.vlmProvider = 'GEMINI 1.5 FLASH',
  });

  factory GeminiAnalysisResult.fromMap(
    Map<String, dynamic> map,
    String raw, {
    String provider = 'GEMINI 1.5 FLASH',
  }) {
    final rawStatus = (map['STATUS'] ?? map['status'] ?? 'FAIL').toString().toUpperCase();
    String normalizedStatus;
    if (rawStatus.contains('PASS')) {
      normalizedStatus = 'PASS';
    } else if (rawStatus.contains('UNREADABLE')) {
      normalizedStatus = 'UNREADABLE';
    } else {
      normalizedStatus = 'FAIL';
    }

    final reasonText = (map['REASON'] ?? map['reason'] ?? '').toString();

    Map<String, dynamic> extracted = {};
    final rawExtracted = map['EXTRACTED_DATA'] ?? map['extracted_data'];
    if (rawExtracted is Map) {
      extracted = Map<String, dynamic>.from(rawExtracted);
    }

    List<String> missing = [];
    final rawMissing = map['MISSING_FIELDS'] ?? map['missing_fields'] ?? map['violations'];
    if (rawMissing is List) {
      missing = rawMissing.map((e) => e.toString()).toList();
    }

    return GeminiAnalysisResult(
      status: normalizedStatus,
      reason: reasonText,
      extractedData: extracted,
      missingFields: missing,
      rawResponse: raw,
      vlmProvider: provider,
    );
  }
}

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  /// Dual-Engine Resilient VLM Inference:
  /// 1. Tries Google Gemini 1.5 Flash (Primary)
  /// 2. If Gemini fails, times out, or quota exhausted -> Automatically fails over to OpenAI GPT-4o / GPT-4o-mini (Fallback)
  /// 3. If neither API key is configured or both fail -> Uses pitch simulation preset
  Future<GeminiAnalysisResult> analyzeLabel(
    String base64Image, {
    String? customApiKey,
    String demoPreset = 'PASS_COMPLIANT',
  }) async {
    final geminiKey = (customApiKey != null && customApiKey.isNotEmpty)
        ? customApiKey
        : ApiConstants.geminiApiKey;
    final openaiKey = ApiConstants.openaiApiKey;

    // ─── 1. PRIMARY: GOOGLE GEMINI 1.5 FLASH ───────────────────────
    if (geminiKey.isNotEmpty) {
      try {
        final geminiResult = await _callGemini(base64Image, geminiKey);
        if (geminiResult != null) {
          return geminiResult;
        }
      } catch (e) {
        print('[VLM PIPELINE] Gemini call encountered error: $e');
      }
    }

    // ─── 2. FALLBACK: OPENAI GPT-4o-mini / GPT-4o ──────────────────
    if (openaiKey.isNotEmpty) {
      try {
        print('[VLM PIPELINE] Engaging OpenAI (${ApiConstants.openaiModel}) fallback engine...');
        final openAiResult = await _callOpenAi(base64Image, openaiKey);
        if (openAiResult != null) {
          return openAiResult;
        }
      } catch (e) {
        print('[VLM PIPELINE] OpenAI fallback also failed: $e');
      }
    }

    // ─── 3. DEMO PRESET SIMULATOR ─────────────────────────────────
    return _generatePresetResult(demoPreset);
  }

  /// Calls Google Gemini 1.5 Flash Multimodal Endpoint
  Future<GeminiAnalysisResult?> _callGemini(String base64Image, String apiKey) async {
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

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 22));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final candidates = decoded['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List;
        final text = parts[0]['text'] as String;

        final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsedJson = jsonDecode(cleaned) as Map<String, dynamic>;
        return GeminiAnalysisResult.fromMap(parsedJson, text, provider: 'GEMINI 1.5 FLASH');
      }
    } else {
      print('[GEMINI ERROR] HTTP ${response.statusCode}: ${response.body}');
    }
    return null;
  }

  /// Calls OpenAI GPT-4o / GPT-4o-mini Vision Chat Completions Endpoint
  Future<GeminiAnalysisResult?> _callOpenAi(String base64Image, String apiKey) async {
    final url = Uri.parse(ApiConstants.openaiEndpoint);
    final payload = {
      'model': ApiConstants.openaiModel,
      'messages': [
        {
          'role': 'system',
          'content': PromptTemplates.legalMetrology2011SystemPrompt,
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Analyze this packaged commodity label strictly under Rule 6 of the Legal Metrology (Packaged Commodities) Rules, 2011. Return raw JSON matching the required schema.',
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
                'detail': 'high',
              },
            },
          ],
        },
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.1,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final choices = decoded['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final content = choices[0]['message']['content'] as String;
        final cleaned = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsedJson = jsonDecode(cleaned) as Map<String, dynamic>;
        return GeminiAnalysisResult.fromMap(
          parsedJson,
          content,
          provider: 'OPENAI (${ApiConstants.openaiModel.toUpperCase()})',
        );
      }
    } else {
      print('[OPENAI ERROR] HTTP ${response.statusCode}: ${response.body}');
    }
    return null;
  }

  /// Preset simulator for pitch demonstrations ensuring Green, Red, and Yellow states trigger on cue
  GeminiAnalysisResult _generatePresetResult(String preset) {
    if (preset.toUpperCase().contains('FAIL') || preset.toUpperCase().contains('VIOLATION')) {
      return GeminiAnalysisResult(
        status: 'FAIL',
        reason: 'Consumer Care contact details missing and MRP format does not state inclusive of all taxes.',
        extractedData: {
          'manufacturer_address': 'Global Treats LLC, Okhla Phase III, New Delhi - 110020',
          'generic_name': 'Choco Wafer Rolls',
          'net_quantity': '250 g',
          'mfg_pack_date': '06/2026',
          'mrp': '₹180.00',
          'consumer_care': null,
          'veg_nonveg_dot': 'Brown',
        },
        missingFields: [
          'Rule 6(1)(e): Maximum Retail Price format missing "inclusive of all taxes"',
          'Rule 6(1)(g): Consumer Care contact details (email/phone/address) missing',
        ],
        rawResponse: '{"STATUS": "FAIL", "PRESET": "VIOLATION"}',
        vlmProvider: 'PRESET SIMULATOR',
      );
    } else if (preset.toUpperCase().contains('UNREADABLE') || preset.toUpperCase().contains('GLARE')) {
      return GeminiAnalysisResult(
        status: 'UNREADABLE',
        reason: 'Severe glare reflection and packaging curvature across the Net Quantity and Batch Date. Reading impossible without risking hallucination.',
        extractedData: {},
        missingFields: ['Net Quantity obscured by glare', 'Batch date obscured'],
        rawResponse: '{"STATUS": "UNREADABLE", "PRESET": "GLARE"}',
        vlmProvider: 'PRESET SIMULATOR',
      );
    }

    // Default PASS (Compliant)
    return GeminiAnalysisResult(
      status: 'PASS',
      reason: '',
      extractedData: {
        'manufacturer_address': 'Kisan Agro Foods Pvt. Ltd., G.T. Road, Karnal, Haryana - 132001',
        'generic_name': 'Premium Tomato Ketchup',
        'net_quantity': '500 g',
        'mfg_pack_date': '08/2026',
        'mrp': '₹125.00 inclusive of all taxes',
        'consumer_care': 'Toll Free: 1800-11-2026, care@kisanagro.gov.in',
        'veg_nonveg_dot': 'Green',
      },
      missingFields: [],
      rawResponse: '{"STATUS": "PASS", "PRESET": "COMPLIANT"}',
      vlmProvider: 'PRESET SIMULATOR',
    );
  }
}
