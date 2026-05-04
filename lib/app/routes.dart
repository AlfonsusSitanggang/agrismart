import 'package:agrismart/features/chatbot/pages/chatbot_page.dart';
import 'package:agrismart/features/location/pages/location_page.dart';
import 'package:agrismart/features/minigame/pages/minigame_page.dart';
import 'package:agrismart/features/plants/pages/plants_page.dart';
import 'package:agrismart/features/schedules/pages/schedules_page.dart';
import 'package:agrismart/features/timezone/pages/timezone_page.dart';
import 'package:agrismart/features/weather/pages/weather_page.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/pages/splash_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/home/pages/home_page.dart';
import 'package:agrismart/features/plants/pages/plant_catalog_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/timezone',
      builder: (context, state) => const TimezonePage(),
    ),

    GoRoute(
      path: '/minigame',
      builder: (context, state) => const MinigamePage(),
    ),
    GoRoute(path: '/weather', builder: (context, state) => const WeatherPage()),
    GoRoute(path: '/plants', builder: (context, state) => const PlantsPage()),
    GoRoute(
      path: '/schedules',
      builder: (context, state) => const SchedulesPage(),
    ),
    GoRoute(path: '/chatbot', builder: (context, state) => const ChatbotPage()),
    GoRoute(
      path: '/plant-catalog',
      builder: (context, state) => const PlantCatalogPage(),
    ),
  ],
);
