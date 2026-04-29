import 'package:flutter/material.dart';
import '../models/routine_task.dart';
import '../services/storage_service.dart';

class EditRoutineScreen extends StatefulWidget {
  final String routineType;
  final StorageService storage;
  final Color accentColor;

  const EditRoutineScreen({
    super.key,
    required this.routineType,
    required this.storage,
    required this.accentColor,
  });

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  List<RoutineTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _tasks = widget.routineType == 'morning'
        ? widget.storage.loadMorningTasks()
        : widget.storage.loadNightTasks();
  }

  Future<void> _save() async {
    if (widget.routineType == 'morning') {
      await widget.storage.saveMorningTasks(_tasks);
    } else {
      await widget.storage.saveNightTasks(_tasks);
    }
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
    
    // Persistent controllers for the duration fields to prevent focus loss on rebuild
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
            width: 300, // Fixed width to avoid IntrinsicWidth layout issues in AlertDialog
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
                        ].map((e) => GestureDetector(
                          onTap: () => emojiController.text = e,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(e, style: const TextStyle(fontSize: 24)),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
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
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.playlist_add_rounded,
                    size: 56,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(60),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tasks. Tap + to add one.',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(120),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                return Card(
                  key: ValueKey(task.id),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        backgroundColor: widget.accentColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
