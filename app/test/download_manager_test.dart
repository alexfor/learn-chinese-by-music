import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learn_chinese_by_music/features/songs/download_manager.dart';

void main() {
  group('DownloadManager', () {
    test('initial state has no downloads', () {
      final container = ProviderContainer();
      final state = container.read(downloadManagerProvider);
      expect(state.downloads, isEmpty);
      container.dispose();
    });

    test('startDownload adds a pending download', () {
      final container = ProviderContainer();
      final notifier = container.read(downloadManagerProvider.notifier);

      notifier.startDownload('song-1');

      final state = container.read(downloadManagerProvider);
      expect(state.downloads.length, equals(1));
      expect(state.downloads['song-1'], equals(DownloadStatus.downloading));
      container.dispose();
    });

    test('completeDownload updates status to downloaded', () {
      final container = ProviderContainer();
      final notifier = container.read(downloadManagerProvider.notifier);

      notifier.startDownload('song-1');
      notifier.completeDownload('song-1');

      final state = container.read(downloadManagerProvider);
      expect(state.downloads['song-1'], equals(DownloadStatus.downloaded));
      container.dispose();
    });

    test('failDownload updates status to failed', () {
      final container = ProviderContainer();
      final notifier = container.read(downloadManagerProvider.notifier);

      notifier.startDownload('song-1');
      notifier.failDownload('song-1');

      final state = container.read(downloadManagerProvider);
      expect(state.downloads['song-1'], equals(DownloadStatus.failed));
      container.dispose();
    });

    test('removeDownload clears the download', () {
      final container = ProviderContainer();
      final notifier = container.read(downloadManagerProvider.notifier);

      notifier.startDownload('song-1');
      notifier.completeDownload('song-1');
      notifier.removeDownload('song-1');

      final state = container.read(downloadManagerProvider);
      expect(state.downloads, isEmpty);
      container.dispose();
    });

    test('isDownloaded returns correct status', () {
      final container = ProviderContainer();
      final notifier = container.read(downloadManagerProvider.notifier);

      expect(notifier.isDownloaded('song-1'), isFalse);

      notifier.startDownload('song-1');
      notifier.completeDownload('song-1');

      expect(notifier.isDownloaded('song-1'), isTrue);
      container.dispose();
    });
  });
}
