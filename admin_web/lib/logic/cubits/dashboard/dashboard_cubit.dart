import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/admin_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final AdminRepository adminRepository;

  DashboardCubit({required this.adminRepository}) : super(DashboardInitial());

  Future<void> fetchDashboardStats() async {
    emit(DashboardLoading());
    try {
      final stats = await adminRepository.getDashboardStats();
      emit(DashboardSuccess(stats));
    } catch (e) {
      final String msg = e.toString().replaceAll('Exception: ', '');
      emit(DashboardFailure(msg));
    }
  }
}
