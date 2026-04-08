part of 'portfolio_bloc.dart';

abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object> get props => [];
}

class LoadPortfolioEvent extends PortfolioEvent {
  const LoadPortfolioEvent();
}

class AddToPortfolioEvent extends PortfolioEvent {
  final PortfolioItem item;
  const AddToPortfolioEvent(this.item);

  @override
  List<Object> get props => [item];
}

class RemoveFromPortfolioEvent extends PortfolioEvent {
  final String id;
  const RemoveFromPortfolioEvent(this.id);

  @override
  List<Object> get props => [id];
}
