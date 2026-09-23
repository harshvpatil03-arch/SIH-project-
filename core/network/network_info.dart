// lib/core/network/network_info.dart
import 'dart:async';
import 'dart:io';

class NetworkInfo {
  static final NetworkInfo _instance = NetworkInfo._internal();
  factory NetworkInfo() => _instance;
  NetworkInfo._internal();

  bool _isMockOffline = false;

  /// Allows toggling offline mode during demonstrations without disabling device Wi-Fi
  bool get isMockOffline => _isMockOffline;
  set isMockOffline(bool value) => _isMockOffline = value;

  /// Checks if the device has an active internet connection.
  Future<bool> isConnected() async {
    if (_isMockOffline) return false;

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
