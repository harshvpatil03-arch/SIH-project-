// lib/core/constants/api_constants.dart
class ApiConstants {
  /// Leave blank for the user to paste their own Gemini API key.
  /// DO NOT commit actual API keys into version control.
  static const String geminiApiKey = ''; 

  /// Local bridge server IP (Change this to your laptop's Wi-Fi / LAN IP, e.g., 192.168.1.5)
  static const String localServerIp = '192.168.1.100';
  static const int localServerPort = 8080;

  /// Full endpoint for pushing inspection records
  static String get localServerUrl => 'http://$localServerIp:$localServerPort/api/inspection';

  /// Gemini REST endpoint (v1beta gemini-1.5-flash multimodal)
  static String geminiUrl(String apiKey) =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
}
