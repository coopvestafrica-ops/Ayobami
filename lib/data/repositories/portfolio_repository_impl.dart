import 'package:ayobami/data/datasources/local/local_data_source.dart';
import 'package:ayobami/data/datasources/remote/market_api_service.dart';
import 'package:ayobami/data/models/portfolio_item_model.dart';
import 'package:ayobami/domain/entities/portfolio_item.dart';
import 'package:ayobami/domain/repositories/portfolio_repository.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  final LocalDataSource localDataSource;
  final MarketApiService marketApiService;

  PortfolioRepositoryImpl({
    required this.localDataSource,
    required this.marketApiService,
  });

  @override
  Future<List<PortfolioItem>> getPortfolio() async {
    return await localDataSource.getPortfolio();
  }

  @override
  Future<void> addToPortfolio(PortfolioItem item) async {
    final model = PortfolioItemModel(
      id: item.id,
      symbol: item.symbol,
      name: item.name,
      quantity: item.quantity,
      averageBuyPrice: item.averageBuyPrice,
      type: item.type,
      addedAt: item.addedAt,
    );
    await localDataSource.addToPortfolio(model);
  }

  @override
  Future<void> removeFromPortfolio(String id) async {
    await localDataSource.removeFromPortfolio(id);
  }

  @override
  Future<List<PriceAlert>> getPriceAlerts() async {
    return await localDataSource.getPriceAlerts();
  }

  @override
  Future<void> addPriceAlert(PriceAlert alert) async {
    final model = PriceAlertModel(
      id: alert.id,
      symbol: alert.symbol,
      targetPrice: alert.targetPrice,
      type: alert.type,
      isActive: alert.isActive,
      createdAt: alert.createdAt,
    );
    await localDataSource.addPriceAlert(model);
  }

  @override
  Future<void> removePriceAlert(String id) async {
    await localDataSource.removePriceAlert(id);
  }

  @override
  Future<List<Reminder>> getReminders() async {
    return await localDataSource.getReminders();
  }

  @override
  Future<void> addReminder(Reminder reminder) async {
    final model = ReminderModel(
      id: reminder.id,
      title: reminder.title,
      description: reminder.description,
      dateTime: reminder.dateTime,
      isCompleted: reminder.isCompleted,
      createdAt: reminder.createdAt,
    );
    await localDataSource.addReminder(model);
  }

  @override
  Future<void> removeReminder(String id) async {
    await localDataSource.removeReminder(id);
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    final model = ReminderModel(
      id: reminder.id,
      title: reminder.title,
      description: reminder.description,
      dateTime: reminder.dateTime,
      isCompleted: reminder.isCompleted,
      createdAt: reminder.createdAt,
    );
    await localDataSource.updateReminder(model);
  }
}
