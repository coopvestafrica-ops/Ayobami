import 'package:ayobami/domain/entities/portfolio_item.dart';

class PortfolioItemModel extends PortfolioItem {
  const PortfolioItemModel({
    required super.id,
    required super.symbol,
    required super.name,
    required super.quantity,
    required super.averageBuyPrice,
    required super.type,
    required super.addedAt,
  });

  factory PortfolioItemModel.fromJson(Map<String, dynamic> json) {
    return PortfolioItemModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      averageBuyPrice: (json['average_buy_price'] as num).toDouble(),
      type: AssetType.values[json['type'] as int],
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'quantity': quantity,
      'average_buy_price': averageBuyPrice,
      'type': type.index,
      'added_at': addedAt.toIso8601String(),
    };
  }
}

class PriceAlertModel extends PriceAlert {
  const PriceAlertModel({
    required super.id,
    required super.symbol,
    required super.targetPrice,
    required super.type,
    required super.isActive,
    required super.createdAt,
  });

  factory PriceAlertModel.fromJson(Map<String, dynamic> json) {
    return PriceAlertModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      targetPrice: (json['target_price'] as num).toDouble(),
      type: AlertType.values[json['type'] as int],
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'target_price': targetPrice,
      'type': type.index,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ReminderModel extends Reminder {
  const ReminderModel({
    required super.id,
    required super.title,
    super.description,
    required super.dateTime,
    required super.isCompleted,
    required super.createdAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dateTime: DateTime.parse(json['date_time'] as String),
      isCompleted: json['is_completed'] == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date_time': dateTime.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
