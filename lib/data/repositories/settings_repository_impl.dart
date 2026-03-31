import 'package:ayobami/data/datasources/local/local_data_source.dart';
import 'package:ayobami/domain/entities/app_settings.dart';
import 'package:ayobami/domain/entities/user_memory.dart';
import 'package:ayobami/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final LocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<AppSettings> getSettings() async {
    return await localDataSource.getSettings();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await localDataSource.saveSettings(settings);
  }

  @override
  Future<void> saveUserMemory(UserMemory memory) async {
    await localDataSource.saveUserMemory(memory);
  }

  @override
  Future<List<UserMemory>> getUserMemory() async {
    return await localDataSource.getUserMemory();
  }

  @override
  Future<void> deleteUserMemory(String id) async {
    await localDataSource.deleteUserMemory(id);
  }

  @override
  Future<void> clearAllData() async {
    await localDataSource.clearChatHistory();
  }
}
