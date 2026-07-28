import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/features/executive/domain/repositories/executive_repository.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../../../../core/di/injection.dart';
import '../bloc/executive_cubit.dart';
import '../widgets/executive_dashboard_body.dart';

class ExecutiveScreen extends StatelessWidget {
  const ExecutiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExecutiveCubit(getIt<ExecutiveRepository>()),
      child: const _ExecutiveView(),
    );
  }
}

class _ExecutiveView extends StatelessWidget {
  const _ExecutiveView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocBuilder<ExecutiveCubit, WebState<ExecutiveDashboardData>>(
          builder: (context, state) {
            if (state is WebLoading || state is WebInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is WebError<ExecutiveDashboardData>) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Iconsax.refresh),
                      label: const Text('Retry'),
                      onPressed: () => context.read<ExecutiveCubit>().load(),
                    ),
                  ],
                ),
              );
            }
            if (state is WebSuccess<ExecutiveDashboardData>) {
              return ExecutiveBody(data: state.data);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}






