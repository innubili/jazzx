import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../utils/utils.dart';

class YouTubePlayerWidget extends StatefulWidget {
  final String youtubeUrl;

  const YouTubePlayerWidget({super.key, required this.youtubeUrl});

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  YoutubePlayerController? _controller;
  Timer? _playTimer;

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
    _initController();
  }

  void _initController() {
    final videoId = extractYouTubeVideoId(widget.youtubeUrl);
    _controller?.close();
    log.info('YTP: ${DateTime.now()} - initializing YouTubePlayerWidget');
    final newController = YoutubePlayerController(
      initialVideoId: videoId,
      params: YoutubePlayerParams(
        autoPlay: true,
        mute: kIsWeb, // Mute if running on web for reliable auto-play
        showFullscreenButton: true,
        showControls: true,
        strictRelatedVideos: true,
      ),
    );
    _controller = newController;

    _playTimer?.cancel();
    _playTimer = Timer(const Duration(milliseconds: 20), () {
      if (mounted && _controller == newController) {
        //log.info('YTP: ${DateTime.now()} - playing YouTubePlayerWidget');
        _controller?.play();
      }
    });
  }

  @override
  void didUpdateWidget(covariant YouTubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.youtubeUrl != oldWidget.youtubeUrl) {
      _initController();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log.info(
      'YTP: ${DateTime.now().toString()} - Building YouTubePlayerWidget',
    );
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 270,
          child:
              _controller == null
                  ? const SizedBox.shrink()
                  : YoutubePlayerIFrame(controller: _controller!),
        ),
      ],
    );
  }
}
