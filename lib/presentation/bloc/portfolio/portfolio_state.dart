part of 'portfolio_bloc.dart';

abstract class PortfolioState extends Equatable {
  const PortfolioState();

  @override
  List<Object> get props => [];
}

class PortfolioInitial extends PortfolioState {}

class PortfolioLoading extends PortfolioState {}

class PortfolioLoaded extends PortfolioState {
  final List<PortfolioItem> portfolio;
  const PortfolioLoaded({required this.portfolio});

  @override
  List<Object> get props => [portfolio];
}

class PortfolioError extends PortfolioState {
  final String message;
  const PortfolioError({required this.message});

  @override
  List<Object> get props => [message];
}
