import 'package:agrismart/features/auth/pages/login_page.dart';
import 'package:agrismart/features/auth/pages/register_page.dart';
import 'package:agrismart/features/chatbot/pages/chatbot_page.dart';
import 'package:agrismart/features/minigame/pages/minigame_page.dart';
import 'package:agrismart/features/navigation/main_navigation_page.dart';
import 'package:agrismart/features/plants/pages/plant_catalog_page.dart';
import 'package:agrismart/features/plants/pages/plants_page.dart';
import 'package:agrismart/features/profile/pages/profile_page.dart';
import 'package:agrismart/features/schedules/pages/schedules_page.dart';
import 'package:agrismart/features/splash/pages/splash_page.dart';
import 'package:agrismart/features/timezone/pages/timezone_page.dart';
import 'package:agrismart/features/weather/pages/weather_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    GoRoute(
      path: '/main',
      builder: (context, state) => const MainNavigationPage(),
    ),

    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationPage(initialIndex: 0),
    ),
    GoRoute(
      path: '/plants',
      builder: (context, state) => const MainNavigationPage(initialIndex: 1),
    ),
    GoRoute(
      path: '/schedules',
      builder: (context, state) => const MainNavigationPage(initialIndex: 2),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MainNavigationPage(initialIndex: 3),
    ),

    GoRoute(path: '/weather', builder: (context, state) => const WeatherPage()),
    GoRoute(
      path: '/timezone',
      builder: (context, state) => const TimezonePage(),
    ),
    GoRoute(
      path: '/minigame',
      builder: (context, state) => const MinigamePage(),
    ),
    GoRoute(path: '/chatbot', builder: (context, state) => const ChatbotPage()),
    GoRoute(
      path: '/plant-catalog',
      builder: (context, state) => const PlantCatalogPage(),
    ),

    GoRoute(
      path: '/plants-page',
      builder: (context, state) => const PlantsPage(),
    ),
    GoRoute(
      path: '/schedules-page',
      builder: (context, state) => const SchedulesPage(),
    ),
    GoRoute(
      path: '/profile-page',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);
