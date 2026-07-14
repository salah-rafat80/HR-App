import 'package:equatable/equatable.dart';
import '../../domain/entities/kpi_entities.dart';

sealed class KpiState extends Equatable {
  const KpiState();
  @override
  List<Object?> get props => [];
}

class KpiInitial extends KpiState {}

class KpiLoading extends KpiState {}

class KpiLoaded extends KpiState {
  final List<Kpi> kpis;
  final List<KpiQuarterScore> history;
  final bool isSubmitting;
  final String? submitError;
  final bool submitSuccess;

  const KpiLoaded({
    required this.kpis,
    required this.history,
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess = false,
  });

  KpiLoaded copyWith({
    List<Kpi>? kpis,
    List<KpiQuarterScore>? history,
    bool? isSubmitting,
    String? submitError,
    bool? submitSuccess,
  }) {
    return KpiLoaded(
      kpis: kpis ?? this.kpis,
      history: history ?? this.history,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }

  @override
  List<Object?> get props => [kpis, history, isSubmitting, submitError, submitSuccess];
}

class KpiError extends KpiState {
  final String message;
  const KpiError(this.message);
  @override
  List<Object?> get props => [message];
}
