import '../../domain/entities/executive_entities.dart';

class FakeExecutiveDataSource {
  final ExecutiveSummary _summary = const ExecutiveSummary(
    totalEmployees: 452,
    presentPercent: 0.89,
    onLeavePercent: 0.07,
    turnoverPercent: 0.02,
    avgKpiScorePercent: 0.78,
    engagementScorePercent: 0.76,
  );

  final List<TrendPoint> _attendanceTrend = [
    const TrendPoint(label: 'Mon', value: 0.90),
    const TrendPoint(label: 'Tue', value: 0.92),
    const TrendPoint(label: 'Wed', value: 0.89),
    const TrendPoint(label: 'Thu', value: 0.88),
    const TrendPoint(label: 'Fri', value: 0.87),
    const TrendPoint(label: 'Sat', value: 0.10),
    const TrendPoint(label: 'Sun', value: 0.91),
  ];

  final Map<String, double> _kpiHeatmap = {
    'Engineering': 0.82,
    'Sales': 0.75,
    'HR': 0.88,
    'Finance': 0.85,
    'Marketing': 0.70,
  };

  final List<DeptHeadcount> _deptHeadcount = [
    const DeptHeadcount(department: 'Engineering', count: 180),
    const DeptHeadcount(department: 'Sales', count: 120),
    const DeptHeadcount(department: 'HR', count: 25),
    const DeptHeadcount(department: 'Finance', count: 40),
    const DeptHeadcount(department: 'Marketing', count: 87),
  ];

  final List<TrendPoint> _turnoverForecast = [
    const TrendPoint(label: 'Jan', value: 0.015),
    const TrendPoint(label: 'Feb', value: 0.018),
    const TrendPoint(label: 'Mar', value: 0.020),
    const TrendPoint(label: 'Apr', value: 0.022),
    const TrendPoint(label: 'May', value: 0.021),
    const TrendPoint(label: 'Jun', value: 0.019),
  ];

  Future<ExecutiveSummary> getSummary() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _summary;
  }

  Future<List<TrendPoint>> getAttendanceTrend() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _attendanceTrend;
  }

  Future<Map<String, double>> getKpiHeatmap() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _kpiHeatmap;
  }

  Future<List<DeptHeadcount>> getDeptHeadcount() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _deptHeadcount;
  }

  Future<List<TrendPoint>> getTurnoverForecast() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _turnoverForecast;
  }
}
