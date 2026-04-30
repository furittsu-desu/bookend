import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../repositories/routine_repository.dart';
import '../repositories/metrics_repository.dart';
import 'routine_screen.dart';

/// Enables mouse-drag scrolling on desktop for PageView.
class _DesktopDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
      };
}

class HomeScreen extends StatefulWidget {
  final BaseStorage storage;
  final RoutineRepository routineRepository;
  final MetricsRepository metricsRepository;

  const HomeScreen({
    super.key,
    required this.storage,
    required this.routineRepository,
    required this.metricsRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _pageValue = 0.0;

  // Morning palette
  static const _morningAccent = Color(0xFFE8A838);
  static const _morningBg = Color(0xFFFFF3E0);

  // Night palette
  static const _nightAccent = Color(0xFF6C63FF);
  static const _nightBg = Color(0xFF1A1A2E);

  final _morningKey = GlobalKey<RoutineScreenState>();
  final _nightKey = GlobalKey<RoutineScreenState>();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (_pageController.hasClients && _pageController.page != null) {
      setState(() {
        _pageValue = _pageController.page!;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Color.lerp(
      _morningBg,
      _nightBg,
      _pageValue.clamp(0.0, 1.0),
    )!;

    return Theme(
      data: _pageValue > 0.5
          ? _nightTheme(context)
          : _morningTheme(context),
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            ScrollConfiguration(
              behavior: _DesktopDragScrollBehavior(),
              child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                // Reload tasks when swiping back to a page
                if (index == 0) {
                  _morningKey.currentState?.reload();
                } else {
                  _nightKey.currentState?.reload();
                }
              },
              children: [
                RoutineScreen(
                  key: _morningKey,
                  routineType: 'morning',
                  storage: widget.storage,
                  routineRepository: widget.routineRepository,
                  metricsRepository: widget.metricsRepository,
                  accentColor: _morningAccent,
                  backgroundColor: _morningBg,
                  title: 'Good Morning',
                  subtitle: 'Start your day right',
                  icon: Icons.wb_sunny_rounded,
                ),
                RoutineScreen(
                  key: _nightKey,
                  routineType: 'night',
                  storage: widget.storage,
                  routineRepository: widget.routineRepository,
                  metricsRepository: widget.metricsRepository,
                  accentColor: _nightAccent,
                  backgroundColor: _nightBg,
                  title: 'Good Night',
                  subtitle: 'Wind down peacefully',
                  icon: Icons.nightlight_round,
                ),
              ],
            ),
            ),
            // Page indicator
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(0, _morningAccent),
                  const SizedBox(width: 8),
                  _buildDot(1, _nightAccent),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index, Color color) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive ? color : color.withAlpha(80),
      ),
    );
  }

  ThemeData _morningTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: _morningAccent,
      scaffoldBackgroundColor: _morningBg,
    );
  }

  ThemeData _nightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: _nightAccent,
      scaffoldBackgroundColor: _nightBg,
    );
  }
}
