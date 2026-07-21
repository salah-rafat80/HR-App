import 'package:hr_core/features/admin/domain/entities/recruitment_entities.dart';
import 'package:hr_core/features/admin/domain/repositories/recruitment_repository.dart';
import '../../../../core/bloc/web_cubits.dart';

class RecruitmentCubit extends WebCubit<List<Candidate>> {
  final RecruitmentRepository _repo;

  RecruitmentCubit(this._repo) : super(() => _loadAllCandidates(_repo));

  static Future<List<Candidate>> _loadAllCandidates(RecruitmentRepository repo) async {
    final jobs = await repo.getJobRequisitions();
    final List<Candidate> all = [];
    for (final job in jobs) {
      all.addAll(await repo.getCandidates(job.id));
    }
    return all;
  }

  Future<void> moveCandidate(String candidateId, CandidateStage newStage) async {
    await _repo.moveCandidateStage(candidateId, newStage);
    load();
  }

  Future<void> postNewJob(String title, String department) async {
    final draft = JobRequisition(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      department: department,
      status: 'open',
      openings: 1,
    );
    await _repo.postJob(draft);
    load();
  }
}
