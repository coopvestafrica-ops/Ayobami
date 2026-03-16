import 'package:ayobami/domain/entities/user_memory.dart';
import 'package:ayobami/domain/repositories/settings_repository.dart';

class SaveUserMemory {
  final SettingsRepository repository;

  SaveUserMemory(this.repository);

  Future<void> call(UserMemory memory) async {
    await repository.saveUserMemory(memory);
  }
}

class GetUserMemory {
  final SettingsRepository repository;

  GetUserMemory(this.repository);

  Future<List<UserMemory>> call() async {
    return await repository.getUserMemory();
  }
}
