import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/countdown_provider.dart';
import '../../core/services/notification_service.dart';
import '../../shared/widgets/tv_focusable.dart';
import 'countdown_detail_screen.dart';

class CreateCountdownScreen extends ConsumerStatefulWidget {
  const CreateCountdownScreen({super.key});

  @override
  ConsumerState<CreateCountdownScreen> createState() =>
      _CreateCountdownScreenState();
}

class _CreateCountdownScreenState
    extends ConsumerState<CreateCountdownScreen> {
  final _titleCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null) return;
    setState(() {
      _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give your countdown a title.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(countdownRepositoryProvider);
      final countdown =
          await repo.createCountdown(title: title, targetDate: _date);
      await NotificationService.instance.scheduleCountdownNotification(
        countdownId: countdown.id,
        title: countdown.title,
        targetDate: countdown.targetDate,
      );
      ref.invalidate(myCountdownsProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CountdownDetailScreen(countdownId: countdown.id),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Could not create countdown. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(title: const Text('New Countdown')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleCtrl,
                style: TextStyle(color: color, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Title (e.g. Birthday Trip)',
                  hintStyle: TextStyle(color: color.withOpacity(0.3)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: color.withOpacity(0.15)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: color.withOpacity(0.6)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TvFocusable(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: color.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18, color: color.withOpacity(0.5)),
                      const SizedBox(width: 12),
                      Text(
                        '${_date.month}/${_date.day}/${_date.year}  ${TimeOfDay.fromDateTime(_date).format(context)}',
                        style: TextStyle(color: color, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const Spacer(),
              TvFocusable(
                onTap: _saving ? null : _create,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _saving ? color.withOpacity(0.3) : color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _saving ? '...' : 'Create Countdown',
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
