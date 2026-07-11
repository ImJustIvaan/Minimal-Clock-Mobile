import 'dart:async';
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

class TimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;

  @override
  TimerState build() => const TimerState();

  void setDuration(Duration d) {
    _ticker?.cancel();
    state = TimerState(total: d, remaining: d, status: TimerStatus.idle);
  }

  void start() {
    if (state.remaining == Duration.zero) return;
    state = state.copyWith(status: TimerStatus.running);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    NotificationService.instance.scheduleTimerNotification(state.remaining);
  }

  void pause() {
    _ticker?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
    NotificationService.instance.cancelTimerNotification();
  }

  void resume() {
    state = state.copyWith(status: TimerStatus.running);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    NotificationService.instance.scheduleTimerNotification(state.remaining);
  }

  void reset() {
    _ticker?.cancel();
    state = TimerState(
        total: state.total, remaining: state.total, status: TimerStatus.idle);
    NotificationService.instance.cancelTimerNotification();
  }

  void _tick() {
    if (state.remaining.inSeconds <= 1) {
      _ticker?.cancel();
      state = state.copyWith(
          remaining: Duration.zero, status: TimerStatus.finished);
      // The OS-scheduled notification (from start/resume) covers the case
      // where the app was backgrounded; fire immediately too so it's exact
      // when the app is still in the foreground at this instant.
      NotificationService.instance
        ..cancelTimerNotification()
        ..showTimerFinished();
    } else {
      state = state.copyWith(
          remaining: state.remaining - const Duration(seconds: 1));
    }
  }

  void dispose() {
    _ticker?.cancel();
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(TimerNotifier.new);
