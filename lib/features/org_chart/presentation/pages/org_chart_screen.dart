import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/org_chart_entities.dart';
import '../bloc/org_chart_cubit.dart';

class OrgChartScreen extends StatelessWidget {
  const OrgChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrgChartCubit>()..fetchData(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppCustomBar(
          title: const Text('Organization Chart'),
          leading: IconButton(
            icon: const Icon(AppIcons.back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<OrgChartCubit, OrgChartState>(
          builder: (context, state) {
            if (state is OrgChartLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is OrgChartLoaded) {
              if (state.rootNode == null) {
                return Center(child: Text('No organizational data found.', style: TextStyle(color: AppColors.textSecondary)));
              }
              return SingleChildScrollView(
                child: _buildTreeView(state.rootNode!, state.childrenMap, 0),
              );
            } else if (state is OrgChartError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildTreeView(OrgNode node, Map<String, List<OrgNode>> childrenMap, int depth) {
    final children = childrenMap[node.id] ?? [];
    
    if (children.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: depth * 16.w),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(AppIcons.profile, color: AppColors.primary),
          ),
          title: Text(node.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${node.title} • ${node.department}'),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: depth * 16.w),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: depth < 2,
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: const Icon(AppIcons.profile, color: Colors.white),
          ),
          title: Text(node.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${node.title} • ${node.department}'),
          children: children.map((c) => _buildTreeView(c, childrenMap, depth + 1)).toList(),
        ),
      ),
    );
  }
}
