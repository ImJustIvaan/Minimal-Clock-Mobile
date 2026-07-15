import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/settings_model.dart';
import '../../core/providers/settings_provider.dart';
import 'timezone_picker_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    return settingsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (settings) => _SettingsBody(settings: settings),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final AppSettings settings;
  const _SettingsBody({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    final color = Theme.of(context).colorScheme.onSurface;

    void update(AppSettings s) => notifier.save(s);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 4,
                    color: color.withOpacity(0.35),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                _Section(label: 'APPEARANCE', children: [
                  _SegmentedRow(
                    label: 'Theme',
                    value: settings.themeMode,
                    options: const {
                      ThemeMode.light: 'Light',
                      ThemeMode.dark: 'Dark',
                      ThemeMode.system: 'Auto',
                    },
                    onChanged: (v) => update(settings.copyWith(themeMode: v)),
                  ),
                ]),
                _Section(label: 'CLOCK', children: [
                  _TimezoneRow(
                    value: settings.selectedTimezone,
                    onChanged: (v) => update(settings.copyWith(selectedTimezone: v)),
                  ),
                  _SwitchRow(
                    label: '24-hour format',
                    value: settings.use24Hour,
                    onChanged: (v) => update(settings.copyWith(use24Hour: v)),
                  ),
                  _SwitchRow(
                    label: 'Show seconds',
                    value: settings.showSeconds,
                    onChanged: (v) => update(settings.copyWith(showSeconds: v)),
                  ),
                  _SwitchRow(
                    label: 'Show date',
                    value: settings.showDate,
                    onChanged: (v) => update(settings.copyWith(showDate: v)),
                  ),
                  _SwitchRow(
                    label: 'Show weekday',
                    value: settings.showWeekday,
                    onChanged: (v) => update(settings.copyWith(showWeekday: v)),
                  ),
                  _SliderRow(
                    label: 'Clock size',
                    value: settings.clockFontSize,
                    min: 48,
                    max: 120,
                    onChanged: (v) => update(settings.copyWith(clockFontSize: v)),
                  ),
                ]),
                _Section(label: 'DISPLAY', children: [
                  _SwitchRow(
                    label: 'Keep screen awake',
                    value: settings.keepScreenAwake,
                    onChanged: (v) => update(settings.copyWith(keepScreenAwake: v)),
                  ),
                ]),
                _Section(label: 'NOTIFICATIONS', children: [
                  _SwitchRow(
                    label: 'Hourly Notifier',
                    value: settings.hourlyNotifier,
                    onChanged: (v) => update(settings.copyWith(hourlyNotifier: v)),
                  ),
                ]),
                _Section(label: 'CREDITS', children: const [
                  _LinkRow(
                    label: 'Made By @ImJustIvaan (a.k.a Ivaan S)',
                    url: 'https://ivaan.cc',
                  ),
                  _LinkRow(
                    label: 'Visit the Minimal Clock website',
                    url: 'https://time.ivaan.cc',
                  ),
                ]),
                const SizedBox(height: 48),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _Section({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 3,
              color: color.withOpacity(0.28),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final String url;

  const _LinkRow({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w300),
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: color.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _TimezoneRow extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TimezoneRow({required this.value, required this.onChanged});

  String _label(String id) => id.isEmpty ? 'Local' : id.replaceAll('_', ' ');

  Future<void> _openPicker(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => TimezonePickerScreen(selected: value)),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: () => _openPicker(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Timezone',
                style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w300),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: color.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label(value),
                    style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.expand_more, size: 16, color: color.withOpacity(0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w300),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w300),
                ),
              ),
              Text(
                '${value.round()}',
                style: TextStyle(fontSize: 14, color: color.withOpacity(0.4)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              thumbColor: color,
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.12),
              overlayColor: color.withOpacity(0.08),
              trackHeight: 1.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _SegmentedRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w300),
            ),
          ),
          SegmentedButton<T>(
            segments: options.entries
                .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                .toList(),
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            style: ButtonStyle(
              textStyle: WidgetStatePropertyAll(
                TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
