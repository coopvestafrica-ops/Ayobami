import 'package:equatable/equatable.dart';

abstract class MarketEvent extends Equatable {
  const MarketEvent();

  @override
  List<Object?> get props => [];
}

class LoadMarketDataEvent extends MarketEvent {
  final String? cryptoId;
  
  const LoadMarketDataEvent({this.cryptoId});
  
  @override
  List<Object?> get props => [cryptoId];
}

class RefreshMarketDataEvent extends MarketEvent {
  const RefreshMarketDataEvent();
}

class SearchCryptoEvent extends MarketEvent {
  final String query;
  
  const SearchCryptoEvent(this.query);
  
  @override
  List<Object?> get props => [query];
}

class SelectCryptoEvent extends MarketEvent {
  final String cryptoId;
  
  const SelectCryptoEvent(this.cryptoId);
  
  @override
  List<Object?> get props => [cryptoId];
}

class FilterCryptoEvent extends MarketEvent {
  final String filter; // all, gainers, losers
  
  const FilterCryptoEvent(this.filter);
  
  @override
  List<Object?> get props => [filter];
}