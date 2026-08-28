import 'package:equatable/equatable.dart';
import '../../../data/models/admin_stats_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardSuccess extends DashboardState {
  final AdminStatsModel stats;

  const DashboardSuccess(this.stats);

  @override
  List<Object?> get props => [stats];
}

class DashboardFailure extends DashboardState {
  final String message;

  const DashboardFailure(this.message);

  @override
  List<Object?> get props => [message];
}
