import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DownloadStatus { downloading, downloaded, failed }

class DownloadState {
  final Map<String, DownloadStatus> downloads;

  const DownloadState({this.downloads = const {}});

  DownloadState copyWith({Map<String, DownloadStatus>? downloads}) {
    return DownloadState(downloads: downloads ?? this.downloads);
  }
}

final downloadManagerProvider =
    NotifierProvider<DownloadManager, DownloadState>(
  DownloadManager.new,
);

class DownloadManager extends Notifier<DownloadState> {
  @override
  DownloadState build() => const DownloadState();

  void startDownload(String songId) {
    state = state.copyWith(
      downloads: {...state.downloads, songId: DownloadStatus.downloading},
    );
  }

  void completeDownload(String songId) {
    state = state.copyWith(
      downloads: {...state.downloads, songId: DownloadStatus.downloaded},
    );
  }

  void failDownload(String songId) {
    state = state.copyWith(
      downloads: {...state.downloads, songId: DownloadStatus.failed},
    );
  }

  void removeDownload(String songId) {
    final updated = Map<String, DownloadStatus>.from(state.downloads)
      ..remove(songId);
    state = state.copyWith(downloads: updated);
  }

  bool isDownloaded(String songId) {
    return state.downloads[songId] == DownloadStatus.downloaded;
  }
}
