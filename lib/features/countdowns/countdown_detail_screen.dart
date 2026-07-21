import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/countdown_provider.dart';
import '../../core/services/notification_service.dart';
import '../../shared/widgets/tv_focusable.dart';
import 'widgets/countdown_tile.dart';

const String kCountdownShareBaseUrl = 'https://time.ivaan.cc/?c=';

class CountdownDetailScreen extends ConsumerStatefulWidget {
  final String countdownId;
  const CountdownDetailScreen({super.key, required this.countdownId});

  @override
  ConsumerState<CountdownDetailScreen> createState() =>
      _CountdownDetailScreenState();
}

class _CountdownDetailScreenState
    extends ConsumerState<CountdownDetailScreen> {
  late Timer _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _toggleNotify(bool isOwner) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(countdownRepositoryProvider);
      final follow = await ref.read(
          followByCountdownIdProvider(widget.countdownId).future);
      final newValue = !(follow?.notify ?? false);
      await repo.setFollow(countdownId: widget.countdownId, notify: newValue);

      final countdown =
          await ref.read(countdownByIdProvider(widget.countdownId).future);
      if (newValue) {
        await NotificationService.instance.scheduleCountdownNotification(
          countdownId: widget.countdownId,
          title: countdown.title,
          targetDate: countdown.targetDate,
        );
      } else {
        await NotificationService.instance
            .cancelCountdownNotification(widget.countdownId);
      }
      ref.invalidate(followByCountdownIdProvider(widget.countdownId));
      ref.invalidate(myCountdownsProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _share(String title) {
    final url = '$kCountdownShareBaseUrl${widget.countdownId}';
    Share.share('$title — count down with me: $url');
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: widget.countdownId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Countdown ID copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final countdownAsync =
        ref.watch(countdownByIdProvider(widget.countdownId));
    final followAsync =
        ref.watch(followByCountdownIdProvider(widget.countdownId));
    final userId = ref.watch(countdownRepositoryProvider).currentUserId;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: countdownAsync.valueOrNull == null
                ? null
                : () => _share(countdownAsync.value!.title),
          ),
        ],
      ),
      body: SafeArea(
        child: countdownAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text('Countdown not found', style: TextStyle(color: color)),
          ),
          data: (countdown) {
            final remaining = countdown.targetDate.difference(DateTime.now());
            final isOwner = userId != null && userId == countdown.ownerId;
            final notify = followAsync.valueOrNull?.notify ?? false;

            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    countdown.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    formatRemaining(remaining),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -1,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${countdown.targetDate.month}/${countdown.targetDate.day}/${countdown.targetDate.year}',
                    style: TextStyle(fontSize: 14, color: color.withOpacity(0.4)),
                  ),
                  const SizedBox(height: 40),
                  TvFocusable(
                    onTap: _busy ? null : () => _toggleNotify(isOwner),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      decoration: BoxDecoration(
                        color: notify ? color : Colors.transparent,
                        border: Border.all(color: color.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            notify
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            size: 18,
                            color: notify
                                ? Theme.of(context).colorScheme.surface
                                : color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notify ? 'Notifying' : 'Notify me',
                            style: TextStyle(
                              color: notify
                                  ? Theme.of(context).colorScheme.surface
                                  : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TvFocusable(
                    onTap: _copyId,
                    borderRadius: BorderRadius.circular(4),
                    child: Text(
                      'ID: ${countdown.id}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withOpacity(0.3),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        ),
      ),
    );
  }
}
