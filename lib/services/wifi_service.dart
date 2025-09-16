import 'package:wifi_info_flutter/wifi_info_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiService {
  static final WifiService _instance = WifiService._internal();
  factory WifiService() => _instance;
  WifiService._internal();

  // Check if WiFi permission is granted
  Future<bool> hasWifiPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  // Request WiFi permission
  Future<bool> requestWifiPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Get current WiFi SSID
  Future<String?> getCurrentWifiSSID() async {
    try {
      if (!await hasWifiPermission()) {
        final granted = await requestWifiPermission();
        if (!granted) {
          throw Exception('WiFi permission not granted');
        }
      }

      final wifiInfo = await WifiInfo().getWifiName();
      return wifiInfo?.replaceAll('"', ''); // Remove quotes from SSID
    } catch (e) {
      print('Error getting WiFi SSID: $e');
      return null;
    }
  }

  // Get WiFi BSSID (MAC address)
  Future<String?> getWifiBSSID() async {
    try {
      if (!await hasWifiPermission()) {
        final granted = await requestWifiPermission();
        if (!granted) {
          throw Exception('WiFi permission not granted');
        }
      }

      final bssid = await WifiInfo().getWifiBSSID();
      return bssid;
    } catch (e) {
      print('Error getting WiFi BSSID: $e');
      return null;
    }
  }

  // Get WiFi IP address
  Future<String?> getWifiIP() async {
    try {
      if (!await hasWifiPermission()) {
        final granted = await requestWifiPermission();
        if (!granted) {
          throw Exception('WiFi permission not granted');
        }
      }

      final ip = await WifiInfo().getWifiIP();
      return ip;
    } catch (e) {
      print('Error getting WiFi IP: $e');
      return null;
    }
  }

  // Validate if current WiFi matches expected SSID
  Future<bool> validateWifiSSID(String expectedSSID) async {
    try {
      final currentSSID = await getCurrentWifiSSID();
      if (currentSSID == null) {
        return false;
      }

      // Case-insensitive comparison
      return currentSSID.toLowerCase() == expectedSSID.toLowerCase();
    } catch (e) {
      print('Error validating WiFi SSID: $e');
      return false;
    }
  }

  // Get detailed WiFi information
  Future<Map<String, dynamic>> getWifiInfo() async {
    try {
      if (!await hasWifiPermission()) {
        final granted = await requestWifiPermission();
        if (!granted) {
          throw Exception('WiFi permission not granted');
        }
      }

      final ssid = await getCurrentWifiSSID();
      final bssid = await getWifiBSSID();
      final ip = await getWifiIP();

      return {
        'ssid': ssid,
        'bssid': bssid,
        'ip': ip,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting WiFi info: $e');
      return {
        'ssid': null,
        'bssid': null,
        'ip': null,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Check if device is connected to WiFi
  Future<bool> isConnectedToWifi() async {
    try {
      final ssid = await getCurrentWifiSSID();
      return ssid != null && ssid.isNotEmpty;
    } catch (e) {
      print('Error checking WiFi connection: $e');
      return false;
    }
  }

  // Get WiFi signal strength (if available)
  Future<int?> getWifiSignalStrength() async {
    try {
      // Note: This might not be available on all platforms
      // You may need to use platform-specific code
      return null; // Placeholder for future implementation
    } catch (e) {
      print('Error getting WiFi signal strength: $e');
      return null;
    }
  }

  // Poll SSID periodically and emit changes (simple fallback for platforms without native callbacks)
  Stream<String?> watchSsid({Duration interval = const Duration(seconds: 5)}) async* {
    String? last;
    while (true) {
      try {
        final current = await getCurrentWifiSSID();
        if (current != last) {
          last = current;
          yield current;
        }
      } catch (_) {}
      await Future.delayed(interval);
    }
  }
}
