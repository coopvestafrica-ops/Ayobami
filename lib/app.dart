import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/core/theme/app_theme.dart';
import 'package:ayobami/core/di/injection_container.dart';
import 'package:ayobami/presentation/bloc/chat/chat_bloc.dart';
import 'package:ayobami/presentation/bloc/market/market_bloc.dart';
import 'package:ayobami/presentation/bloc/portfolio/portfolio_bloc.dart';
import 'package:ayobami/presentation/bloc/settings/settings_bloc.dart';
import 'package:ayobami/presentation/pages/main_page.dart';

class AyobamiApp extends StatelessWidget {
  const AyobamiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ChatBloc>()..add(LoadChatHistory()),
        ),
        BlocProvider(
          create: (_) => sl<MarketBloc>()..add(LoadMarketData()),
        ),
        BlocProvider(
          create: (_) => sl<PortfolioBloc>()..add(LoadPortfolio()),
        ),
        BlocProvider(
          create: (_) => sl<SettingsBloc>()..add(LoadSettings()),
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
