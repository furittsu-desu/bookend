import 'package:flutter/material.dart';
import '../models/routine_task.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final StorageService storage;

  const OnboardingScreen({super.key, required this.storage});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<RoutineTask> _morningTasks = [];
  final List<RoutineTask> _nightTasks = [];

  final TextEditingController _taskController = TextEditingController();
  String _selectedEmoji = '✨';

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    await widget.storage.saveMorningTasks(_morningTasks);
    await widget.storage.saveNightTasks(_nightTasks);
    await widget.storage.completeOnboarding();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(storage: widget.storage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildWelcomeSlide(),
                  _buildFocusModeSlide(),
                  _buildMorningSetupSlide(),
                  _buildNightSetupSlide(),
                  _buildReadySlide(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSlide() {
    return _OnboardingSlide(
      title: 'Welcome to Bookend',
      subtitle: 'Master your mornings and evenings with focused routines.',
      icon: Icons.auto_stories_rounded,
      iconColor: const Color(0xFF6C63FF),
    );
  }

  Widget _buildFocusModeSlide() {
    return _OnboardingSlide(
      title: 'The Focus Engine',
      subtitle: 'The app automatically learns how long you take for each task and updates your timers daily.',
      icon: Icons.timer_rounded,
      iconColor: const Color(0xFFE8A838),
    );
  }

  Widget _buildMorningSetupSlide() {
    return _buildRoutineSetup(
      title: 'Your Morning',
      subtitle: 'What helps you start your day right?',
      tasks: _morningTasks,
      suggestions: StorageService.defaultMorningTasks,
      accentColor: const Color(0xFFE8A838),
    );
  }

  Widget _buildNightSetupSlide() {
    return _buildRoutineSetup(
      title: 'Your Evening',
      subtitle: 'How do you prefer to wind down?',
      tasks: _nightTasks,
      suggestions: StorageService.defaultNightTasks,
      accentColor: const Color(0xFF6C63FF),
    );
  }

  Widget _buildRoutineSetup({
    required String title,
    required String subtitle,
    required List<RoutineTask> tasks,
    required List<RoutineTask> suggestions,
    required Color accentColor,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 24),
          
          // Suggestions
          if (suggestions.any((s) => !tasks.any((t) => t.title == s.title))) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('SUGGESTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .where((s) => !tasks.any((t) => t.title == s.title))
                  .map((s) => ActionChip(
                        avatar: Text(s.emoji),
                        label: Text(s.title),
                        onPressed: () => setState(() => tasks.add(s)),
                        backgroundColor: accentColor.withAlpha(20),
                        side: BorderSide(color: accentColor.withAlpha(50)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('YOUR ROUTINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Add your first task below', style: TextStyle(color: Colors.grey[400]))),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Text(task.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(task.title),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => setState(() => tasks.removeAt(index)),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          _buildCustomTaskInput(tasks, accentColor),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCustomTaskInput(List<RoutineTask> tasks, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              '✨', '☀️', '🪥', '📖', '🧘', '☕', '🚿', '📓', '💊', '🍳', '🏃', 
              '💦', '🌙', '🛌', '📵', '🥛', '📝', '🧹', '🚶', '🎧', '🛀'
            ].map((e) => GestureDetector(
              onTap: () => setState(() => _selectedEmoji = e),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: _selectedEmoji == e ? Border(bottom: BorderSide(color: accentColor, width: 2)) : null,
                ),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _taskController,
                decoration: InputDecoration(
                  hintText: 'Add custom task...',
                  hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(_selectedEmoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      tasks.add(RoutineTask(title: val.trim(), emoji: _selectedEmoji));
                      _taskController.clear();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: accentColor,
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  if (_taskController.text.trim().isNotEmpty) {
                    setState(() {
                      tasks.add(RoutineTask(title: _taskController.text.trim(), emoji: _selectedEmoji));
                      _taskController.clear();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadySlide() {
    return const _OnboardingSlide(
      title: 'You\'re All Set!',
      subtitle: 'Consistency is the key to mastering your routine. Let\'s get started.',
      icon: Icons.check_circle_outline_rounded,
      iconColor: Colors.green,
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots
          Row(
            children: List.generate(
              5,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Colors.black : Colors.black.withAlpha(50),
                ),
              ),
            ),
          ),
          
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(_currentPage == 4 ? 'GET STARTED' : 'NEXT'),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: iconColor),
          const SizedBox(height: 48),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey[600], height: 1.5)),
        ],
      ),
    );
  }
}
