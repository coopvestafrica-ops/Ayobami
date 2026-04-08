import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ayobami/domain/usecases/settings/settings_use_cases.dart';
import 'package:ayobami/domain/entities/app_settings.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final SaveSettings saveSettings;

  SettingsBloc({
    required this.getSettings,
    required this.saveSettings,
  }) : super(SettingsInitial()) {
    on<LoadSettingsEvent>((event, emit) async {
      emit(SettingsLoading());
      try {
        final settings = await getSettings();
        emit(SettingsLoaded(settings: settings));
      } catch (e) {
        emit(SettingsError(message: e.toString()));
      }
    });
  }
}
