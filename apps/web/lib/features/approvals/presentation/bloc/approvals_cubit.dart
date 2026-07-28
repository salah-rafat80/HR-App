import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/bloc/web_cubits.dart';
import '../../../../core/di/injection.dart';

class ApprovalsCubit extends WebCubit<List<LeaveRequest>> {
  final LeaveRepository _repo;
  final io.Socket _socket;
  final Set<String> _inFlightIds = {};

  bool isInFlight(String id) => _inFlightIds.contains(id);

  ApprovalsCubit(this._repo, this._socket, String userId, String role) : super(() => _repo.getPendingApprovals(ApprovalScope.all)) {
    _socket.on('entity.updated.$userId', _onEntityUpdated);
    _socket.on('entity.updated.$role', _onEntityUpdated);
  }


  void _onEntityUpdated(data) {
    if (data['entity'] == 'LeaveRequest' && !isClosed) {
      _loadSilently();
    }
  }

  Future<void> _loadSilently() async {
    try {
      final data = await fetchData();
      if (!isClosed) emit(WebSuccess<List<LeaveRequest>>(data));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    final prefs = getIt<SharedPreferences>();
    final userId = prefs.getString('user_id') ?? '';
    final role = prefs.getString('user_role') ?? '';
    _socket.off('entity.updated.$userId', _onEntityUpdated);
    _socket.off('entity.updated.$role', _onEntityUpdated);
    return super.close();
  }

  Future<void> approve(String id, {void Function(String)? onError}) async {
    await _performAction(id, _repo.approveRequest, onError);
  }

  Future<void> reject(String id, {void Function(String)? onError}) async {
    await _performAction(id, _repo.rejectRequest, onError);
  }

  Future<void> _performAction(String id, Future<void> Function(String) action, void Function(String)? onError) async {
    if (state is WebSuccess<List<LeaveRequest>>) {
      final currentList = (state as WebSuccess<List<LeaveRequest>>).data;
      _inFlightIds.add(id);
      emit(WebSuccess<List<LeaveRequest>>(List.from(currentList)));
      
      try {
        await action(id);
        _inFlightIds.remove(id);
        _loadSilently();
      } catch (e) {
        _inFlightIds.remove(id);
        emit(WebSuccess<List<LeaveRequest>>(List.from(currentList)));
        onError?.call(e.toString());
      }
    } else {
      await action(id);
      load();
    }
  }
}

