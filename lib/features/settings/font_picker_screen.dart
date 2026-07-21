import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-page font picker with search. Each row previews the font itself.
/// Fonts are downloaded and cached by google_fonts the first time they're
/// used, so selecting a font needs network access on its first use.
class FontPickerScreen extends StatefulWidget {
  final String selected;

  const FontPickerScreen({super.key, required this.selected});

  @override
  State<FontPickerScreen> createState() => _FontPickerScreenState();
}

class _FontPickerScreenState extends State<FontPickerScreen> {
  late final List<String> _allFonts = GoogleFonts.asMap().keys.toList()..sort();
  final _ctrl = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = ['', ..._allFonts];
    _ctrl.addListener(() {
      final q = _ctrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? ['', ..._allFonts]
            : _allFonts.where((f) => f.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(title: const Text('Select Font')),
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
                  hintText: 'Search fonts…',
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
                  final name = _filtered[i];
                  final isSelected = name == widget.selected;
                  final isDefault = name.isEmpty;
                  return ListTile(
                    title: Text(
                      isDefault ? 'Default' : name,
                      style: isDefault
                          ? TextStyle(
                              fontSize: 16,
                              color: isSelected ? color : color.withOpacity(0.75),
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                            )
                          : GoogleFonts.getFont(
                              name,
                              textStyle: TextStyle(
                                fontSize: 16,
                                color: isSelected ? color : color.withOpacity(0.75),
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                              ),
                            ),
                    ),
                    trailing: isSelected ? Icon(Icons.check, color: color, size: 18) : null,
                    onTap: () => Navigator.of(context).pop(name),
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
