import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/timer_provider.dart';
import '../../shared/widgets/tv_focusable.dart';
import 'widgets/duration_picker.dart';
import 'widgets/timer_progress_ring.dart';
import 'widgets/until_time_picker.dart';

enum _TimerInputMode { duration, until }

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  _TimerInputMode _mode = _TimerInputMode.duration;
  TimeOfDay _untilTime = TimeOfDay.now();

  void _start(TimerNotifier notifier) {
    if (_mode == _TimerInputMode.until) {
      final now = DateTime.now();
      var target = DateTime(now.year, now.month, now.day, _untilTime.hour, _untilTime.minute);
      if (!target.isAfter(now)) {
        target = target.add(const Duration(days: 1));
      }
      notifier.setDuration(target.difference(now));
    }
    notifier.start();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    final color = Theme.of(context).colorScheme.onSurface;
    final is24Hour = ref.watch(settingsProvider).valueOrNull?.use24Hour ?? false;
    final isIdle = state.status == TimerStatus.idle;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              if (isIdle) ...[
                _ModeToggle(
                  mode: _mode,
                  color: color,
                  onChanged: (m) => setState(() => _mode = m),
                ),
                const SizedBox(height: 24),
              ],
              // Progress ring + time display
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: !isIdle
                    ? TimerProgressRing(
                        key: const ValueKey('ring'),
                        state: state,
                        color: color,
                      )
                    : _mode == _TimerInputMode.duration
                        ? DurationPicker(
                            key: const ValueKey('picker'),
                            onChanged: (d) => notifier.setDuration(d),
                            initial: state.total,
                          )
                        : UntilTimePicker(
                            key: const ValueKey('until'),
                            initial: _untilTime,
                            is24Hour: is24Hour,
                            onChanged: (t) => setState(() => _untilTime = t),
                          ),
              ),
              const Spacer(flex: 2),
              // Control buttons
              _Controls(state: state, notifier: notifier, onStart: () => _start(notifier)),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _TimerInputMode mode;
  final Color color;
  final ValueChanged<_TimerInputMode> onChanged;

  const _ModeToggle({required this.mode, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: 'Duration',
            selected: mode == _TimerInputMode.duration,
            color: color,
            onTap: () => onChanged(_TimerInputMode.duration),
          ),
          _ModeButton(
            label: 'Until Time',
            selected: mode == _TimerInputMode.until,
            color: color,
            onTap: () => onChanged(_TimerInputMode.until),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Theme.of(context).colorScheme.surface : color.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final TimerState state;
  final TimerNotifier notifier;
  final VoidCallback onStart;

  const _Controls({required this.state, required this.notifier, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state.status != TimerStatus.idle) ...[
          _CircleButton(
            icon: Icons.refresh_rounded,
            onTap: notifier.reset,
            color: color.withOpacity(0.3),
            size: 56,
          ),
          const SizedBox(width: 24),
        ],
        _CircleButton(
          icon: _primaryIcon(state.status),
          onTap: () => _primaryAction(state.status, notifier, onStart),
          color: color,
          size: 72,
          iconColor: Theme.of(context).colorScheme.surface,
        ),
      ],
    );
  }

  IconData _primaryIcon(TimerStatus s) {
    switch (s) {
      case TimerStatus.running:
        return Icons.pause_rounded;
      case TimerStatus.paused:
        return Icons.play_arrow_rounded;
      case TimerStatus.finished:
        return Icons.refresh_rounded;
      case TimerStatus.idle:
        return Icons.play_arrow_rounded;
    }
  }

  void _primaryAction(TimerStatus s, TimerNotifier n, VoidCallback onStart) {
    switch (s) {
      case TimerStatus.idle:
        onStart();
      case TimerStatus.running:
        n.pause();
      case TimerStatus.paused:
        n.resume();
      case TimerStatus.finished:
        n.reset();
    }
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;
  final Color? iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.size,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.surface,
          size: size * 0.45,
        ),
      ),
    );
  }
}
