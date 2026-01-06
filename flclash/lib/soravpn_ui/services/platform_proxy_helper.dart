import 'dart:io';

/// Platform-specific system proxy helper
/// Automatically sets and clears system proxy settings for HTTP/HTTPS traffic
class PlatformProxyHelper {
  static const String proxyHost = '127.0.0.1';
  static const int proxyPort = 7891;

  /// Set system proxy
  /// Returns true if successful, false otherwise
  static Future<bool> setSystemProxy() async {
    try {
      if (Platform.isMacOS) {
        return await _setMacOSProxy();
      } else if (Platform.isWindows) {
        return await _setWindowsProxy();
      } else if (Platform.isLinux) {
        return await _setLinuxProxy();
      }
      return false;
    } catch (e) {
      print('[ProxyHelper] Error setting system proxy: $e');
      return false;
    }
  }

  /// Clear system proxy
  /// Returns true if successful, false otherwise
  static Future<bool> clearSystemProxy() async {
    try {
      if (Platform.isMacOS) {
        return await _clearMacOSProxy();
      } else if (Platform.isWindows) {
        return await _clearWindowsProxy();
      } else if (Platform.isLinux) {
        return await _clearLinuxProxy();
      }
      return false;
    } catch (e) {
      print('[ProxyHelper] Error clearing system proxy: $e');
      return false;
    }
  }

  /// macOS: Set system proxy using networksetup
  static Future<bool> _setMacOSProxy() async {
    try {
      // Get active network service
      final services = await _getMacOSNetworkServices();

      if (services.isEmpty) {
        print('[ProxyHelper] No active network services found');
        return false;
      }

      print('[ProxyHelper] Setting proxy for services: $services');

      for (final service in services) {
        // Set HTTP proxy
        await Process.run('networksetup', [
          '-setwebproxy',
          service,
          proxyHost,
          proxyPort.toString(),
        ]);

        // Enable HTTP proxy
        await Process.run('networksetup', [
          '-setwebproxystate',
          service,
          'on',
        ]);

        // Set HTTPS proxy
        await Process.run('networksetup', [
          '-setsecurewebproxy',
          service,
          proxyHost,
          proxyPort.toString(),
        ]);

        // Enable HTTPS proxy
        await Process.run('networksetup', [
          '-setsecurewebproxystate',
          service,
          'on',
        ]);

        // Set SOCKS proxy
        await Process.run('networksetup', [
          '-setsocksfirewallproxy',
          service,
          proxyHost,
          proxyPort.toString(),
        ]);

        // Enable SOCKS proxy
        await Process.run('networksetup', [
          '-setsocksfirewallproxystate',
          service,
          'on',
        ]);
      }

      print('[ProxyHelper] macOS system proxy set successfully');
      return true;
    } catch (e) {
      print('[ProxyHelper] Failed to set macOS proxy: $e');
      return false;
    }
  }

  /// macOS: Clear system proxy
  static Future<bool> _clearMacOSProxy() async {
    try {
      final services = await _getMacOSNetworkServices();

      for (final service in services) {
        // Disable HTTP proxy
        await Process.run('networksetup', [
          '-setwebproxystate',
          service,
          'off',
        ]);

        // Disable HTTPS proxy
        await Process.run('networksetup', [
          '-setsecurewebproxystate',
          service,
          'off',
        ]);

        // Disable SOCKS proxy
        await Process.run('networksetup', [
          '-setsocksfirewallproxystate',
          service,
          'off',
        ]);
      }

      print('[ProxyHelper] macOS system proxy cleared successfully');
      return true;
    } catch (e) {
      print('[ProxyHelper] Failed to clear macOS proxy: $e');
      return false;
    }
  }

  /// Get active macOS network services
  static Future<List<String>> _getMacOSNetworkServices() async {
    try {
      // Get list of network services
      final result = await Process.run('networksetup', ['-listallnetworkservices']);

      if (result.exitCode != 0) {
        return [];
      }

      final output = result.stdout.toString();
      final lines = output.split('\n');

      // Skip the first line (header) and empty lines
      final services = lines
          .skip(1)
          .where((line) => line.trim().isNotEmpty && !line.startsWith('*'))
          .map((line) => line.trim())
          .toList();

      // Return all valid services
      return services;
    } catch (e) {
      print('[ProxyHelper] Error getting network services: $e');
      // Fallback
      return ['Wi-Fi', 'Ethernet'];
    }
  }

  /// Windows: Set system proxy using registry
  static Future<bool> _setWindowsProxy() async {
    try {
      final proxyServer = '$proxyHost:$proxyPort';

      // Enable proxy
      await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f',
      ]);

      // Set proxy server
      await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyServer',
        '/t',
        'REG_SZ',
        '/d',
        proxyServer,
        '/f',
      ]);

      print('[ProxyHelper] Windows system proxy set successfully');
      return true;
    } catch (e) {
      print('[ProxyHelper] Failed to set Windows proxy: $e');
      return false;
    }
  }

  /// Windows: Clear system proxy
  static Future<bool> _clearWindowsProxy() async {
    try {
      // Disable proxy
      await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f',
      ]);

      print('[ProxyHelper] Windows system proxy cleared successfully');
      return true;
    } catch (e) {
      print('[ProxyHelper] Failed to clear Windows proxy: $e');
      return false;
    }
  }

  /// Linux: Set system proxy using gsettings (GNOME/Ubuntu)
  static Future<bool> _setLinuxProxy() async {
    try {
      // Set proxy mode to manual
      await Process.run('gsettings', [
        'set',
        'org.gnome.system.proxy',
        'mode',
        'manual',
      ]);

      // Set HTTP proxy
      await Process.run('gsettings', [
        'set',
        'org.gnome.system.proxy.http',
        'host',
        proxyHost,
      ]);

      await Process.run('gsettings', [
        'set',
        'org.gnome.system.proxy.http',
        'port',
        proxyPort.toString(),
      ]);

      // Set HTTPS proxy
      await Process.run('gsettings', [
        'set',
        'org.gnome.system.proxy.https',
        'host',
        proxyHost,
      ]);

      await Process.run('gsettings', [
        'set',
        'org.gnome.system.proxy.https',
        'port',
        proxyPort.toString(),
      ]);

      // Set SOCKS proxy
      await Process.run('gsettings', [
        'set',
        'org.gnome.system.proxy.socks',
        'host',
        proxyHost,
      ]);

      await Process.run('gsettings', [
        'set',
        'org.gnome.system.proxy.socks',
        'port',
        proxyPort.toString(),
      ]);

      print('[ProxyHelper] Linux system proxy set successfully');
      return true;
    } catch (e) {
      print('[ProxyHelper] Failed to set Linux proxy: $e');
      return false;
    }
  }

  /// Linux: Clear system proxy
  static Future<bool> _clearLinuxProxy() async {
    try {
      // Set proxy mode to none
      await Process.run('gsettings', [
        'set',
        'org.gnome.system.proxy',
        'mode',
        'none',
      ]);

      print('[ProxyHelper] Linux system proxy cleared successfully');
      return true;
    } catch (e) {
      print('[ProxyHelper] Failed to clear Linux proxy: $e');
      return false;
    }
  }
}
