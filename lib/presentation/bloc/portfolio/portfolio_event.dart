import 'package:equatable/equatable.dart';
import 'package:ayobami/domain/entities/portfolio_item.dart';

abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object?> get props => [];
}

class LoadPortfolioEvent extends PortfolioEvent {
  const LoadPortfolioEvent();
}

class AddPortfolioItemEvent extends PortfolioEvent {
  final PortfolioItem item;

  const AddPortfolioItemEvent(this.item);

  @override
  List<Object?> get props => [item];
}

class RemovePortfolioItemEvent extends PortfolioEvent {
  final String id;

  const RemovePortfolioItemEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class RefreshPortfolioEvent extends PortfolioEvent {
  const RefreshPortfolioEvent();
}
