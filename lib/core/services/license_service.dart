import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../features/authentication/models/user_info.dart';

class LicenseService {
  final FlutterSecureStorage? _secureStorage;
  final SharedPreferences? _prefs;
  
  static const String _licenseKeyKey = 'license_key';
  static const String _activationDateKey = 'activation_date';
  static const String _userInfoKey = 'user_info_json';
  static const String _setupDoneKey = 'setup_done';
  
  LicenseService({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? prefs,
  })  : _secureStorage = secureStorage,
        _prefs = prefs;
  
  /// Prüft ob die App aktiviert ist (lokal gespeicherter Key)
  Future<bool> isActivated() async {
    final key = await _getKey();
    if (key == null) return false;
    // Lokal nur Format-Check – die Online-Validierung passiert bei Aktivierung
    return _isValidFormat(key);
  }
  
  /// Aktiviert die App – prüft Key online gegen GitHub-Key-Liste
  /// Gibt zurück: true = aktiviert, false = ungültig
  /// Wirft Exception bei Netzwerk-Fehler
  Future<bool> activateLicense(String productKey) async {
    final cleanKey = productKey.trim().toUpperCase();
    
    if (!_isValidFormat(cleanKey)) return false;
    
    // Online-Validierung gegen GitHub-Keys-Liste
    final validKeys = await _fetchValidKeys();
    
    if (validKeys.contains(cleanKey)) {
      await _setKey(cleanKey);
      await _setActivationDate(DateTime.now().toIso8601String());
      return true;
    }
    
    return false;
  }

  /// Lädt die Liste gültiger Keys von GitHub
  Future<Set<String>> _fetchValidKeys() async {
    final url = AppConfig.keysUrl;
    if (url == 'DEINE_GITHUB_KEYS_URL') {
      throw Exception('https://gist.githubusercontent.com/Dominic9603/34bb50d8d637916c99703f00de0e35ff/raw/fa7524f29fab05498fa6d7416dd842993517fc0e/keys.json');
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Server-Fehler (${response.statusCode})');
      }

      final data = jsonDecode(response.body);
      final List<dynamic> keyList = data['keys'] ?? [];
      return keyList.map((k) => k.toString().trim().toUpperCase()).toSet();
    } catch (e) {
      if (e is Exception && e.toString().contains('Keys-URL nicht konfiguriert')) {
        rethrow;
      }
      throw Exception('Keine Internetverbindung. Bitte prüfen Sie Ihre Verbindung und versuchen Sie es erneut.');
    }
  }
  
  /// Prüft ob ein Key das gültige Format hat (XXXX-XXXX-XXXX-XXXX)
  bool _isValidFormat(String key) {
    final parts = key.split('-');
    if (parts.length != 4) return false;
    if (parts.any((part) => part.length != 4)) return false;
    return RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(key);
  }
  
  /// Gibt den aktuellen License Key zurück
  Future<String?> getLicenseKey() async {
    return await _getKey();
  }
  
  /// Gibt das Aktivierungsdatum zurück
  Future<DateTime?> getActivationDate() async {
    final dateStr = await _getActivationDate();
    if (dateStr == null) return null;
    return DateTime.parse(dateStr);
  }
  
  /// Deaktiviert die Lizenz (für Testing)
  Future<void> deactivate() async {
    await _deleteKey();
    await _deleteActivationDate();
  }

  // Private Helper für Plattform-Abstraktion
  Future<String?> _getKey() async {
    if (_isWeb()) {
      return _prefs?.getString(_licenseKeyKey);
    } else {
      return await _secureStorage?.read(key: _licenseKeyKey);
    }
  }

  Future<void> _setKey(String value) async {
    if (_isWeb()) {
      await _prefs?.setString(_licenseKeyKey, value);
    } else {
      await _secureStorage?.write(key: _licenseKeyKey, value: value);
    }
  }

  Future<void> _deleteKey() async {
    if (_isWeb()) {
      await _prefs?.remove(_licenseKeyKey);
    } else {
      await _secureStorage?.delete(key: _licenseKeyKey);
    }
  }

  Future<String?> _getActivationDate() async {
    if (_isWeb()) {
      return _prefs?.getString(_activationDateKey);
    } else {
      return await _secureStorage?.read(key: _activationDateKey);
    }
  }

  Future<void> _setActivationDate(String value) async {
    if (_isWeb()) {
      await _prefs?.setString(_activationDateKey, value);
    } else {
      await _secureStorage?.write(key: _activationDateKey, value: value);
    }
  }

  Future<void> _deleteActivationDate() async {
    if (_isWeb()) {
      await _prefs?.remove(_activationDateKey);
    } else {
      await _secureStorage?.delete(key: _activationDateKey);
    }
  }
  bool _isWeb() {
    return kIsWeb;
  }

  // ===== BenutzerInfo Management =====

  /// Prüft ob das Setup (Personalisierung) bereits durchgeführt wurde
  Future<bool> isSetupDone() async {
    if (_isWeb()) {
      return _prefs?.getBool(_setupDoneKey) ?? false;
    } else {
      final value = await _secureStorage?.read(key: _setupDoneKey);
      return value == 'true';
    }
  }

  /// Speichert BenutzerInfo und markiert Setup als done
  Future<void> saveUserInfo(UserInfo userInfo) async {
    final json = jsonEncode(userInfo.toJson());
    if (_isWeb()) {
      await _prefs?.setString(_userInfoKey, json);
      await _prefs?.setBool(_setupDoneKey, true);
    } else {
      await _secureStorage?.write(key: _userInfoKey, value: json);
      await _secureStorage?.write(key: _setupDoneKey, value: 'true');
    }
  }

  /// Lädt BenutzerInfo oder gibt null zurück falls nicht gesetzt
  Future<UserInfo?> getUserInfo() async {
    String? json;
    if (_isWeb()) {
      json = _prefs?.getString(_userInfoKey);
    } else {
      json = await _secureStorage?.read(key: _userInfoKey);
    }
    
    if (json == null) return null;
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return UserInfo.fromJson(data);
    } catch (e) {
      print('Fehler beim Laden der BenutzerInfo: $e');
      return null;
    }
  }
}
