import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/storage_service.dart';
import 'repositories/routine_repository.dart';
import 'repositories/metrics_repository.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  final routineRepository = RoutineRepository(storage.prefs, storage.timeService);
  final metricsRepository = MetricsRepository(storage.prefs);

  runApp(BookendApp(
    storage: storage,
    routineRepository: routineRepository,
    metricsRepository: metricsRepository,
  ));
}

class BookendApp extends StatelessWidget {
  final StorageService storage;
  final RoutineRepository routineRepository;
  final MetricsRepository metricsRepository;

  const BookendApp({
    super.key,
    required this.storage,
    required this.routineRepository,
    required this.metricsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookend',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US')],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFFE8A838),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.light).textTheme,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6C63FF),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      home: !routineRepository.isOnboardingCompleted()
          ? OnboardingScreen(
              storage: storage,
              routineRepository: routineRepository,
              metricsRepository: metricsRepository,
            )
          : HomeScreen(
              storage: storage,
              routineRepository: routineRepository,
              metricsRepository: metricsRepository,
            ),
    );
  }
}
