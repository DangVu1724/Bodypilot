import 'package:core_shared/core_shared.dart';
import 'package:equatable/equatable.dart';

abstract class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersSuccess extends UsersState {
  final List<UserModel> users;
  final String? searchQuery;

  const UsersSuccess(this.users, {this.searchQuery});

  @override
  List<Object?> get props => [users, searchQuery];
}

class UsersFailure extends UsersState {
  final String message;

  const UsersFailure(this.message);

  @override
  List<Object?> get props => [message];
}
