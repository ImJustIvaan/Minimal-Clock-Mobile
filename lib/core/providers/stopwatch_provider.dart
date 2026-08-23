import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StopwatchStatus { idle, running, paused }

class StopwatchState {
  final Duration elapsed;
  final StopwatchStatus status;

  const StopwatchState({
    this.elapsed = Duration.zero,
    this.status = StopwatchStatus.idle,
  });

  StopwatchState copyWith({Duration? elapsed, StopwatchStatus? status}) =>
      StopwatchState(
        elapsed: elapsed ?? this.elapsed,
        status: status ?? this.status,
      );
}

class StopwatchNotifier extends Notifier<StopwatchState>
    with WidgetsBindingObserver {
  Timer? _ticker;

  // Wall-clock anchor for the currently running segment, same reasoning as
  // TimerNotifier's _endTime: a tick counter alone loses time the app spent
  // suspended, so elapsed time is always re-derived from real clock time.
  DateTime? _segmentStart;
  Duration _accumulated = Duration.zero;

  @override
  StopwatchState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _ticker?.cancel();
    });
    return const StopwatchState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) _syncToWallClock();
  }

  void _syncToWallClock() {
    if (state.status != StopwatchStatus.running || _segmentStart == null) {
      return;
    }
    state = state.copyWith(
      elapsed: _accumulated + DateTime.now().difference(_segmentStart!),
    );
  }

  void start() {
    _segmentStart = DateTime.now();
    state = state.copyWith(status: StopwatchStatus.running);
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void pause() {
    _ticker?.cancel();
    if (_segmentStart != null) {
      _accumulated += DateTime.now().difference(_segmentStart!);
    }
    _segmentStart = null;
    state = state.copyWith(elapsed: _accumulated, status: StopwatchStatus.paused);
  }

  void reset() {
    _ticker?.cancel();
    _segmentStart = null;
    _accumulated = Duration.zero;
    state = const StopwatchState();
  }

  void _tick() {
    if (_segmentStart == null) return;
    state = state.copyWith(
      elapsed: _accumulated + DateTime.now().difference(_segmentStart!),
    );
  }
}

final stopwatchProvider =
    NotifierProvider<StopwatchNotifier, StopwatchState>(StopwatchNotifier.new);
