// lib/core/constants/api_constants.dart
class ApiConstants {
  /// Primary VLM: Google Gemini API Key
  /// Leave blank for the user to paste their own Gemini API key.
  /// DO NOT commit actual API keys into version control.
  static const String geminiApiKey = ''; 

  /// Fallback VLM: OpenAI API Key (e.g., sk-proj-...)
  /// Used automatically if Gemini encounters rate-limits, quota exhaustion, or fails.
  static const String openaiApiKey = '';

  /// OpenAI Vision Configuration
  static const String openaiEndpoint = 'https://api.openai.com/v1/chat/completions';
  static const String openaiModel = 'gpt-4o-mini'; // or 'gpt-4o'

  /// Local bridge server IP (Change this to your laptop's Wi-Fi / LAN IP, e.g., 192.168.1.5)
  static const String localServerIp = '192.168.1.100';
  static const int localServerPort = 8080;

  /// Full endpoint for pushing inspection records
  static String get localServerUrl => 'http://$localServerIp:$localServerPort/api/inspection';

  /// Gemini REST endpoint (v1beta gemini-1.5-flash multimodal)
  static String geminiUrl(String apiKey) =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
}
