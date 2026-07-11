import '../models/countdown_model.dart';
import 'supabase_service.dart';

class CountdownNotFoundException implements Exception {}

class CountdownRepository {
  CountdownRepository._();
  static final instance = CountdownRepository._();

  final _client = SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<Countdown> createCountdown({
    required String title,
    required DateTime targetDate,
  }) async {
    final ownerId = currentUserId;
    if (ownerId == null) throw StateError('Not signed in');
    final row = await _client
        .from('countdowns')
        .insert({
          'owner_id': ownerId,
          'title': title,
          'target_date': targetDate.toUtc().toIso8601String(),
        })
        .select()
        .single();
    final countdown = Countdown.fromJson(row);
    // Owners automatically follow + get notified for their own countdown.
    await setFollow(countdownId: countdown.id, notify: true);
    return countdown;
  }

  Future<Countdown> fetchCountdown(String id) async {
    final row = await _client
        .from('countdowns')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) throw CountdownNotFoundException();
    return Countdown.fromJson(row);
  }

  Future<void> deleteCountdown(String id) async {
    await _client.from('countdowns').delete().eq('id', id);
  }

  Future<CountdownFollow?> fetchFollow(String countdownId) async {
    final userId = currentUserId;
    if (userId == null) return null;
    final row = await _client
        .from('countdown_follows')
        .select()
        .eq('user_id', userId)
        .eq('countdown_id', countdownId)
        .maybeSingle();
    return row == null ? null : CountdownFollow.fromJson(row);
  }

  Future<CountdownFollow> setFollow({
    required String countdownId,
    required bool notify,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not signed in');
    final row = await _client
        .from('countdown_follows')
        .upsert(
          {
            'user_id': userId,
            'countdown_id': countdownId,
            'notify': notify,
          },
          onConflict: 'user_id,countdown_id',
        )
        .select()
        .single();
    return CountdownFollow.fromJson(row);
  }

  Future<void> unfollow(String countdownId) async {
    final userId = currentUserId;
    if (userId == null) return;
    await _client
        .from('countdown_follows')
        .delete()
        .eq('user_id', userId)
        .eq('countdown_id', countdownId);
  }

  Future<List<FollowedCountdown>> fetchMyCountdowns() async {
    final userId = currentUserId;
    if (userId == null) return [];
    final rows = await _client
        .from('countdown_follows')
        .select('*, countdowns(*)')
        .eq('user_id', userId)
        .order('created_at');
    return rows
        .where((r) => r['countdowns'] != null)
        .map<FollowedCountdown>((r) => FollowedCountdown(
              countdown: Countdown.fromJson(
                  r['countdowns'] as Map<String, dynamic>),
              follow: CountdownFollow.fromJson(r),
            ))
        .toList();
  }
}
