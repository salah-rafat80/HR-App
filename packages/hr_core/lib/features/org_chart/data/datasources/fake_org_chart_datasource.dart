import '../../domain/entities/org_chart_entities.dart';

class FakeOrgChartDataSource {
  final List<OrgNode> _nodes = [
    const OrgNode(
      id: '1',
      employeeName: 'Ahmed Hassan', // CEO
      title: 'Chief Executive Officer',
      department: 'Executive',
      managerId: null,
    ),
    const OrgNode(
      id: '2',
      employeeName: 'Sara Ali',
      title: 'VP of Engineering',
      department: 'Engineering',
      managerId: '1',
    ),
    const OrgNode(
      id: '3',
      employeeName: 'Omar Khaled',
      title: 'VP of Sales',
      department: 'Sales',
      managerId: '1',
    ),
    const OrgNode(
      id: '4',
      employeeName: 'Nour Tariq',
      title: 'Head of HR',
      department: 'HR',
      managerId: '1',
    ),
    const OrgNode(
      id: '5',
      employeeName: 'Mona Youssef',
      title: 'VP of Marketing',
      department: 'Marketing',
      managerId: '1',
    ),
    const OrgNode(
      id: '6',
      employeeName: 'Tariq Ziad',
      title: 'VP of Finance',
      department: 'Finance',
      managerId: '1',
    ),
    const OrgNode(
      id: '7',
      employeeName: 'Amira Khaled',
      title: 'Engineering Manager',
      department: 'Engineering',
      managerId: '2',
    ),
    const OrgNode(
      id: '8',
      employeeName: 'Ziad Mahmoud',
      title: 'Senior Developer',
      department: 'Engineering',
      managerId: '7',
    ),
    const OrgNode(
      id: '9',
      employeeName: 'Hassan Omar',
      title: 'Flutter Developer',
      department: 'Engineering',
      managerId: '7',
    ),
    const OrgNode(
      id: '10',
      employeeName: 'Fatma Ali',
      title: 'Sales Director',
      department: 'Sales',
      managerId: '3',
    ),
    const OrgNode(
      id: '11',
      employeeName: 'Khaled Noor',
      title: 'Sales Executive',
      department: 'Sales',
      managerId: '10',
    ),
    const OrgNode(
      id: '12',
      employeeName: 'Ali Youssef',
      title: 'HR Business Partner',
      department: 'HR',
      managerId: '4',
    ),
    const OrgNode(
      id: '13',
      employeeName: 'Youssef Tariq',
      title: 'Recruiter',
      department: 'HR',
      managerId: '12',
    ),
    const OrgNode(
      id: '14',
      employeeName: 'Salma Hassan',
      title: 'Marketing Manager',
      department: 'Marketing',
      managerId: '5',
    ),
    const OrgNode(
      id: '15',
      employeeName: 'Noor Ali',
      title: 'Accountant',
      department: 'Finance',
      managerId: '6',
    ),
  ];

  Future<List<OrgNode>> getOrgChart() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _nodes;
  }
}
