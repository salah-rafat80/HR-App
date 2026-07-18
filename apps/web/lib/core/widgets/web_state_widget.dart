import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../bloc/web_cubits.dart';

class WebStateWidget<T> extends StatelessWidget {
  final WebCubit<T> cubit;
  final Widget Function(BuildContext, T) builder;
  final bool Function(T)? isEmpty;
  final Widget? emptyWidget;

  const WebStateWidget({
    super.key,
    required this.cubit,
    required this.builder,
    this.isEmpty,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebCubit<T>, WebState<T>>(
      bloc: cubit,
      builder: (context, state) {
        if (state is WebLoading || state is WebInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is WebError<T>) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading data', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(state.message, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Iconsax.refresh),
                  label: const Text('Retry'),
                  onPressed: () => cubit.load(),
                ),
              ],
            ),
          );
        }
        if (state is WebSuccess<T>) {
          if (isEmpty != null && isEmpty!(state.data)) {
            return emptyWidget ?? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.folder_open, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No data available', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }
          return builder(context, state.data);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
