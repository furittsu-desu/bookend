import 'package:flutter/material.dart';
import '../models/routine_task.dart';
import '../services/storage_service.dart';
import '../repositories/routine_repository.dart';
import '../repositories/metrics_repository.dart';
import '../widgets/animated_task_tile.dart';
import '../widgets/progress_ring.dart';
import '../widgets/completion_celebration.dart';
import '../widgets/journal_prompt.dart';
import 'edit_routine_screen.dart';
import 'insights_screen.dart';
import 'focus_routine_screen.dart';
import 'settings_screen.dart';

class RoutineScreen extends StatefulWidget {
  final String routineType; // 'morning' or 'night'
  final BaseStorage storage;
  final RoutineRepository routineRepository;
  final MetricsRepository metricsRepository;
  final Color accentColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final IconData icon;

  const RoutineScreen({
    super.key,
    required this.routineType,
    required this.storage,
    required this.routineRepository,
    required this.metricsRepository,
    required this.accentColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  State<RoutineScreen> createState() => RoutineScreenState();
}

class RoutineScreenState extends State<RoutineScreen> {
  List<RoutineTask> _tasks = [];
  bool _allCompleted = false;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void reload() {
    _loadTasks();
  }

  void _loadTasks() {
    final tasks = widget.routineType == 'morning'
        ? widget.routineRepository.loadMorningTasks()
        : widget.routineRepository.loadNightTasks();

    // Restore today's completion state
    final completionState =
        widget.routineRepository.loadCompletionState(widget.routineType);
    for (final task in tasks) {
      task.isCompleted = completionState[task.id] ?? false;
    }

    setState(() {
      _tasks = tasks;
      _allCompleted =
          _tasks.isNotEmpty && _tasks.every((t) => t.isCompleted);
    });
  }

  void _toggleTask(int index, bool value) {
    setState(() {
      final task = _tasks[index];
      task.isCompleted = value;
      
      // Handle Metrics & Undo for task durations
      final today = widget.routineRepository.timeService.getEffectiveDateString();
      if (!value) {
        // Unchecked: remove from metrics so it's not double counted if completed again later
        widget.metricsRepository.removeTaskFromMetrics(widget.routineType, today, task.id);

        // Undo target duration if accidentally completed in Focus Mode
        if (task.previousTargetDuration != task.targetDuration) {
          task.targetDuration = task.previousTargetDuration;
          if (widget.routineType == 'morning') {
            widget.routineRepository.saveMorningTasks(_tasks);
          } else {
            widget.routineRepository.saveNightTasks(_tasks);
          }
        }
      } else {
        // Checked manually: if we have a lastFocusDuration, restore it to metrics
        if (task.lastFocusDuration != null) {
          widget.metricsRepository.addTaskToMetrics(widget.routineType, today, task.id, task.lastFocusDuration!);
        }
      }

      final wasAllCompleted = _allCompleted;
      _allCompleted =
          _tasks.isNotEmpty && _tasks.every((t) => t.isCompleted);

      // Trigger celebration only on first completion of all tasks
      if (_allCompleted && !wasAllCompleted) {
        _triggerCelebration();
      } else if (wasAllCompleted && !_allCompleted) {
        final today = widget.routineRepository.timeService.getEffectiveDateString();
        widget.routineRepository.removeStreakForToday(widget.routineType, today).then((_) {
          if (mounted) setState(() {});
        });
      }
    });

    // Persist completion state
    final state = {
      for (final t in _tasks) t.id: t.isCompleted,
    };
    widget.routineRepository.saveCompletionState(widget.routineType, state);
  }

  void _triggerCelebration() {
    _showCelebration = true;

    // Streak logic
    final today = widget.routineRepository.timeService.getEffectiveDateString();
    
    if (widget.routineRepository.getLastStreakDate(widget.routineType) != today) {
      widget.routineRepository.incrementStreak(widget.routineType, today).then((_) {
        if (mounted) setState(() {});
      });
    }

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showCelebration = false);
      
      if (widget.routineType == 'night' && mounted) {
        _showJournalPrompt(today);
      }
    });
  }

  void _showJournalPrompt(String date) {
    if (widget.routineRepository.loadJournalEntry(date) != null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JournalPromptBottomSheet(
        accentColor: widget.accentColor,
        onSave: (text) {
          widget.routineRepository.saveJournalEntry(date, text);
        },
      ),
    );
  }

  void _openEditScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditRoutineScreen(
          routineType: widget.routineType,
          routineRepository: widget.routineRepository,
          accentColor: widget.accentColor,
        ),
      ),
    );
    _loadTasks(); // Reload after editing
  }

  void _openInsights() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InsightsScreen(
          metricsRepository: widget.metricsRepository,
          routineRepository: widget.routineRepository,
          accentColor: widget.accentColor,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          storage: widget.storage,
          accentColor: widget.accentColor,
        ),
      ),
    );
  }

  void _startFocusMode() async {
    final uncompleted = _tasks.where((t) => !t.isCompleted).toList();
    if (uncompleted.isEmpty) return;

    final didCompleteAll = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusRoutineScreen(
          routineType: widget.routineType,
          routineRepository: widget.routineRepository,
          metricsRepository: widget.metricsRepository,
          timeService: widget.routineRepository.timeService,
          accentColor: widget.accentColor,
          uncompletedTasks: uncompleted,
        ),
      ),
    );

    final wasAllCompleted = _allCompleted;
    _loadTasks();

    if (didCompleteAll == true && !wasAllCompleted) {
      _triggerCelebration();
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _tasks.where((t) => t.isCompleted).length;

    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.backgroundColor,
                widget.backgroundColor.withAlpha(230),
                Theme.of(context).scaffoldBackgroundColor,
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.accentColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: _openSettings,
                      icon: Icon(
                        Icons.settings_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(180),
                      ),
                      tooltip: 'Settings',
                    ),
                    IconButton(
                      onPressed: _openEditScreen,
                      icon: Icon(
                        Icons.tune_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(180),
                      ),
                      tooltip: 'Edit routine',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Progress ring
              ProgressRing(
                completed: completed,
                total: _tasks.length,
                color: widget.accentColor,
                backgroundColor:
                    widget.accentColor.withAlpha(30),
              ),
              const SizedBox(height: 8),
              if (widget.routineRepository.getStreak(widget.routineType) > 0) ...[
                Text(
                  '🔥 ${widget.routineRepository.getStreak(widget.routineType)} Day Streak',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              // Status text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _allCompleted
                      ? '✨ All done! Great job!'
                      : '$completed of ${_tasks.length} completed',
                  key: ValueKey(_allCompleted),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _allCompleted
                        ? widget.accentColor
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(150),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Task list
              Expanded(
                child: _tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_task_rounded,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(60),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No tasks yet.\nTap the tune icon to add some!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(100),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 40),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          return AnimatedTaskTile(
                            key: ValueKey(_tasks[index].id),
                            task: _tasks[index],
                            accentColor: widget.accentColor,
                            onToggle: (val) => _toggleTask(index, val),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // Celebration overlay
        Positioned.fill(
          child: CompletionCelebration(
            show: _showCelebration,
            color: widget.accentColor,
          ),
        ),
        // FAB for Insights (Night routine only)
        if (widget.routineType == 'night')
          Positioned(
            bottom: 56,
            right: 24,
            child: FloatingActionButton(
              heroTag: 'insights_fab',
              onPressed: _openInsights,
              backgroundColor: widget.accentColor,
              child: const Icon(Icons.auto_stories_rounded, color: Colors.white),
            ),
          ),
        // FAB for Start Focus Mode
        if (!_allCompleted && _tasks.isNotEmpty)
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                heroTag: 'play_${widget.routineType}',
                onPressed: _startFocusMode,
                backgroundColor: widget.accentColor,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('Focus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  }
}
