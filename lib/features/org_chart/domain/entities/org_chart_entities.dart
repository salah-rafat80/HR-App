import 'package:equatable/equatable.dart';

class OrgNode extends Equatable {
  final String id;
  final String employeeName;
  final String title;
  final String department;
  final String? managerId; // null means top of the org

  const OrgNode({
    required this.id,
    required this.employeeName,
    required this.title,
    required this.department,
    this.managerId,
  });

  @override
  List<Object?> get props => [id, employeeName, title, department, managerId];
}
