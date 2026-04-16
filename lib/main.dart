import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/app.dart';
import 'package:ayobami/core/di/injection_container.dart' as di;
import 'package:ayobami/core/services/autonomous_trading_service.dart';
import 'package:get_it/get_it.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Workmanager executing task: $task");
    try {
      await di.init();
      final tradingService = GetIt.I<AutonomousTradingService>();
      await tradingService.start();
      return Future.value(true);
    } catch (e) {
      print("Workmanager error: $e");
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize dependency injection
  await di.init();
  
  // Start the autonomous trading service
  // In a real Flutter app, we would use flutter_background_service or workmanager
  // for true 24/7 background execution. For this implementation, we start it
  // as a persistent service within the app lifecycle.
  final tradingService = GetIt.I<AutonomousTradingService>();
  await tradingService.start();
  
  // Initialize background execution
  await tradingService.startBackgroundExecution(callbackDispatcher);
  
  runApp(const AyobamiApp());
}
