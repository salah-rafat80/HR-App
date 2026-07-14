import '../entities/home_entities.dart';

abstract class HomeRepository {
  Future<HomeDashboardData> getDashboardData();
}
