import 'package:equatable/equatable.dart';
import 'package:ayobami/domain/entities/app_settings.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class UpdateSettingsEvent extends SettingsEvent {
  final AppSettings settings;

  const UpdateSettingsEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

class ToggleDarkModeEvent extends SettingsEvent {
  const ToggleDarkModeEvent();
}

class ToggleVoiceEvent extends SettingsEvent {
  const ToggleVoiceEvent();
}
