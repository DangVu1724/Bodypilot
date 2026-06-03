import 'package:flutter/material.dart';
import 'package:mobile/core/routes/app_pages.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/presentation/bloc/food/food_cubit.dart';
import 'package:mobile/data/repositories/food_repository.dart';
import 'package:mobile/data/repositories/workout_repository.dart';
import 'package:mobile/data/repositories/exercise_repository.dart';
import 'package:mobile/presentation/bloc/workout/workout_plan_cubit.dart';
import 'package:mobile/presentation/bloc/workout/exercise_cubit.dart';
import 'package:mobile/presentation/bloc/workout/workout_category_cubit.dart';
import 'package:mobile/presentation/bloc/meal/meal_cubit.dart';
import 'package:mobile/data/repositories/nutrition_diary_repository.dart';


import 'package:hive_flutter/hive_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('assessment_box');
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
        BlocProvider(create: (context) => FoodCubit(foodRepository)..init()),
        BlocProvider(create: (context) => WorkoutPlanCubit(workoutRepository)..fetchPlansFull()),
        BlocProvider(create: (context) => ExerciseCubit(exerciseRepository)..fetchStrengthExercises()),
        BlocProvider(create: (context) => WorkoutCategoryCubit(exerciseRepository)..fetchCategories()),
        BlocProvider(create: (context) => MealCubit(nutritionDiaryRepository)),

      ],
      child: MaterialApp(
        title: 'BodyPilot',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppPages.onGenerateRoute,
      ),
    );
  }
}
