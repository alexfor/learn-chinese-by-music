import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

class ShareCard extends StatelessWidget {
  final String songTitle;
  final double score;
  final String? lyricSnippet;

  const ShareCard({
    super.key,
    required this.songTitle,
    required this.score,
    this.lyricSnippet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_note, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            songTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            score.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'points',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (lyricSnippet != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"$lyricSnippet"',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 32),
          Text(
            'Learn Chinese by Music',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a ShareCard offscreen and triggers the system share sheet.
///
/// Usage: wrap your screen content with a [ShareCardOverlay] that holds
/// the [globalKey], then call [captureAndShare] with that key.
class ShareCardOverlay extends StatelessWidget {
  final GlobalKey repaintKey;
  final String songTitle;
  final double score;
  final String? lyricSnippet;

  const ShareCardOverlay({
    super.key,
    required this.repaintKey,
    required this.songTitle,
    required this.score,
    this.lyricSnippet,
  });

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: true,
      child: RepaintBoundary(
        key: repaintKey,
        child: ShareCard(
          songTitle: songTitle,
          score: score,
          lyricSnippet: lyricSnippet,
        ),
      ),
    );
  }
}

/// Must be called after the [ShareCardOverlay] has been built in the widget tree.
/// Returns the image bytes, or null on failure.
Future<Uint8List?> captureCardImage(GlobalKey repaintKey) async {
  try {
    final boundary = repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

/// Capture and share a score card. The [repaintKey] must be attached to a
/// [RepaintBoundary] that is currently in the widget tree.
Future<void> shareScoreCard({
  required GlobalKey repaintKey,
  required String songTitle,
  required double score,
  String? lyricSnippet,
}) async {
  final imageBytes = await captureCardImage(repaintKey);
  if (imageBytes == null) return;

  final dir = Directory.systemTemp;
  final file = File('${dir.path}/share_card.png');
  await file.writeAsBytes(imageBytes);

  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'I scored $score on "$songTitle"!',
  );
}
