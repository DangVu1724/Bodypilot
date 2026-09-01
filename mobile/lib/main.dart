import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:mobile/core/network/network_connectivity_service.dart';
import 'package:mobile/core/routes/app_pages.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/repositories/exercise_repository.dart';
import 'package:mobile/data/repositories/food_repository.dart';
import 'package:mobile/data/repositories/nutrition_diary_repository.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/repositories/workout_diary_repository.dart';
import 'package:mobile/data/repositories/workout_repository.dart';
import 'package:mobile/data/services/push_notification_service.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/presentation/bloc/checkin/checkin_cubit.dart';
import 'package:mobile/presentation/bloc/food/food_cubit.dart';
import 'package:mobile/presentation/bloc/meal/meal_cubit.dart';
import 'package:mobile/presentation/bloc/notification/notification_cubit.dart';
import 'package:mobile/presentation/bloc/step/step_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/workout/exercise_cubit.dart';
import 'package:mobile/presentation/bloc/workout/workout_category_cubit.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_cubit.dart';
import 'package:mobile/presentation/bloc/workout/workout_plan_cubit.dart';
import 'package:mobile/presentation/widgets/offline_banner_widget.dart';

final _logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    PushNotificationService.init().catchError((e) {
      _logger.e("PushNotificationService init error: $e");
    });
  } catch (e) {
    _logger.e("Firebase initialization failed: $e");
  }
  await Hive.initFlutter();
  await Hive.openBox('assessment_box');
  await Hive.openBox('notification_box');
  networkConnectivityService.init();
  await TokenService.init();
  runApp(const BodyPilotApp());
}

class BodyPilotApp extends StatelessWidget {
  const BodyPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => UserCubit(userRepository)..fetchUserProfile()),
        BlocProvider(create: (context) => CheckInCubit(userRepository)..fetchCheckInStatus()),
        BlocProvider(create: (context) => FoodCubit(foodRepository)..init()),

        BlocProvider(create: (context) => WorkoutPlanCubit(workoutRepository)..fetchPlansFull()),
        BlocProvider(create: (context) => ExerciseCubit(exerciseRepository)..fetchStrengthExercises()),
        BlocProvider(create: (context) => WorkoutCategoryCubit(exerciseRepository)..fetchCategories()),
        BlocProvider(create: (context) => MealCubit(nutritionDiaryRepository)),
        BlocProvider(create: (context) => WorkoutDiaryCubit(workoutDiaryRepository)),
        BlocProvider(create: (context) => NotificationCubit()),
        BlocProvider(create: (context) => StepCubit()),
      ],
      child: MaterialApp.router(
        title: 'BodyPilot',
        routerConfig: AppPages.router,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        builder: (context, child) {
          return OfflineBannerWidget(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}
