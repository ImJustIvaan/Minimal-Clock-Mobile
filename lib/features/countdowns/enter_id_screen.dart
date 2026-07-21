import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/countdown_provider.dart';
import '../../core/services/countdown_repository.dart';
import '../../shared/widgets/tv_focusable.dart';
import 'countdown_detail_screen.dart';

class EnterIdScreen extends ConsumerStatefulWidget {
  const EnterIdScreen({super.key});

  @override
  ConsumerState<EnterIdScreen> createState() => _EnterIdScreenState();
}

class _EnterIdScreenState extends ConsumerState<EnterIdScreen> {
  final _idCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final raw = _idCtrl.text.trim();
    if (raw.isEmpty) return;
    final id = raw.split('/').last;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(countdownRepositoryProvider);
      final countdown = await repo.fetchCountdown(id);
      final existingFollow = await repo.fetchFollow(countdown.id);
      if (existingFollow == null) {
        await repo.setFollow(countdownId: countdown.id, notify: false);
      }
      ref.invalidate(myCountdownsProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CountdownDetailScreen(countdownId: countdown.id),
        ),
      );
    } on CountdownNotFoundException {
      setState(() => _error = 'No countdown found with that ID.');
    } catch (e) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Countdown')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paste a countdown ID or share link to view and follow it.',
                style: TextStyle(color: color.withOpacity(0.5), fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _idCtrl,
                style: TextStyle(color: color),
                decoration: InputDecoration(
                  hintText: 'Countdown ID or link',
                  hintStyle: TextStyle(color: color.withOpacity(0.3)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: color.withOpacity(0.15)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: color.withOpacity(0.6)),
                  ),
                ),
                onSubmitted: (_) => _go(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              TvFocusable(
                onTap: _loading ? null : _go,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _loading ? color.withOpacity(0.3) : color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _loading ? '...' : 'View Countdown',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
