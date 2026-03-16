import 'package:ayobami/domain/entities/app_settings.dart';
import 'package:ayobami/domain/entities/user_memory.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<void> saveUserMemory(UserMemory memory);
  Future<List<UserMemory>> getUserMemory();
  Future<void> deleteUserMemory(String id);
  Future<void> clearAllData();
}
