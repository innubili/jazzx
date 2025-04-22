import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/link.dart';

class LinkViewPanel extends StatefulWidget {
  final Link link;
  final VoidCallback onButtonPressed;
  final String buttonText;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const LinkViewPanel({
    super.key,
    required this.link,
    required this.onButtonPressed,
    required this.buttonText,
    this.onPrev,
    this.onNext,
  });

  @override
  State<LinkViewPanel> createState() => _LinkViewPanelState();
}

class _LinkViewPanelState extends State<LinkViewPanel> {
  YoutubePlayerController? _ytController;

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
    if (widget.link.kind == LinkKind.youtube) {
      final videoId = extractYouTubeVideoId(widget.link.link);
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
  void didUpdateWidget(covariant LinkViewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.link.link != oldWidget.link.link &&
        widget.link.kind == LinkKind.youtube) {
      final newVideoId = extractYouTubeVideoId(widget.link.link);
      _ytController?.loadVideoById(videoId: newVideoId);
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget player;

    if (widget.link.kind == LinkKind.youtube && _ytController != null) {
      player = YoutubePlayerScaffold(
        controller: _ytController!,
        aspectRatio: 16 / 9,
        builder: (context, player) => player,
      );
    } else if (widget.link.kind == LinkKind.spotify) {
      player = ListTile(
        leading: const Icon(Icons.music_note),
        title: Text(widget.link.name),
        subtitle: Text(widget.link.link),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () => launchUrl(Uri.parse(widget.link.link)),
        ),
      );
    } else {
      player = ListTile(
        title: Text(widget.link.name),
        subtitle: Text(widget.link.link),
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
              if (widget.onPrev != null)
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: widget.onPrev,
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.link.link,
                      style: const TextStyle(color: Colors.blue),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: Text(widget.buttonText),
                      onPressed: widget.onButtonPressed,
                    ),
                  ],
                ),
              ),
              if (widget.onNext != null)
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
