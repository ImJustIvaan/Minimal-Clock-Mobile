import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

enum TimerStatus { idle, running, paused, finished }

class TimerState {
  final Duration total;
  final Duration remaining;
  final TimerStatus status;

  const TimerState({
    this.total = Duration.zero,
    this.remaining = Duration.zero,
    this.status = TimerStatus.idle,
  });

  double get progress =>
      total.inSeconds == 0 ? 0 : remaining.inSeconds / total.inSeconds;

  TimerState copyWith({
    Duration? total,
    Duration? remaining,
    TimerStatus? status,
  }) =>
      TimerState(
        total: total ?? this.total,
        remaining: remaining ?? this.remaining,
        status: status ?? this.status,
      );
}

class TimerNotifier extends Notifier<TimerState> with WidgetsBindingObserver {
  Timer? _ticker;

  // Wall-clock time the timer is due to finish. Remaining time is always
  // derived from this, rather than counting down by exactly 1s per tick —
  // ticks stop firing while the app is suspended (e.g. screen locked), so a
  // pure tick-counter silently loses whatever time passed in the background.
  DateTime? _endTime;

  @override
  TimerState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _ticker?.cancel();
    });
    return const TimerState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      _syncToWallClock();
    }
  }

  void _syncToWallClock() {
    if (state.status != TimerStatus.running || _endTime == null) return;
    final remaining = _endTime!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _finish();
    } else {
      state = state.copyWith(remaining: remaining);
    }
  }

  void setDuration(Duration d) {
    _ticker?.cancel();
    _endTime = null;
    state = TimerState(total: d, remaining: d, status: TimerStatus.idle);
  }

  void start() {
    if (state.remaining == Duration.zero) return;
    _endTime = DateTime.now().add(state.remaining);
    state = state.copyWith(status: TimerStatus.running);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    NotificationService.instance.scheduleTimerNotification(state.remaining);
  }

  void pause() {
    _ticker?.cancel();
    _endTime = null;
    state = state.copyWith(status: TimerStatus.paused);
    NotificationService.instance.cancelTimerNotification();
  }

  void resume() {
    _endTime = DateTime.now().add(state.remaining);
    state = state.copyWith(status: TimerStatus.running);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    NotificationService.instance.scheduleTimerNotification(state.remaining);
  }

  void reset() {
    _ticker?.cancel();
    _endTime = null;
    state = TimerState(
        total: state.total, remaining: state.total, status: TimerStatus.idle);
    NotificationService.instance.cancelTimerNotification();
  }

  void _tick() {
    if (_endTime == null) return;
    final remaining = _endTime!.difference(DateTime.now());
    if (remaining <= const Duration(milliseconds: 500)) {
      _finish();
    } else {
      state = state.copyWith(remaining: remaining);
    }
  }

  void _finish() {
    _ticker?.cancel();
    _endTime = null;
    state = state.copyWith(remaining: Duration.zero, status: TimerStatus.finished);
    // The OS-scheduled notification (from start/resume) covers the case
    // where the app was backgrounded; fire immediately too so it's exact
    // when the app is still in the foreground at this instant.
    NotificationService.instance
      ..cancelTimerNotification()
      ..showTimerFinished();
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(TimerNotifier.new);
