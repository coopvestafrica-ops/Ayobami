import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/domain/usecases/portfolio/portfolio_use_cases.dart';
import 'portfolio_event.dart';
import 'portfolio_state.dart';

export 'portfolio_state.dart';

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final GetPortfolio getPortfolio;
  final AddToPortfolio addToPortfolio;
  final RemoveFromPortfolio removeFromPortfolio;

  PortfolioBloc({
    required this.getPortfolio,
    required this.addToPortfolio,
    required this.removeFromPortfolio,
  }) : super(const PortfolioState()) {
    on<LoadPortfolioEvent>(_onLoadPortfolio);
    on<AddPortfolioItemEvent>(_onAddPortfolioItem);
    on<RemovePortfolioItemEvent>(_onRemovePortfolioItem);
    on<RefreshPortfolioEvent>(_onRefreshPortfolio);
  }

  Future<void> _onLoadPortfolio(
    LoadPortfolioEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    emit(state.copyWith(status: PortfolioStatus.loading));
    try {
      final items = await getPortfolio();
      final totalValue = items.fold<double>(0, (sum, item) => sum + item.totalValue);
      emit(state.copyWith(
        status: PortfolioStatus.success,
        items: items,
        totalValue: totalValue,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PortfolioStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddPortfolioItem(
    AddPortfolioItemEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    try {
      await addToPortfolio(event.item);
      add(const LoadPortfolioEvent());
    } catch (e) {
      emit(state.copyWith(
        status: PortfolioStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRemovePortfolioItem(
    RemovePortfolioItemEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    try {
      await removeFromPortfolio(event.id);
      add(const LoadPortfolioEvent());
    } catch (e) {
      emit(state.copyWith(
        status: PortfolioStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshPortfolio(
    RefreshPortfolioEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    add(const LoadPortfolioEvent());
  }
}
