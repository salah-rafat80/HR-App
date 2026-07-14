import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'kpi_state.dart';
import '../../domain/repositories/kpi_repository.dart';

class KpiCubit extends SafeCubit<KpiState> {
  final KpiRepository _repository;

  KpiCubit(this._repository) : super(KpiInitial());

  Future<void> loadData() async {
    if (!isClosed) { emit(KpiLoading()); }
    try {
      final kpis = await _repository.getCurrentKpis();
      final history = await _repository.getHistoricalScores();
      if (!isClosed) { emit(KpiLoaded(kpis: kpis, history: history)); }
    } catch (e) {
      if (!isClosed) { emit(KpiError(e.toString())); }
    }
  }

  Future<void> submitAssessment(String kpiId, String text) async {
    if (state is! KpiLoaded) return;
    final currentState = state as KpiLoaded;
    if (!isClosed) { emit(currentState.copyWith(isSubmitting: true, submitError: null, submitSuccess: false)); }
    try {
      await _repository.submitSelfAssessment(kpiId, text);
      final updatedKpis = await _repository.getCurrentKpis();
      if (!isClosed) { emit(currentState.copyWith(isSubmitting: false, submitSuccess: true, kpis: updatedKpis)); }
    } catch (e) {
      if (!isClosed) { emit(currentState.copyWith(isSubmitting: false, submitError: e.toString())); }
    }
  }

  Future<void> attachEvidence(String kpiId) async {
    if (state is! KpiLoaded) return;
    try {
      await _repository.attachEvidence(kpiId);
      final updatedKpis = await _repository.getCurrentKpis();
      if (!isClosed) { emit((state as KpiLoaded).copyWith(kpis: updatedKpis)); }
    } catch (e) {
      // Ignore
    }
  }
}
