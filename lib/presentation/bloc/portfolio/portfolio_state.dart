import 'package:equatable/equatable.dart';
import 'package:ayobami/domain/entities/portfolio_item.dart';

enum PortfolioStatus { initial, loading, success, error }

class PortfolioState extends Equatable {
  final PortfolioStatus status;
  final List<PortfolioItem> items;
  final String? errorMessage;
  final double totalValue;

  const PortfolioState({
    this.status = PortfolioStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.totalValue = 0.0,
  });

  PortfolioState copyWith({
    PortfolioStatus? status,
    List<PortfolioItem>? items,
    String? errorMessage,
    double? totalValue,
  }) {
    return PortfolioState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      totalValue: totalValue ?? this.totalValue,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage, totalValue];
}
