import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

class InsightsScreen extends StatefulWidget {
  final StorageService storage;
  final Color accentColor;

  const InsightsScreen({
    super.key,
    required this.storage,
    required this.accentColor,
  });

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  void _deleteEntry(String date) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this journal entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storage.deleteJournalEntry(date);
      setState(() {});
    }
  }

  void _editEntry(String date, String currentText) async {
    final controller = TextEditingController(text: currentText);
    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Entry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newText != null && newText.isNotEmpty && newText != currentText) {
      await widget.storage.saveJournalEntry(date, newText);
      setState(() {});
    }
  }

  Widget _buildAverages(Map<String, Map<String, dynamic>> metrics) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    int morningTotal = 0, morningCount = 0;
    int nightTotal = 0, nightCount = 0;

    metrics.forEach((key, data) {
      try {
        int diff = 0;
        if (data.containsKey('taskDurations')) {
          final tasksMap = data['taskDurations'] as Map<String, dynamic>;
          for (final duration in tasksMap.values) {
            diff += duration as int;
          }
        } else {
          // Fallback if taskDurations doesn't exist
          final start = DateTime.parse(data['startTime'] as String);
          final end = DateTime.parse(data['endTime'] as String);
          diff = end.difference(start).inSeconds;
        }

        if (diff > 0 && diff < 86400) {
          if (key.startsWith('metrics_morning')) {
            morningTotal += diff;
            morningCount++;
          } else if (key.startsWith('metrics_night')) {
            nightTotal += diff;
            nightCount++;
          }
        }
      } catch (_) {}
    });

    String formatAvg(int total, int count) {
      if (count == 0) return '--';
      final avg = (total / count).round();
      final m = avg ~/ 60;
      final s = avg % 60;
      if (m == 0) return '${s}s';
      return '${m}m ${s}s';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average Focus Time',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricsCard(
                title: 'Morning',
                value: formatAvg(morningTotal, morningCount),
                accentColor: const Color(0xFFE8A838),
                icon: Icons.wb_sunny_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricsCard(
                title: 'Night',
                value: formatAvg(nightTotal, nightCount),
                accentColor: const Color(0xFF6C63FF),
                icon: Icons.nights_stay_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTimeline(Map<String, Map<String, dynamic>> metrics) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    final Map<String, Map<String, DateTime?>> timeline = {};
    metrics.forEach((key, data) {
      try {
        final start = DateTime.parse(data['startTime'] as String);
        final parts = key.split('_'); 
        if (parts.length >= 3) {
          final type = parts[1];
          final date = parts.sublist(2).join('_');
          
          if (!timeline.containsKey(date)) {
            timeline[date] = {'morning': null, 'night': null};
          }
          timeline[date]![type] = start;
        }
      } catch (_) {}
    });

    final sortedDates = timeline.keys.toList()..sort((a, b) => b.compareTo(a));
    final displayDates = sortedDates.take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start Time Consistency',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayDates.length,
            itemBuilder: (context, index) {
              final date = displayDates[index];
              final data = timeline[date]!;
              final mStart = data['morning'];
              final nStart = data['night'];
              
              DateTime? parsedDate;
              try { parsedDate = DateTime.parse(date); } catch (_) {}
              final dayStr = parsedDate != null ? DateFormat.E().format(parsedDate) : '';
              final dateStr = parsedDate != null ? DateFormat.Md().format(parsedDate) : date;

              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$dayStr, $dateStr', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_rounded, size: 14, color: Color(0xFFE8A838)),
                        const SizedBox(width: 6),
                        Text(mStart != null ? DateFormat.jm().format(mStart) : '--', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.nights_stay_rounded, size: 14, color: Color(0xFF6C63FF)),
                        const SizedBox(width: 6),
                        Text(nStart != null ? DateFormat.jm().format(nStart) : '--', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTaskBreakdown(Map<String, Map<String, dynamic>> metrics) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    
    final morningTasks = widget.storage.loadMorningTasks();
    final nightTasks = widget.storage.loadNightTasks();
    final Map<String, String> taskIdToName = {};
    for (final t in morningTasks) {
      taskIdToName[t.id] = '${t.emoji} ${t.title}'.trim();
    }
    for (final t in nightTasks) {
      taskIdToName[t.id] = '${t.emoji} ${t.title}'.trim();
    }

    final Map<String, List<int>> taskDurationsMap = {};
    
    metrics.forEach((key, data) {
      try {
        final tasksMap = data['taskDurations'] as Map<String, dynamic>;
        tasksMap.forEach((taskId, durationDynamic) {
          final duration = durationDynamic as int;
          if (!taskDurationsMap.containsKey(taskId)) {
            taskDurationsMap[taskId] = [];
          }
          taskDurationsMap[taskId]!.add(duration);
        });
      } catch (_) {}
    });

    final List<MapEntry<String, double>> averages = taskDurationsMap.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return MapEntry(e.key, avg);
    }).toList();
    
    averages.sort((a, b) => b.value.compareTo(a.value));
    final topAverages = averages.take(3).toList();

    if (topAverages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Longest Tasks (Avg)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...topAverages.map((e) {
          final name = taskIdToName[e.key] ?? 'Deleted Task';
          final avgSecs = e.value.round();
          final m = avgSecs ~/ 60;
          final s = avgSecs % 60;
          final timeStr = m == 0 ? '${s}s' : '${m}m ${s}s';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  flex: 2,
                  child: Text(timeStr, textAlign: TextAlign.right, style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final morningStreak = widget.storage.getStreak('morning');
    final nightStreak = widget.storage.getStreak('night');
    final entries = widget.storage.getAllJournalEntries();
    final metrics = widget.storage.getAllRoutineMetrics();
    // Sort dates newest first
    final sortedDates = entries.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Insights',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // ── Stats Section ──────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatsCard(
                    title: 'Morning',
                    streak: morningStreak, 
                    accentColor: const Color(0xFFE8A838) // morningAccent
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatsCard(
                    title: 'Night',
                    streak: nightStreak, 
                    accentColor: const Color(0xFF6C63FF) // nightAccent
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            _buildAverages(metrics),
            _buildTimeline(metrics),
            _buildTaskBreakdown(metrics),

            // ── Journal Section Header ─────────────────────────
            Row(
              children: [
                Icon(Icons.auto_stories_rounded,
                    color: widget.accentColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Journal Entries',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Journal Entries ─────────────────────────────────
            if (sortedDates.isEmpty)
              _EmptyJournalState(accentColor: widget.accentColor)
            else
              ...sortedDates.map((date) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _JournalEntryCard(
                      date: date,
                      text: entries[date]!['text']!,
                      timestamp: entries[date]!['timestamp']!,
                      accentColor: widget.accentColor,
                      onEdit: () => _editEntry(date, entries[date]!['text']!),
                      onDelete: () => _deleteEntry(date),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

// ── Stats Card ────────────────────────────────────────────────────────

class _MetricsCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accentColor;
  final IconData icon;

  const _MetricsCard({
    required this.title,
    required this.value,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final int streak;
  final Color accentColor;

  const _StatsCard({
    required this.title,
    required this.streak,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withAlpha(30),
            accentColor.withAlpha(12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withAlpha(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              Text(
                streak > 0 ? '🔥' : '💤',
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$streak',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Days',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(160),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              streak == 0
                  ? 'Start today!'
                  : streak < 7
                      ? 'Keep going!'
                      : streak < 30
                          ? 'On fire! 🔥'
                          : 'Legendary! 🏆',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Journal Entry Card ────────────────────────────────────────────────

class _JournalEntryCard extends StatelessWidget {
  final String date;
  final String text;
  final String timestamp;
  final Color accentColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _JournalEntryCard({
    required this.date,
    required this.text,
    required this.timestamp,
    required this.accentColor,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(String isoDate) {
    try {
      final parsed = DateTime.parse(isoDate);
      return DateFormat.yMMMEd().format(parsed);
    } catch (_) {
      return isoDate;
    }
  }

  String _formatTime(String isoTimestamp) {
    if (isoTimestamp.isEmpty) return '';
    try {
      final parsed = DateTime.parse(isoTimestamp);
      return DateFormat.jm().format(parsed);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14,
                  color: accentColor.withAlpha(180)),
              const SizedBox(width: 6),
              Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentColor.withAlpha(200),
                ),
              ),
              if (timestamp.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(50),
                      fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(timestamp),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────

class _EmptyJournalState extends StatelessWidget {
  final Color accentColor;

  const _EmptyJournalState({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(50),
          ),
          const SizedBox(height: 16),
          Text(
            'No journal entries yet.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color:
                  Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete your night routine to start journaling!',
            style: TextStyle(
              fontSize: 14,
              color:
                  Theme.of(context).colorScheme.onSurface.withAlpha(80),
            ),
          ),
        ],
      ),
    );
  }
}
