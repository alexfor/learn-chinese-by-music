import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/song.dart';
import '../../services/audio_service.dart';
import '../../shared/lrc_parser.dart';
import '../songs/song_providers.dart';
import 'player_controller.dart';
import 'lyric_widget.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String songId;
  const PlayerScreen({super.key, required this.songId});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  final _controllerLogic = PlayerControllerLogic();
  bool _audioInitialized = false;

  @override
  void dispose() {
    ref.read(audioServiceProvider).dispose();
    super.dispose();
  }

  Future<void> _initAudio(String url) async {
    if (_audioInitialized) return;
    _audioInitialized = true;
    final audio = ref.read(audioServiceProvider);
    try {
      await audio.setUrl(url);
      _listenToPosition();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load audio: $e')),
        );
      }
    }
  }

  void _listenToPosition() {
    final audio = ref.read(audioServiceProvider);
    audio.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _controllerLogic.updatePosition(position.inMilliseconds);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(songDetailProvider(widget.songId));

    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load song',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () =>
                    ref.invalidate(songDetailProvider(widget.songId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (song) {
          _setupLrcAndAudio(song);
          return _PlayerContent(
            song: song,
            controllerLogic: _controllerLogic,
            audioService: ref.read(audioServiceProvider),
            onLineTap: (index) {
              final target = _controllerLogic.seekTargetMs(index);
              if (target != null) {
                ref.read(audioServiceProvider).seek(Duration(milliseconds: target));
              }
            },
          );
        },
      ),
    );
  }

  void _setupLrcAndAudio(SongDetail song) {
    if (song.lrc != null) {
      final lines = LrcParser.parse(song.lrc!);
      _controllerLogic.setLrcLines(lines);
    }

    final audioUrl = song.fullSongUrl ?? song.vocalUrl;
    if (audioUrl != null) {
      _initAudio(audioUrl);
    }
  }
}

class _PlayerContent extends StatelessWidget {
  final SongDetail song;
  final PlayerControllerLogic controllerLogic;
  final AudioService audioService;
  final void Function(int index)? onLineTap;

  const _PlayerContent({
    required this.song,
    required this.controllerLogic,
    required this.audioService,
    this.onLineTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Song info
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(song.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('${song.style} • difficulty ${song.difficulty.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),

        // Lyrics
        Expanded(
          child: song.lyricJson != null
              ? LyricWidget(
                  lyricJson: song.lyricJson!,
                  currentLineIndex: controllerLogic.currentLineIndex,
                  onLineTap: onLineTap,
                )
              : const Center(child: Text('No lyrics available')),
        ),

        // Progress bar + controls
        _PlayerControls(audioService: audioService),
      ],
    );
  }
}

class _PlayerControls extends StatefulWidget {
  final AudioService audioService;
  const _PlayerControls({required this.audioService});

  @override
  State<_PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<_PlayerControls> {
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    widget.audioService.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    widget.audioService.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });
    widget.audioService.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _duration?.inMilliseconds ?? 1;
    final positionMs = _position.inMilliseconds.clamp(0, totalMs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: totalMs > 0 ? positionMs / totalMs : 0,
            onChanged: (v) {
              widget.audioService.seek(Duration(milliseconds: (v * totalMs).round()));
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position)),
              Text(_formatDuration(_duration ?? Duration.zero)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                iconSize: 32,
                onPressed: () {
                  final newPos = _position - const Duration(seconds: 10);
                  widget.audioService.seek(
                    newPos < Duration.zero ? Duration.zero : newPos,
                  );
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                iconSize: 64,
                onPressed: () {
                  if (_isPlaying) {
                    widget.audioService.pause();
                  } else {
                    widget.audioService.play();
                  }
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10),
                iconSize: 32,
                onPressed: () {
                  final maxPos = _duration ?? Duration.zero;
                  final newPos = _position + const Duration(seconds: 10);
                  widget.audioService.seek(
                    newPos > maxPos ? maxPos : newPos,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
