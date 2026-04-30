import 'dart:async';

import 'package:flutter/material.dart';
import '../models/routine_task.dart';
import '../repositories/routine_repository.dart';
import '../repositories/metrics_repository.dart';
import '../services/time_service.dart';

class FocusRoutineScreen extends StatefulWidget {
  final String routineType;
  final RoutineRepository routineRepository;
  final MetricsRepository metricsRepository;
  final TimeService timeService;
  final Color accentColor;
  final List<RoutineTask> uncompletedTasks;

  const FocusRoutineScreen({
    super.key,
    required this.routineType,
    required this.routineRepository,
    required this.metricsRepository,
    required this.timeService,
    required this.accentColor,
    required this.uncompletedTasks,
  });

  @override
  State<FocusRoutineScreen> createState() => _FocusRoutineScreenState();
}

class _FocusRoutineScreenState extends State<FocusRoutineScreen> {
  int _currentIndex = 0;
  int _secondsElapsed = 0;
  Timer? _timer;
  late DateTime _routineStartTime;
  final Map<String, int> _taskDurations = {};

  @override
  void initState() {
    super.initState();
    _routineStartTime = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  Future<void> _completeCurrentTask() async {
    _timer?.cancel();
    
    final task = widget.uncompletedTasks[_currentIndex];
    final actualSeconds = _secondsElapsed;
    
    // Track duration for metrics
    _taskDurations[task.id] = actualSeconds;
    
    // Update target duration formula
    int newTarget;
    if (task.targetDuration <= 0) {
      newTarget = actualSeconds;
    } else {
      newTarget = (task.targetDuration * 0.7 + actualSeconds * 0.3).round();
    }
    
    // Prevent target from being 0 accidentally
    if (newTarget < 5) newTarget = 5;

    // Load full list of tasks to update and save
    final allTasks = widget.routineType == 'morning'
        ? widget.routineRepository.loadMorningTasks()
        : widget.routineRepository.loadNightTasks();
        
    final taskIndex = allTasks.indexWhere((t) => t.id == task.id);
    if (taskIndex != -1) {
      allTasks[taskIndex].previousTargetDuration = allTasks[taskIndex].targetDuration;
      allTasks[taskIndex].targetDuration = newTarget;
      allTasks[taskIndex].lastFocusDuration = actualSeconds;
      if (widget.routineType == 'morning') {
        await widget.routineRepository.saveMorningTasks(allTasks);
      } else {
        await widget.routineRepository.saveNightTasks(allTasks);
      }
    }

    // Mark as completed for today
    final state = widget.routineRepository.loadCompletionState(widget.routineType);
    state[task.id] = true;
    await widget.routineRepository.saveCompletionState(widget.routineType, state);

    // Move to next task or finish
    if (_currentIndex < widget.uncompletedTasks.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startTimer();
    } else {
      // Finished all tasks!
      await widget.metricsRepository.saveRoutineMetrics(
        widget.routineType, 
        widget.timeService.getEffectiveDateString(),
        _routineStartTime, 
        DateTime.now(), 
        _taskDurations,
      );
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to signal full completion
      }
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uncompletedTasks.isEmpty) {
      return const Scaffold(body: Center(child: Text('No tasks remaining!')));
    }

    final task = widget.uncompletedTasks[_currentIndex];
    final target = task.targetDuration;
    final isCountUp = target <= 0;
    
    final isOvertime = !isCountUp && _secondsElapsed > target;
    
    Color timerColor = widget.accentColor;
    if (isOvertime) {
      timerColor = Colors.deepOrangeAccent;
    }

    double progress = 0.0;
    String displayTime = '';

    if (isCountUp) {
      progress = (_secondsElapsed % 60) / 60.0; // Sweeping second hand effect
      displayTime = _formatTime(_secondsElapsed);
    } else {
      if (isOvertime) {
        final overtimeSecs = _secondsElapsed - target;
        progress = 1.0;
        displayTime = '+${_formatTime(overtimeSecs)}';
      } else {
        final remaining = target - _secondsElapsed;
        progress = remaining / target;
        displayTime = _formatTime(remaining);
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  ),
                  Text(
                    'Task ${_currentIndex + 1} of ${widget.uncompletedTasks.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance close button
                ],
              ),
            ),
            
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.emoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        task.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Timer Ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            backgroundColor: timerColor.withAlpha(30),
                            color: timerColor,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayTime,
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w300,
                                fontFeatures: const [FontFeature.tabularFigures()],
                                color: timerColor,
                              ),
                            ),
                            if (!isCountUp) ...[
                              const SizedBox(height: 4),
                              Text(
                                isOvertime ? 'Overtime' : 'Remaining',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: timerColor.withAlpha(200),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              Text(
                                'Gathering data',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: timerColor.withAlpha(200),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Done Button
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _completeCurrentTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: timerColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
