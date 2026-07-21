import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the "Hide UI" mode is active — hides the bottom nav and all
/// clock-screen chrome (weekday/date/timezone label) except the time itself.
/// Deliberately not persisted: it's a transient "focus mode" toggle, not a
/// setting you'd want to still be in the next time you open the app.
final uiHiddenProvider = StateProvider<bool>((ref) => false);
