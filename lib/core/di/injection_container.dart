import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayobami/data/datasources/local/database_helper.dart';
import 'package:ayobami/data/datasources/local/local_data_source.dart';
import 'package:ayobami/data/datasources/remote/market_api_service.dart';
import 'package:ayobami/data/repositories/chat_repository_impl.dart';
import 'package:ayobami/data/repositories/market_repository_impl.dart';
import 'package:ayobami/data/repositories/portfolio_repository_impl.dart';
import 'package:ayobami/data/repositories/settings_repository_impl.dart';
import 'package:ayobami/domain/repositories/chat_repository.dart';
import 'package:ayobami/domain/repositories/market_repository.dart';
import 'package:ayobami/domain/repositories/portfolio_repository.dart';
import 'package:ayobami/domain/repositories/settings_repository.dart';
import 'package:ayobami/domain/usecases/chat/chat_use_cases.dart';
import 'package:ayobami/domain/usecases/market/market_use_cases.dart';
import 'package:ayobami/domain/usecases/portfolio/portfolio_use_cases.dart';
import 'package:ayobami/domain/usecases/settings/settings_use_cases.dart';
import 'package:ayobami/presentation/bloc/chat/chat_bloc.dart';
import 'package:ayobami/presentation/bloc/market/market_bloc.dart';
import 'package:ayobami/presentation/bloc/portfolio/portfolio_bloc.dart';
import 'package:ayobami/presentation/bloc/settings/settings_bloc.dart';
import 'package:ayobami/core/voice/voice_controller.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  // Database
  sl.registerLazySingleton(() => DatabaseHelper());
  
  // Data Sources
  sl.registerLazySingleton<LocalDataSource>(
    () => LocalDataSourceImpl(sharedPreferences: sl(), databaseHelper: sl()),
  );
  sl.registerLazySingleton<MarketApiService>(
    () => MarketApiService(),
  );
  
  // Repositories
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<MarketRepository>(
    () => MarketRepositoryImpl(
      marketApiService: sl(),
      localDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<PortfolioRepository>(
    () => PortfolioRepositoryImpl(
      localDataSource: sl(),
      marketApiService: sl(),
    ),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(localDataSource: sl()),
  );
  
  // Use Cases
  sl.registerLazySingleton(() => GetChatHistory(sl()));
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => SaveUserMemory(sl()));
  sl.registerLazySingleton(() => GetUserMemory(sl()));
  sl.registerLazySingleton(() => GetMarketData(sl()));
  sl.registerLazySingleton(() => GetForexRates(sl()));
  sl.registerLazySingleton(() => GetPortfolio(sl()));
  sl.registerLazySingleton(() => AddToPortfolio(sl()));
  sl.registerLazySingleton(() => RemoveFromPortfolio(sl()));
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerLazySingleton(() => SaveSettings(sl()));
  
  // BLoCs
  sl.registerFactory(() => ChatBloc(
    getChatHistory: sl(),
    sendMessage: sl(),
    saveUserMemory: sl(),
    getUserMemory: sl(),
  ));
  sl.registerFactory(() => MarketBloc(
    getMarketData: sl(),
    getForexRates: sl(),
  ));
  sl.registerFactory(() => PortfolioBloc(
    getPortfolio: sl(),
    addToPortfolio: sl(),
    removeFromPortfolio: sl(),
  ));
  sl.registerFactory(() => SettingsBloc(
    getSettings: sl(),
    saveSettings: sl(),
  ));

  // Voice Controller
  sl.registerLazySingleton(() => VoiceController());
}
