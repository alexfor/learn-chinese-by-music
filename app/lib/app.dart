import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/songs/song_list_screen.dart';
import 'features/songs/song_detail_screen.dart';
import 'features/player/player_screen.dart';
import 'features/singalong/singalong_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/community/community_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/settings/settings_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SongListScreen(),
    ),
    GoRoute(
      path: '/songs/:id',
      builder: (context, state) {
        final songId = state.pathParameters['id']!;
        return SongDetailScreen(songId: songId);
      },
    ),
    GoRoute(
      path: '/songs/:id/play',
      builder: (context, state) {
        final songId = state.pathParameters['id']!;
        return PlayerScreen(songId: songId);
      },
    ),
    GoRoute(
      path: '/songs/:id/sing',
      builder: (context, state) {
        final songId = state.pathParameters['id']!;
        return SingalongScreen(songId: songId);
      },
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressScreen(),
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class LearnChineseByMusicApp extends ConsumerWidget {
  const LearnChineseByMusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Learn Chinese by Music',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
