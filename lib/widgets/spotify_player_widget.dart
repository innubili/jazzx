import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SpotifyPlayerWidget extends StatefulWidget {
  final String url;
  final bool isPlaylist;

  const SpotifyPlayerWidget({
    super.key,
    required this.url,
    required this.isPlaylist,
  });

  @override
  State<SpotifyPlayerWidget> createState() => _SpotifyPlayerWidgetState();
}

class _SpotifyPlayerWidgetState extends State<SpotifyPlayerWidget> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant SpotifyPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _initController();
    }
  }

  void _initController() {
    final uriId = _extractSpotifyId(widget.url, widget.isPlaylist);
    final embedUrl =
        'https://open.spotify.com/embed/${widget.isPlaylist ? 'playlist' : 'track'}/$uriId';

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(embedUrl));
  }

  String _extractSpotifyId(String url, bool isPlaylist) {
    final uri = Uri.tryParse(url);
    return uri?.pathSegments.contains(isPlaylist ? 'playlist' : 'track') == true
        ? uri!.pathSegments.last
        : '';
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: WebViewWidget(controller: _controller),
    );
  }
}
