import 'package:equatable/equatable.dart';

class PortfolioItem extends Equatable {
  final String id;
  final String symbol;
  final String name;
  final double quantity;
  final double averageBuyPrice;
  final AssetType type;
  final DateTime addedAt;
  
  const PortfolioItem({
    required this.id,
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.averageBuyPrice,
    required this.type,
    required this.addedAt,
  });
  
  double get totalValue => quantity * averageBuyPrice;
  
  @override
  List<Object?> get props => [id, symbol, name, quantity, averageBuyPrice, type, addedAt];
}

enum AssetType {
  crypto,
  forex,
  stock,
}

class PriceAlert extends Equatable {
  final String id;
  final String symbol;
  final double targetPrice;
  final AlertType type;
  final bool isActive;
  final DateTime createdAt;
  
  const PriceAlert({
    required this.id,
    required this.symbol,
    required this.targetPrice,
    required this.type,
    required this.isActive,
    required this.createdAt,
  });
  
  @override
  List<Object?> get props => [id, symbol, targetPrice, type, isActive, createdAt];
}

enum AlertType {
  above,
  below,
}

class Reminder extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final bool isCompleted;
  final DateTime createdAt;
  
  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    required this.isCompleted,
    required this.createdAt,
  });
  
  @override
  List<Object?> get props => [id, title, description, dateTime, isCompleted, createdAt];
}
