import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/link_search_screen.dart';
import '../models/link.dart';

class ResultPreviewPanel extends StatefulWidget {
  final SearchResult result;
  final VoidCallback onAddLink;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const ResultPreviewPanel({
    super.key,
    required this.result,
    required this.onAddLink,
    required this.onPrev,
    required this.onNext,
  });

  @override
  State<ResultPreviewPanel> createState() => _ResultPreviewPanelState();
}

class _ResultPreviewPanelState extends State<ResultPreviewPanel> {
  late YoutubePlayerController _ytController;

  String extractYouTubeVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v']!;
    } else if (uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();

    if (widget.result.kind == LinkKind.youtube) {
      final videoId = extractYouTubeVideoId(widget.result.url);
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          showControls: true,
          strictRelatedVideos: true,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant ResultPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.result.url != oldWidget.result.url &&
        widget.result.kind == LinkKind.youtube) {
      final newVideoId = extractYouTubeVideoId(widget.result.url);
      _ytController.loadVideoById(videoId: newVideoId);
    }
  }

  @override
  void dispose() {
    if (widget.result.kind == LinkKind.youtube) {
      _ytController.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget player;

    if (widget.result.kind == LinkKind.youtube) {
      player = YoutubePlayerScaffold(
        controller: _ytController,
        aspectRatio: 16 / 9,
        builder: (context, player) {
          return player;
        },
      );
    } else if (widget.result.kind == LinkKind.spotify) {
      player = ListTile(
        leading: const Icon(Icons.music_note),
        title: Text(widget.result.title),
        subtitle: Text(widget.result.url),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () => launchUrl(Uri.parse(widget.result.url)),
        ),
      );
    } else {
      player = ListTile(
        title: Text(widget.result.title),
        subtitle: Text(widget.result.url),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          player,
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: widget.onPrev,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.result.url,
                      style: const TextStyle(color: Colors.blue),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text("Add This Link"),
                      onPressed: widget.onAddLink,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: widget.onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
