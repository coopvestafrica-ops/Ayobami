import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/domain/usecases/settings/settings_use_cases.dart';
import 'settings_event.dart';
import 'settings_state.dart';

export 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final SaveSettings saveSettings;

  SettingsBloc({
    required this.getSettings,
    required this.saveSettings,
  }) : super(const SettingsState()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);
    on<ToggleDarkModeEvent>(_onToggleDarkMode);
    on<ToggleVoiceEvent>(_onToggleVoice);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final settings = await getSettings();
      emit(SettingsState.fromSettings(settings));
    } catch (e) {
      // Keep default settings on error
    }
  }

  Future<void> _onUpdateSettings(
    UpdateSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await saveSettings(event.settings);
      emit(SettingsState.fromSettings(event.settings));
    } catch (e) {
      // Keep current settings on error
    }
  }

  Future<void> _onToggleDarkMode(
    ToggleDarkModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final newState = state.copyWith(isDarkMode: !state.isDarkMode);
    emit(newState);
    await saveSettings(newState.toSettings());
  }

  Future<void> _onToggleVoice(
    ToggleVoiceEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final newState = state.copyWith(isVoiceEnabled: !state.isVoiceEnabled);
    emit(newState);
    await saveSettings(newState.toSettings());
  }
}
