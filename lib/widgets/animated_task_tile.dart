import 'package:flutter/material.dart';
import '../models/routine_task.dart';

class AnimatedTaskTile extends StatefulWidget {
  final RoutineTask task;
  final Color accentColor;
  final ValueChanged<bool> onToggle;

  const AnimatedTaskTile({
    super.key,
    required this.task,
    required this.accentColor,
    required this.onToggle,
  });

  @override
  State<AnimatedTaskTile> createState() => _AnimatedTaskTileState();
}

class _AnimatedTaskTileState extends State<AnimatedTaskTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _strikeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.02), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _strikeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    if (widget.task.isCompleted) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedTaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.isCompleted != oldWidget.task.isCompleted) {
      if (widget.task.isCompleted) {
        _controller.forward(from: 0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.task.isCompleted;
    return ScaleTransition(
      scale: _scaleAnim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCompleted
              ? widget.accentColor.withAlpha(25)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? widget.accentColor.withAlpha(80)
                : Theme.of(context).colorScheme.outlineVariant.withAlpha(60),
            width: 1.5,
          ),
          boxShadow: [
            if (!isCompleted)
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Semantics(
          checked: isCompleted,
          button: true,
          label: widget.task.title,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => widget.onToggle(!isCompleted),
            child: ExcludeSemantics(
              child: Row(
                children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? widget.accentColor
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? widget.accentColor
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withAlpha(100),
                    width: 2,
                  ),
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: isCompleted ? 1.0 : 0.0,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Emoji
              if (widget.task.emoji.isNotEmpty) ...[
                Text(
                  widget.task.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 12),
              ],
              // Title
              Expanded(
                child: AnimatedBuilder(
                  animation: _strikeAnim,
                  builder: (context, child) {
                    return Text(
                      widget.task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(120)
                            : Theme.of(context).colorScheme.onSurface,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: widget.accentColor.withAlpha(150),
                        decorationThickness: 2,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }
}
