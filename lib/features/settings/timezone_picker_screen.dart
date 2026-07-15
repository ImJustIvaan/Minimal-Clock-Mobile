import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

/// Full-page timezone picker with search. Timezone data is already
/// initialized by NotificationService.init() at app startup.
class TimezonePickerScreen extends StatefulWidget {
  final String selected;

  const TimezonePickerScreen({super.key, required this.selected});

  @override
  State<TimezonePickerScreen> createState() => _TimezonePickerScreenState();
}

class _TimezonePickerScreenState extends State<TimezonePickerScreen> {
  late final List<String> _allZones =
      tz.timeZoneDatabase.locations.keys.toList()..sort();
  final _ctrl = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = ['', ..._allZones];
    _ctrl.addListener(() {
      final q = _ctrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? ['', ..._allZones]
            : _allZones.where((z) => z.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _label(String id) => id.isEmpty ? 'Local (device timezone)' : id.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(title: const Text('Select Timezone')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                style: TextStyle(fontSize: 15, color: color),
                decoration: InputDecoration(
                  hintText: 'Search timezones…',
                  hintStyle: TextStyle(color: color.withOpacity(0.35)),
                  prefixIcon: Icon(Icons.search, color: color.withOpacity(0.4), size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color.withOpacity(0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color.withOpacity(0.15)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final id = _filtered[i];
                  final isSelected = id == widget.selected;
                  return ListTile(
                    title: Text(
                      _label(id),
                      style: TextStyle(
                        fontSize: 15,
                        color: isSelected ? color : color.withOpacity(0.75),
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                      ),
                    ),
                    trailing: isSelected ? Icon(Icons.check, color: color, size: 18) : null,
                    onTap: () => Navigator.of(context).pop(id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
