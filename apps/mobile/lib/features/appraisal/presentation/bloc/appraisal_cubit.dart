import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'appraisal_state.dart';
import 'package:hr_core/features/appraisal/domain/repositories/appraisal_repository.dart';
import 'package:hr_core/features/kpi/domain/repositories/kpi_repository.dart';
import 'package:hr_core/features/appraisal/domain/entities/appraisal_entities.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class AppraisalCubit extends SafeCubit<AppraisalState> {
  final AppraisalRepository _repository;
  final KpiRepository _kpiRepository;
  final io.Socket _socket;

  AppraisalCubit(this._repository, this._kpiRepository, this._socket) : super(AppraisalInitial()) {
    _socket.on('entity.updated', _onEntityUpdated);
  }

  void _onEntityUpdated(data) {
    if (data['entity'] == 'AppraisalCycle' && !isClosed) {
      loadData();
    }
  }

  @override
  Future<void> close() {
    _socket.off('entity.updated', _onEntityUpdated);
    return super.close();
  }

  Future<void> loadData() async {
    if (!isClosed) { emit(AppraisalLoading()); }
    try {
      final cycle = await _repository.getCurrentCycle();
      final questions = await _repository.getSelfAppraisalQuestions();
      final peers = await _repository.getPeersForFeedback();
      final results = await _repository.getMyResults();
      final devPlan = await _repository.getDevelopmentPlan();
      final careerPath = await _repository.getCareerPath();
      final kpiScore = await _kpiRepository.getOverallQuarterScore();

      if (!isClosed) { emit(AppraisalLoaded(
        cycle: cycle,
        questions: questions,
        peers: peers,
        myResults: results,
        devPlan: devPlan,
        careerPath: careerPath,
        currentKpiScore: kpiScore,
      )); }
    } catch (e) {
      if (!isClosed) { emit(AppraisalError(e.toString())); }
    }
  }

  Future<void> submitSelfAppraisal(List<SelfAppraisalQuestion> answers) async {
    if (state is! AppraisalLoaded) return;
    final currentState = state as AppraisalLoaded;
    if (!isClosed) { emit(currentState.copyWith(isSubmitting: true, submitError: null, submitSuccess: false)); }
    try {
      await _repository.submitSelfAppraisal(answers);
      final updatedCycle = await _repository.getCurrentCycle();
      if (!isClosed) { emit(currentState.copyWith(isSubmitting: false, submitSuccess: true, cycle: updatedCycle)); }
    } catch (e) {
      if (!isClosed) { emit(currentState.copyWith(isSubmitting: false, submitError: e.toString())); }
    }
  }

  Future<void> submitPeerFeedback(String colleagueId, String text) async {
    if (state is! AppraisalLoaded) return;
    try {
      await _repository.submitPeerFeedback(colleagueId, text);
      final updatedPeers = await _repository.getPeersForFeedback();
      if (!isClosed) { emit((state as AppraisalLoaded).copyWith(peers: updatedPeers)); }
    } catch (e) {
      // Ignore
    }
  }
}
