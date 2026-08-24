import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/purchase_service.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

const _kIsProCacheKey = 'is_pro_cached';

/// Whether the signed-in user has purchased Pro. Server-authoritative
/// (fetched from the `entitlements` table, which only the verify-purchase
/// Edge Function can write) with a local cache so gated features don't
/// flicker locked while offline for a user who already unlocked Pro.
class EntitlementNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    ref.listen(authStateProvider, (_, __) => refresh());
    ref.listen(purchaseUnlockStreamProvider, (_, __) => refresh());

    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(_kIsProCacheKey) ?? false;

    // Return the cache immediately, then kick off a background refresh —
    // callers awaiting `build()` still get the fast, offline-safe value.
    unawaited(refresh());
    return cached;
  }

  Future<void> refresh() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncData(false);
      return;
    }
    try {
      final row = await SupabaseService.client
          .from('entitlements')
          .select('is_pro')
          .eq('user_id', userId)
          .maybeSingle();
      final isPro = row?['is_pro'] as bool? ?? false;
      state = AsyncData(isPro);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsProCacheKey, isPro);
    } catch (_) {
      // Network/RLS hiccup — keep whatever state (cached or previous) is
      // already showing rather than flashing the UI to locked.
    }
  }
}

final entitlementProvider =
    AsyncNotifierProvider<EntitlementNotifier, bool>(EntitlementNotifier.new);

/// Bridges PurchaseService's non-Riverpod purchase-verified stream into a
/// provider that entitlementProvider can `ref.listen` to.
final purchaseUnlockStreamProvider = StreamProvider<void>((ref) {
  return PurchaseService.instance.proUnlockedController.stream;
});
