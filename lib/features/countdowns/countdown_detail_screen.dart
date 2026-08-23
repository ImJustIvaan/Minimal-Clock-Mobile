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
  final _shareButtonKey = GlobalKey();

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
    // sharePositionOrigin is required on iPad, where the share sheet is
    // presented as a popover anchored to a source rect — without it the
    // call fails silently (no sheet, no error). iPhone doesn't need it
    // since it presents as a bottom sheet instead, which is why this only
    // showed up testing on iPad and not on the iPhone-only sideloaded build.
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    Share.share(
      '$title — count down with me: $url',
      sharePositionOrigin: origin,
    );
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: widget.countdownId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Countdown ID copied')),
    );
  }

  Future<void> _delete(bool isOwner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isOwner ? 'Delete countdown?' : 'Remove countdown?'),
        content: Text(isOwner
            ? 'This will permanently delete this countdown for everyone.'
            : 'This will remove the countdown from your list. You can add it back later using its ID.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isOwner ? 'Delete' : 'Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(countdownRepositoryProvider);
      await NotificationService.instance
          .cancelCountdownNotification(widget.countdownId);
      if (isOwner) {
        await repo.deleteCountdown(widget.countdownId);
      } else {
        await repo.unfollow(widget.countdownId);
      }
      ref.invalidate(myCountdownsProvider);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final countdownAsync =
        ref.watch(countdownByIdProvider(widget.countdownId));
    final followAsync =
        ref.watch(followByCountdownIdProvider(widget.countdownId));
    final userId = ref.watch(countdownRepositoryProvider).currentUserId;

    final countdownValue = countdownAsync.valueOrNull;
    final isOwner = countdownValue != null && userId == countdownValue.ownerId;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: _shareButtonKey,
            icon: const Icon(Icons.ios_share),
            onPressed: countdownValue == null
                ? null
                : () => _share(countdownValue.title),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: isOwner ? 'Delete' : 'Remove',
            onPressed: countdownValue == null || _busy
                ? null
                : () => _delete(isOwner),
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
