import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/core/theme/app_theme.dart';
import 'package:ayobami/core/di/injection_container.dart';
import 'package:ayobami/core/voice/voice_controller.dart';
import 'package:ayobami/presentation/bloc/chat/chat_bloc.dart';
import 'package:ayobami/presentation/bloc/chat/chat_event.dart';
import 'package:ayobami/presentation/bloc/market/market_bloc.dart';
import 'package:ayobami/presentation/bloc/market/market_event.dart';
import 'package:ayobami/presentation/bloc/portfolio/portfolio_bloc.dart';
import 'package:ayobami/presentation/bloc/portfolio/portfolio_event.dart';
import 'package:ayobami/presentation/bloc/settings/settings_bloc.dart';
import 'package:ayobami/presentation/bloc/settings/settings_event.dart';
import 'package:ayobami/presentation/pages/home_page.dart';
import 'package:ayobami/presentation/pages/main_page.dart';

class AyobamiApp extends StatelessWidget {
  const AyobamiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final voiceController = sl<VoiceController>();
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ChatBloc(
            getChatHistory: sl(),
            sendMessage: sl(),
            saveUserMemory: sl(),
            getUserMemory: sl(),
            voiceController: voiceController,
          )..add(const LoadChatHistoryEvent()),
        ),
        BlocProvider(
          create: (_) => sl<MarketBloc>()..add(const LoadMarketDataEvent()),
        ),
        BlocProvider(
          create: (_) => sl<PortfolioBloc>()..add(const LoadPortfolioEvent()),
        ),
        BlocProvider(
          create: (_) => sl<SettingsBloc>()..add(const LoadSettingsEvent()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Ayobami',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const MainPage(),
          );
        },
      ),
    );
  }
}
