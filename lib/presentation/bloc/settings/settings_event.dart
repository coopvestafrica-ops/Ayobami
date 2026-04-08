part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class SaveSettingsEvent extends SettingsEvent {
  final AppSettings settings;
  const SaveSettingsEvent(this.settings);

  @override
  List<Object> get props => [settings];
}
