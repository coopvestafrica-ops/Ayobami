import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ayobami/domain/usecases/portfolio/portfolio_use_cases.dart';
import 'package:ayobami/domain/entities/portfolio_item.dart';

part 'portfolio_event.dart';
part 'portfolio_state.dart';

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final GetPortfolio getPortfolio;
  final AddToPortfolio addToPortfolio;
  final RemoveFromPortfolio removeFromPortfolio;

  PortfolioBloc({
    required this.getPortfolio,
    required this.addToPortfolio,
    required this.removeFromPortfolio,
  }) : super(PortfolioInitial()) {
    on<LoadPortfolioEvent>((event, emit) async {
      emit(PortfolioLoading());
      try {
        final portfolio = await getPortfolio();
        emit(PortfolioLoaded(portfolio: portfolio));
      } catch (e) {
        emit(PortfolioError(message: e.toString()));
      }
    });
  }
}
