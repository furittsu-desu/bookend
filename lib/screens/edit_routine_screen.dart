import 'package:flutter/material.dart';
import '../models/routine_task.dart';
import '../repositories/routine_repository.dart';
import '../repositories/metrics_repository.dart';

class EditRoutineScreen extends StatefulWidget {
  final String routineType;
  final RoutineRepository routineRepository;
  final MetricsRepository metricsRepository;
  final Color accentColor;

  const EditRoutineScreen({
    super.key,
    required this.routineType,
    required this.routineRepository,
    required this.metricsRepository,
    required this.accentColor,
  });

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  List<RoutineTask> _tasks = [];
  String? _startTime;

  @override
  void initState() {
    super.initState();
    _tasks = widget.routineType == 'morning'
        ? widget.routineRepository.loadMorningTasks()
        : widget.routineRepository.loadNightTasks();
    _startTime = widget.routineRepository.getRoutineStartTime(widget.routineType);
  }

  Future<void> _save() async {
    if (widget.routineType == 'morning') {
      await widget.routineRepository.saveMorningTasks(_tasks);
    } else {
      await widget.routineRepository.saveNightTasks(_tasks);
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay initialTime = TimeOfDay.now();
    if (_startTime != null) {
      final parts = _startTime!.split(':');
      if (parts.length == 2) {
        initialTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: widget.accentColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeIso = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _updateStartTime(timeIso);
    }
  }

  Future<void> _updateStartTime(String timeIso) async {
    await widget.routineRepository.saveRoutineStartTime(widget.routineType, timeIso);
    setState(() {
      _startTime = timeIso;
    });
  }

  void _deleteTask(int index) {
    final removed = _tasks[index];
    setState(() => _tasks.removeAt(index));
    _save();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${removed.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _tasks.insert(index, removed));
            _save();
          },
        ),
      ),
    );
  }

  void _showTaskDialog({RoutineTask? task, int? index}) {
    final isEditing = task != null && index != null;
    final titleController = TextEditingController(text: task?.title ?? '');
    final emojiController = TextEditingController(text: task?.emoji ?? '');
    final durationController = TextEditingController(text: (task?.targetDuration ?? 0).toString());
    
    int initialTotalSecs = task?.targetDuration ?? 0;
    final minController = TextEditingController(text: (initialTotalSecs ~/ 60).toString().padLeft(2, '0'));
    final secController = TextEditingController(text: (initialTotalSecs % 60).toString().padLeft(2, '0'));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'Edit Task' : 'Add Task'),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select Emoji', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          '☀️', '🪥', '📖', '🧘', '☕', '🚿', '📓', '💊', '🍳', '🏃', 
                          '💦', '🌙', '🛌', '📵', '🥛', '📝', '🧹', '🚶', '🎧', '🛀'
                        ].map((e) => Semantics(
                          button: true,
                          label: 'Select emoji $e',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => emojiController.text = e,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(e, style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('task_emoji_field'),
                    controller: emojiController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Emoji',
                      hintText: 'Tap to type any emoji',
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('task_title_field'),
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task name',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  const Text('Target Duration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        child: TextField(
                          key: const ValueKey('task_min_field'),
                          controller: minController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                          decoration: const InputDecoration(
                            labelText: 'Min',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (_) {
                            final m = int.tryParse(minController.text) ?? 0;
                            final s = int.tryParse(secController.text) ?? 0;
                            durationController.text = (m * 60 + s).toString();
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(
                        width: 70,
                        child: TextField(
                          key: const ValueKey('task_sec_field'),
                          controller: secController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                          decoration: const InputDecoration(
                            labelText: 'Sec',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (_) {
                            final m = int.tryParse(minController.text) ?? 0;
                            final s = int.tryParse(secController.text) ?? 0;
                            durationController.text = (m * 60 + s).toString();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('00:00 = auto-learning', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                setState(() {
                  final newTask = RoutineTask(
                    title: title,
                    emoji: emojiController.text.trim().isEmpty ? '✨' : emojiController.text.trim(),
                    targetDuration: int.tryParse(durationController.text) ?? 0,
                  );
                  if (isEditing) {
                    _tasks[index] = newTask;
                  } else {
                    _tasks.add(newTask);
                  }
                });
                _save();
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(backgroundColor: widget.accentColor),
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMorning = widget.routineType == 'morning';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMorning ? 'Edit Morning Routine' : 'Edit Night Routine',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _tasks.isEmpty
            ? ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildScheduleSection(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('TASKS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                  ),
                  const Center(child: Text('No tasks. Tap + to add one.')),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildScheduleSection(),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text('TASKS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                    ),
                  ),
                  SliverReorderableList(
                    itemCount: _tasks.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _tasks.removeAt(oldIndex);
                        _tasks.insert(newIndex, item);
                      });
                      _save();
                    },
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return _buildTaskTile(task, index);
                    },
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        backgroundColor: widget.accentColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
  Widget _buildScheduleSection() {
    final avgStart = widget.metricsRepository.getAverageStartTime(widget.routineType);
    final avgStartStr = avgStart != null 
        ? '${avgStart.hour.toString().padLeft(2, '0')}:${avgStart.minute.toString().padLeft(2, '0')}'
        : null;
    final score = widget.metricsRepository.getConsistencyScore(widget.routineType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('SCHEDULE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
            ),
            if (score > 0)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('Consistency: $score%', style: TextStyle(fontSize: 12, color: widget.accentColor, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: Icon(Icons.notifications_active_rounded, color: widget.accentColor),
            title: const Text('Nudge Start Time', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(_startTime ?? 'Not scheduled'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _pickTime,
          ),
        ),
        if (avgStartStr != null && avgStartStr != _startTime)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: widget.accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You usually start at $avgStartStr. Sync?',
                    style: TextStyle(fontSize: 12, color: widget.accentColor.withOpacity(0.8), fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed: () => _updateStartTime(avgStartStr),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('Sync'),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              'We\'ll nudge you if you haven\'t started your routine by this time.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTaskTile(RoutineTask task, int index) {
    return Card(
      key: ValueKey(task.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Text(
          task.emoji.isEmpty ? '📋' : task.emoji,
          style: const TextStyle(fontSize: 22),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: task.targetDuration > 0
            ? Text('${task.targetDuration}s target')
            : const Text('Auto-learning mode'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              onPressed: () => _showTaskDialog(task: task, index: index),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  size: 20, color: Colors.red.shade300),
              onPressed: () => _deleteTask(index),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
