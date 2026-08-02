import 'package:equatable/equatable.dart';
import 'package:core_shared/models/check_in_model.dart';

abstract class CheckInState extends Equatable {
  const CheckInState();

  @override
  List<Object?> get props => [];
}

class CheckInInitial extends CheckInState {}

class CheckInLoading extends CheckInState {}

class CheckInStatusLoaded extends CheckInState {
  final CheckInStatusModel status;

  const CheckInStatusLoaded(this.status);

  @override
  List<Object?> get props => [status];
}

class CheckInSubmitting extends CheckInState {}

class CheckInSuccess extends CheckInState {
  final CheckInResultModel result;

  const CheckInSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class CheckInError extends CheckInState {
  final String message;

  const CheckInError(this.message);

  @override
  List<Object?> get props => [message];
}
