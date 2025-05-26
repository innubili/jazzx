import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:io';

/// Service to handle incoming shared links and files from other apps on Android/iOS.
class SharingIntentService {
  static final SharingIntentService _instance = SharingIntentService._internal();
  factory SharingIntentService() => _instance;
  SharingIntentService._internal();

  StreamSubscription<List<SharedMediaFile>>? _mediaStreamSub;

  /// Listen for incoming media (files, images, etc). Callbacks provide the shared data.
  void listen({
    required void Function(String link) onLink,
    required void Function(List<SharedMediaFile> files) onMedia,
  }) {
    // Listen for media/file sharing
    _mediaStreamSub = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        // Try to extract a link from any text file or pass to onMedia
        final linkFile = value.firstWhere(
          (file) => file.mimeType?.startsWith('text') == true || file.path.endsWith('.txt'),
          orElse: () => value.first,
        );
        // Attempt to read text content (requires additional implementation)
        if (linkFile.mimeType?.startsWith('text') == true || linkFile.path.endsWith('.txt')) {
          _readTextFileAndExtractLink(linkFile.path).then((link) {
            if (link != null && link.isNotEmpty) {
              onLink(link);
            } else {
              // If no link found, treat as file
              onMedia(value);
            }
          });
        } else {
          onMedia(value);
        }
      }
    });
  }

  /// Optionally fetch initial shared data if app was launched via share.
  Future<void> fetchInitial({
    required void Function(String link) onLink,
    required void Function(List<SharedMediaFile> files) onMedia,
  }) async {
    // Initial media
    final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initialMedia.isNotEmpty) {
      // Try to extract a link from any text file or pass to onMedia
      final linkFile = initialMedia.firstWhere(
        (file) => file.mimeType?.startsWith('text') == true || file.path.endsWith('.txt'),
        orElse: () => initialMedia.first,
      );
      if (linkFile.mimeType?.startsWith('text') == true || linkFile.path.endsWith('.txt')) {
        final link = await _readTextFileAndExtractLink(linkFile.path);
        if (link != null && link.isNotEmpty) {
          onLink(link);
        } else {
          onMedia(initialMedia);
        }
      } else {
        onMedia(initialMedia);
      }
    }
  }

  Future<String?> _readTextFileAndExtractLink(String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();
      final regex = RegExp(r'(https?://[^\s]+)', caseSensitive: false);
      final match = regex.firstMatch(content);
      return match?.group(0);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _mediaStreamSub?.cancel();
  }
}
