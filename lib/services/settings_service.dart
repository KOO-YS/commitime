import 'package:shared_preferences/shared_preferences.dart';

/// 앱 설정 저장 서비스
class SettingsService {
  static const String _keyAlarmVolume = 'alarm_volume';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keySoundEnabled = 'sound_enabled';

  static SettingsService? _instance;
  static SharedPreferences? _prefs;

  SettingsService._();

  static Future<SettingsService> getInstance() async {
    if (_instance == null) {
      _instance = SettingsService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  /// 알람 볼륨 (0.0 ~ 1.0)
  double get alarmVolume => _prefs?.getDouble(_keyAlarmVolume) ?? 0.8;

  Future<void> setAlarmVolume(double volume) async {
    await _prefs?.setDouble(_keyAlarmVolume, volume.clamp(0.0, 1.0));
  }

  /// 알림 활성화 여부
  bool get notificationsEnabled =>
      _prefs?.getBool(_keyNotificationsEnabled) ?? true;

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyNotificationsEnabled, enabled);
  }

  /// 사운드 활성화 여부
  bool get soundEnabled => _prefs?.getBool(_keySoundEnabled) ?? true;

  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs?.setBool(_keySoundEnabled, enabled);
  }
}
