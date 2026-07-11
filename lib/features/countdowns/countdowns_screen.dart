import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/countdown_provider.dart';
import '../../core/services/supabase_service.dart';
import '../auth/auth_screen.dart';
import 'create_countdown_screen.dart';
import 'countdown_detail_screen.dart';
import 'enter_id_screen.dart';
import 'widgets/countdown_tile.dart';

class CountdownsScreen extends ConsumerWidget {
  const CountdownsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseConfig.isConfigured) {
      return const _NotConfiguredScreen();
    }
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const AuthScreen();
    }
    return const _CountdownsList();
  }
}

class _CountdownsList extends ConsumerWidget {
  const _CountdownsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.onSurface;
    final countdownsAsync = ref.watch(myCountdownsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Countdowns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Find by ID',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EnterIdScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => SupabaseService.client.auth.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: color,
        foregroundColor: Theme.of(context).colorScheme.surface,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateCountdownScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myCountdownsProvider),
          child: countdownsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text('Could not load countdowns', style: TextStyle(color: color)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    Center(
                      child: Text(
                        'No countdowns yet.\nTap + to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: color.withOpacity(0.4)),
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(color: color.withOpacity(0.08)),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return CountdownTile(
                    countdown: item.countdown,
                    notify: item.follow.notify,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CountdownDetailScreen(
                          countdownId: item.countdown.id,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotConfiguredScreen extends StatelessWidget {
  const _NotConfiguredScreen();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Countdowns need a Supabase project to be connected.\n\nAdd your project URL and anon key in lib/core/services/supabase_service.dart.',
              textAlign: TextAlign.center,
              style: TextStyle(color: color.withOpacity(0.5)),
            ),
          ),
        ),
      ),
    );
  }
}
