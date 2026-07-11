import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/countdown_model.dart';
import '../services/countdown_repository.dart';
import 'auth_provider.dart';

final countdownRepositoryProvider = Provider<CountdownRepository>((ref) {
  return CountdownRepository.instance;
});

final myCountdownsProvider =
    FutureProvider.autoDispose<List<FollowedCountdown>>((ref) async {
  ref.watch(currentUserProvider);
  return ref.read(countdownRepositoryProvider).fetchMyCountdowns();
});

final countdownByIdProvider =
    FutureProvider.autoDispose.family<Countdown, String>((ref, id) async {
  return ref.read(countdownRepositoryProvider).fetchCountdown(id);
});

final followByCountdownIdProvider = FutureProvider.autoDispose
    .family<CountdownFollow?, String>((ref, countdownId) async {
  ref.watch(currentUserProvider);
  return ref.read(countdownRepositoryProvider).fetchFollow(countdownId);
});
