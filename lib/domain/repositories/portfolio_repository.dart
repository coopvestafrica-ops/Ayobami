import 'package:ayobami/domain/entities/portfolio_item.dart';

abstract class PortfolioRepository {
  Future<List<PortfolioItem>> getPortfolio();
  Future<void> addToPortfolio(PortfolioItem item);
  Future<void> removeFromPortfolio(String id);
  Future<List<PriceAlert>> getPriceAlerts();
  Future<void> addPriceAlert(PriceAlert alert);
  Future<void> removePriceAlert(String id);
  Future<List<Reminder>> getReminders();
  Future<void> addReminder(Reminder reminder);
  Future<void> removeReminder(String id);
  Future<void> updateReminder(Reminder reminder);
}
