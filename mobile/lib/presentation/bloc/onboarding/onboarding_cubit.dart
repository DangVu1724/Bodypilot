import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingPage {
  final String image;
  final String title;
  final String description;

  const OnboardingPage({required this.image, required this.title, required this.description});
}

class OnboardingCubit extends Cubit<int> {
  OnboardingCubit() : super(0);

  static const List<OnboardingPage> pages = [
    OnboardingPage(
      image: 'assets/images/gym_workout.png',
      title: 'Kế hoạch Tập luyện Cá nhân',
      description: 'Nhận các giáo án tập luyện được thiết kế riêng phù hợp hoàn toàn với thể trạng và mục tiêu của bạn.',
    ),
    OnboardingPage(
      image: 'assets/images/fruit.png',
      title: 'Chế độ Dinh dưỡng Thông minh',
      description: 'Theo dõi bữa ăn hàng ngày dễ dàng và nhận các gợi ý thực đơn lành mạnh từ trợ lý dinh dưỡng AI.',
    ),
    OnboardingPage(
      image: 'assets/images/ai_coach.png',
      title: 'Huấn luyện viên AI 24/7',
      description: 'Nhận phản hồi tức thì và các phân tích thể trạng thông minh dựa trên trí tuệ nhân tạo.',
    ),
    OnboardingPage(
      image: 'assets/images/heart.png',
      title: 'Theo dõi Tiến trình Trực quan',
      description: 'Giám sát hành trình cải thiện vóc dáng và các chỉ số cơ thể của bạn qua biểu đồ chi tiết.',
    ),
    OnboardingPage(
      image: 'assets/images/equipments.png',
      title: 'Cộng đồng BodyPilot',
      description: 'Kết nối với những người bạn có cùng mục tiêu luyện tập và cùng nhau duy trì động lực mỗi ngày.',
    ),
  ];

  void nextPage() {
    if (state < pages.length - 1) emit(state + 1);
  }

  void previousPage() {
    if (state > 0) emit(state - 1);
  }

  void goToPage(int index) {
    if (index >= 0 && index < pages.length) emit(index);
  }
}
