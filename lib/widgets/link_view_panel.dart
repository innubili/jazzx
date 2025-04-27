import 'package:flutter/material.dart';
//import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/link.dart';
//import '../services/youtube_service.dart';
//import '../screens/link_search_screen.dart';
import '../widgets/youtube_player_widget.dart';
import 'spotify_player_widget.dart';

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
  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant LinkViewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.link.link != oldWidget.link.link ||
        widget.link.kind != oldWidget.link.kind) {
      _initControllers();
    }
  }

  void _initControllers() {
    if (widget.link.kind == LinkKind.spotify) {
      final isPlaylist = widget.link.category == LinkCategory.playlist;
      final uriId =
          isPlaylist
              ? _extractSpotifyPlaylistId(widget.link.link)
              : _extractSpotifyTrackId(widget.link.link);

      if (uriId.isNotEmpty) {
        final embedUrl =
            'https://open.spotify.com/embed/${isPlaylist ? 'playlist' : 'track'}/$uriId';
        // Remove unused variable 'controller'
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(embedUrl));
      }
    }
  }

  String _extractSpotifyTrackId(String url) {
    final uri = Uri.tryParse(url);
    return uri?.pathSegments.contains('track') == true
        ? uri!.pathSegments.last
        : '';
  }

  String _extractSpotifyPlaylistId(String url) {
    final uri = Uri.tryParse(url);
    return uri?.pathSegments.contains('playlist') == true
        ? uri!.pathSegments.last
        : '';
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget player;

    if (widget.link.kind == LinkKind.youtube) {
      player = YouTubePlayerWidget(youtubeUrl: widget.link.link);
    } else if (widget.link.kind == LinkKind.spotify) {
      player = SpotifyPlayerWidget(
        url: widget.link.link,
        isPlaylist: widget.link.category == LinkCategory.playlist,
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
