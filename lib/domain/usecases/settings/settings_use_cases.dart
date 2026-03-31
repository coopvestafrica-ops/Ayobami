import 'package:ayobami/domain/entities/app_settings.dart';
import 'package:ayobami/domain/repositories/settings_repository.dart';

export 'user_memory_use_cases.dart';

class GetSettings {
  final SettingsRepository repository;

  GetSettings(this.repository);

  Future<AppSettings> call() async {
    return await repository.getSettings();
  }
}

class SaveSettings {
  final SettingsRepository repository;

  SaveSettings(this.repository);

  Future<void> call(AppSettings settings) async {
    await repository.saveSettings(settings);
  }
}
