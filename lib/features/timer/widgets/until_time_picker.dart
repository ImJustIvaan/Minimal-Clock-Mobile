import 'package:flutter/material.dart';

/// Lets the user pick a target clock time (e.g. "9:40 AM") instead of a
/// raw duration. TimerScreen converts this to a Duration relative to now
/// when the timer is started.
class UntilTimePicker extends StatefulWidget {
  final TimeOfDay initial;
  final bool is24Hour;
  final ValueChanged<TimeOfDay> onChanged;

  const UntilTimePicker({
    super.key,
    required this.initial,
    required this.is24Hour,
    required this.onChanged,
  });

  @override
  State<UntilTimePicker> createState() => _UntilTimePickerState();
}

class _UntilTimePickerState extends State<UntilTimePicker> {
  late int _hour24;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour24 = widget.initial.hour;
    _minute = widget.initial.minute;
  }

  void _notify() {
    widget.onChanged(TimeOfDay(hour: _hour24, minute: _minute));
  }

  bool get _isPm => _hour24 >= 12;

  int get _hourDisplay {
    if (widget.is24Hour) return _hour24;
    final h = _hour24 % 12;
    return h == 0 ? 12 : h;
  }

  void _setHourDisplay(int displayValue) {
    if (widget.is24Hour) {
      _hour24 = displayValue;
    } else {
      final isPm = _isPm;
      var h = displayValue % 12;
      if (isPm) h += 12;
      _hour24 = h;
    }
    _notify();
  }

  void _toggleAmPm() {
    setState(() {
      _hour24 = _isPm ? _hour24 - 12 : _hour24 + 12;
      _notify();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final scale = isTablet ? 1.5 : 1.0;
    // Fixed-size digit wheel, not scrollable text — ignore accessibility
    // text scaling so digits can't clip their cells.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: _buildContent(color, scale),
    );
  }

  Widget _buildContent(Color color, double scale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'TIMER ENDS AT',
          style: TextStyle(
            fontSize: 11 * scale,
            letterSpacing: 4,
            color: color.withOpacity(0.3),
          ),
        ),
        SizedBox(height: 32 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Scroll(
              label: 'HH',
              value: _hourDisplay,
              max: widget.is24Hour ? 23 : 12,
              min: widget.is24Hour ? 0 : 1,
              scale: scale,
              onChanged: (v) => setState(() => _setHourDisplay(v)),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20 * scale),
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: 48 * scale,
                  fontWeight: FontWeight.w200,
                  color: color.withOpacity(0.3),
                ),
              ),
            ),
            _Scroll(
              label: 'MM',
              value: _minute,
              max: 59,
              min: 0,
              scale: scale,
              onChanged: (v) => setState(() {
                _minute = v;
                _notify();
              }),
            ),
            if (!widget.is24Hour) ...[
              SizedBox(width: 16 * scale),
              GestureDetector(
                onTap: _toggleAmPm,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
                  decoration: BoxDecoration(
                    border: Border.all(color: color.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isPm ? 'PM' : 'AM',
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Scroll extends StatefulWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final double scale;
  final ValueChanged<int> onChanged;

  const _Scroll({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.scale = 1.0,
  });

  @override
  State<_Scroll> createState() => _ScrollState();
}

class _ScrollState extends State<_Scroll> {
  late FixedExtentScrollController _ctrl;
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.max - widget.min + 1;
    _ctrl = FixedExtentScrollController(initialItem: widget.value - widget.min);
  }

  @override
  void didUpdateWidget(covariant _Scroll old) {
    super.didUpdateWidget(old);
    if (old.min != widget.min || old.max != widget.max) {
      _count = widget.max - widget.min + 1;
      _ctrl.jumpToItem(widget.value - widget.min);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72 * widget.scale,
          height: 140 * widget.scale,
          child: ListWheelScrollView.useDelegate(
            controller: _ctrl,
            itemExtent: 56 * widget.scale,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.003,
            onSelectedItemChanged: (i) => widget.onChanged(widget.min + (i % _count)),
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final v = widget.min + (index % _count);
                final selected = v == widget.value;
                return Center(
                  child: Text(
                    v.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 42 * widget.scale,
                      fontWeight: FontWeight.w200,
                      color: selected ? color : color.withOpacity(0.18),
                      letterSpacing: -1,
                    ),
                  ),
                );
              },
              childCount: _count * 100,
            ),
          ),
        ),
        SizedBox(height: 6 * widget.scale),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 10 * widget.scale,
            letterSpacing: 2,
            color: color.withOpacity(0.25),
          ),
        ),
      ],
    );
  }
}
