import 'dart:async';
import 'package:ayobami/core/services/binance_websocket_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/domain/usecases/market/market_use_cases.dart';
import 'market_event.dart';
import 'market_state.dart';

class MarketBloc extends Bloc<MarketEvent, MarketState> {
  final GetMarketData getMarketData;
  final GetForexRates? getForexRates;
  final BinanceWebSocketService? wsService;
  StreamSubscription? _wsSubscription;
  
  MarketBloc({
    required this.getMarketData,
    this.getForexRates,
    this.wsService,
  }) : super(const MarketState()) {
    on<LoadMarketDataEvent>(_onLoadMarketData);
    on<RefreshMarketDataEvent>(_onRefreshMarketData);
    on<SearchCryptoEvent>(_onSearchCrypto);
    on<SelectCryptoEvent>(_onSelectCrypto);
    on<FilterCryptoEvent>(_onFilterCrypto);
  }
  
  Future<void> _onLoadMarketData(
    LoadMarketDataEvent event, 
    Emitter<MarketState> emit,
  ) async {
    emit(state.copyWith(status: MarketStatus.loading));
    
    try {
      final marketData = await getMarketData(
        limit: event.cryptoId == null ? 50 : 1,
        cryptoId: event.cryptoId,
      );
      
      // Get selected crypto if specific one was requested
      CryptoCurrency? selected;
      if (event.cryptoId != null && marketData.cryptos.isNotEmpty) {
        selected = marketData.cryptos.first;
      } else if (state.selectedCrypto != null) {
        selected = marketData.cryptos.firstWhere(
          (c) => c.id == state.selectedCrypto!.id,
          orElse: () => marketData.cryptos.isNotEmpty 
              ? marketData.cryptos.first 
              : state.selectedCrypto!,
        );
      }
      
      emit(state.copyWith(
        status: MarketStatus.success,

      // Connect WebSockets for real-time updates
      if (wsService != null) {
        final symbols = marketData.cryptos.map((c) => '${c.symbol.toUpperCase()}USDT').toList();
        wsService!.connect(symbols);
        _wsSubscription?.cancel();
        _wsSubscription = wsService!.stream.listen((data) {
          _handleWsPriceUpdate(data, emit);
        });
      }

        cryptos: marketData.cryptos,
        selectedCrypto: selected,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MarketStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
  
  Future<void> _onRefreshMarketData(
    RefreshMarketDataEvent event, 
    Emitter<MarketState> emit,
  ) async {
    add(LoadMarketDataEvent(cryptoId: state.selectedCrypto?.id));
  }
  
  Future<void> _onSearchCrypto(
    SearchCryptoEvent event, 
    Emitter<MarketState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(searchResults: []));
      return;
    }
    
    final results = state.cryptos.where((c) => 
      c.name.toLowerCase().contains(event.query.toLowerCase()) ||
      c.symbol.toLowerCase().contains(event.query.toLowerCase())
    ).toList();
    
    emit(state.copyWith(searchResults: results));
  }
  
  Future<void> _onSelectCrypto(
    SelectCryptoEvent event, 
    Emitter<MarketState> emit,
  ) async {
    final selected = state.cryptos.firstWhere(
      (c) => c.id == event.cryptoId,
      orElse: () => state.cryptos.first,
    );
    
    emit(state.copyWith(selectedCrypto: selected));
    add(LoadMarketDataEvent(cryptoId: event.cryptoId));
  }
  
  void _onFilterCrypto(
    FilterCryptoEvent event, 
    Emitter<MarketState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  void _handleWsPriceUpdate(dynamic data, Emitter<MarketState> emit) {
    try {
      final json = data is String ? jsonDecode(data) : data;
      final ticker = json['data'];
      final symbol = ticker['s'].toString().replaceAll('USDT', '').toLowerCase();
      final newPrice = double.tryParse(ticker['c'].toString()) ?? 0.0;
      
      final updatedCryptos = state.cryptos.map((c) {
        if (c.symbol.toLowerCase() == symbol) {
          return c.copyWith(currentPrice: newPrice);
        }
        return c;
      }).toList();
      
      emit(state.copyWith(cryptos: updatedCryptos));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    wsService?.disconnect();
    return super.close();
  }

}