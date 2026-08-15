import 'package:dio/dio.dart';
import '../../domain/entities/system_config_entities.dart';

class ApiSystemConfigDataSource {
  final Dio dio;

  ApiSystemConfigDataSource({required this.dio});

  Future<List<OfficeBranch>> getBranches() async {
    try {
      final response = await dio.get('/company-settings/branches');
      return (response.data as List)
          .map((b) => OfficeBranch.fromJson(b))
          .toList();
    } catch (e) {
      throw Exception('Failed to get branches: $e');
    }
  }

  Future<void> addBranch(OfficeBranch branch) async {
    try {
      final payload = branch.toJson();
      payload.remove('id');
      await dio.post('/company-settings/branches', data: payload);
    } catch (e) {
      throw Exception('Failed to add branch: $e');
    }
  }

  Future<void> updateBranch(OfficeBranch branch) async {
    try {
      final payload = branch.toJson();
      payload.remove('id');
      await dio.patch('/company-settings/branches/${branch.id}', data: payload);
    } catch (e) {
      throw Exception('Failed to update branch: $e');
    }
  }

  Future<void> deleteBranch(String id) async {
    try {
      await dio.delete('/company-settings/branches/$id');
    } catch (e) {
      throw Exception('Failed to delete branch: $e');
    }
  }

  Future<List<BranchAssignedEmployee>> getUsersForBranchAssignment() async {
    try {
      final response = await dio.get('/company-settings/users');
      return (response.data as List)
          .map((user) => BranchAssignedEmployee.fromJson(user))
          .toList();
    } catch (e) {
      throw Exception('Failed to get employees for branch assignment: $e');
    }
  }

  Future<void> assignUserBranch(String userId, String branchId) async {
    try {
      await dio.patch(
        '/company-settings/users/$userId/branch',
        data: {'branchId': branchId},
      );
    } catch (e) {
      throw Exception('Failed to assign employee branch: $e');
    }
  }
}
