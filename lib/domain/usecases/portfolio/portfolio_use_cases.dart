import 'package:ayobami/domain/entities/portfolio_item.dart';
import 'package:ayobami/domain/repositories/portfolio_repository.dart';

class GetPortfolio {
  final PortfolioRepository repository;

  GetPortfolio(this.repository);

  Future<List<PortfolioItem>> call() async {
    return await repository.getPortfolio();
  }
}

class AddToPortfolio {
  final PortfolioRepository repository;

  AddToPortfolio(this.repository);

  Future<void> call(PortfolioItem item) async {
    await repository.addToPortfolio(item);
  }
}

class RemoveFromPortfolio {
  final PortfolioRepository repository;

  RemoveFromPortfolio(this.repository);

  Future<void> call(String id) async {
    await repository.removeFromPortfolio(id);
  }
}
