import 'package:hr_core/features/appraisal/domain/entities/appraisal_entities.dart';
import 'package:hr_core/features/appraisal/domain/repositories/appraisal_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/bloc/web_cubits.dart';

class AppraisalCubit extends WebCubit<AppraisalCycle> {
  final AppraisalRepository _repo;
  final io.Socket _socket;

  AppraisalCubit(this._repo, this._socket) : super(() => _repo.getCurrentCycle()) {
    _socket.on('entity.updated', _onEntityUpdated);
  }

  void _onEntityUpdated(data) {
    if (data['entity'] == 'AppraisalCycle' && !isClosed) {
      load();
    }
  }

  @override
  Future<void> close() {
    _socket.off('entity.updated', _onEntityUpdated);
    return super.close();
  }

  Future<void> startNewCycle(String label, DateTime dueDate) async {
    await _repo.startNewCycle(label, dueDate);
    load();
  }
}
