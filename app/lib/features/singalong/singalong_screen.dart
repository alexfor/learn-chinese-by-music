import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/lrc_parser.dart';
import '../../models/song.dart';
import '../songs/song_providers.dart';
import '../player/player_controller.dart';
import 'audio_recorder.dart';
import 'scoring_pipeline.dart';
import 'score_display.dart';

final singalongPipelineProvider = Provider<ScoringPipeline>((ref) {
  final audio = ref.read(audioServiceProvider);
  return ScoringPipeline(
    audioService: audio,
    recorder: AudioRecorderService(),
  );
});

class SingalongScreen extends ConsumerStatefulWidget {
  final String songId;
  const SingalongScreen({super.key, required this.songId});

  @override
  ConsumerState<SingalongScreen> createState() => _SingalongScreenState();
}

class _SingalongScreenState extends ConsumerState<SingalongScreen> {
  SingalongState _localState = SingalongState.idle;

  @override
  void dispose() {
    ref.read(singalongPipelineProvider).stop();
    super.dispose();
  }

  Future<void> _handleStart() async {
    final detailAsync = ref.read(songDetailProvider(widget.songId));
    final song = detailAsync.valueOrNull;
    if (song == null) return;

    final pipeline = ref.read(singalongPipelineProvider);

    // Parse LRC for reference curves
    final lrcLines = song.lrc != null ? LrcParser.parse(song.lrc!) : <LrcLine>[];
    if (lrcLines.isNotEmpty) {
      pipeline.configure(lrcLines, []);
    }

    // Start with accompaniment URL
    final accompanimentUrl = song.accompanimentUrl;

    if (accompanimentUrl != null) {
      await pipeline.start(accompanimentUrl);
      setState(() => _localState = SingalongState.recording);
    }
  }

  Future<void> _handleStop() async {
    final pipeline = ref.read(singalongPipelineProvider);
    await pipeline.stop();
    setState(() => _localState = SingalongState.completed);
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(songDetailProvider(widget.songId));
    final pipeline = ref.watch(singalongPipelineProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sing Along')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load song',
              style: TextStyle(color: colorScheme.error)),
        ),
        data: (song) => _buildContent(song, pipeline, colorScheme),
      ),
    );
  }

  Widget _buildContent(
      SongDetail song, ScoringPipeline pipeline, ColorScheme colorScheme) {
    return Column(
      children: [
        // Song info
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(song.title,
              style: Theme.of(context).textTheme.headlineSmall),
        ),

        // Status / state display
        Expanded(
          child: Center(
            child: _localState == SingalongState.completed
                ? ScoreDisplay(
                    lineScores: pipeline.lineScores,
                    totalScore: pipeline.totalScore,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStateIndicator(),
                      const SizedBox(height: 24),
                      if (song.lyricJson != null)
                        Text(song.lyricJson!.lines.isNotEmpty
                            ? song.lyricJson!.lines[0].zh
                            : ''),
                    ],
                  ),
          ),
        ),

        // Control buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_localState == SingalongState.idle)
                FilledButton.icon(
                  onPressed: _handleStart,
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Singing'),
                ),
              if (_localState == SingalongState.recording)
                FilledButton.icon(
                  onPressed: _handleStop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop & Score'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                  ),
                ),
              if (_localState == SingalongState.completed)
                FilledButton.icon(
                  onPressed: () => setState(() => _localState = SingalongState.idle),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStateIndicator() {
    switch (_localState) {
      case SingalongState.idle:
        return Column(
          children: [
            Icon(Icons.mic_none, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('Press Start to begin singing'),
          ],
        );
      case SingalongState.recording:
        return Column(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            const Text('Recording...'),
          ],
        );
      case SingalongState.paused:
        return const Text('Paused');
      case SingalongState.completed:
        return const Text('Done!');
    }
  }
}
