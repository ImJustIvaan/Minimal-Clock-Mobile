import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../../features/countdowns/countdown_detail_screen.dart';

/// Routes incoming `minimalclock://countdown?id=<id>` links (e.g. tapped
/// from the "Open in App" button on the website) to the matching countdown.
/// Auth callbacks (`minimalclock://login-callback`) are handled separately
/// by supabase_flutter's own web-auth session and are ignored here.
class DeepLinkService {
  DeepLinkService._();
  static final instance = DeepLinkService._();

  final _appLinks = AppLinks();

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial, navigatorKey);
    } catch (_) {
      // No initial link, or platform doesn't support querying it.
    }

    _appLinks.uriLinkStream.listen((uri) => _handle(uri, navigatorKey));
  }

  void _handle(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    if (uri.scheme != 'minimalclock' || uri.host != 'countdown') return;
    final id = uri.queryParameters['id'];
    if (id == null || id.isEmpty) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => CountdownDetailScreen(countdownId: id)),
    );
  }
}
