import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../models/link.dart';
import '../providers/irealpro_provider.dart';

class SongLineWidget extends StatelessWidget {
  final Song song;
  final void Function(LinkKind kind) onIconPressed;

  const SongLineWidget({
    super.key,
    required this.song,
    required this.onIconPressed,
  });

  @override
  Widget build(BuildContext context) {
    // final iconSize = 20.0;
    final iRealAvailable = context.watch<IRealProProvider>().isInstalled;

    return Row(
      children: [
        Expanded(
          child: Text(
            song.title,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        // iReal Pro
        if (iRealAvailable)
          _linkIcon(
            icon: Icons.music_note,
            tooltip: 'iReal Pro',
            kind: LinkKind.iReal,
            context: context,
          ),

        // YouTube
        _linkIcon(
          icon: Icons.play_circle_fill,
          tooltip: 'YouTube',
          kind: LinkKind.youtube,
          context: context,
        ),

        // Spotify
        _linkIcon(
          icon: Icons.music_video,
          tooltip: 'Spotify',
          kind: LinkKind.spotify,
          context: context,
        ),

        // Score / PDF (default kind: media, category: scores)
        _linkIcon(
          icon: Icons.picture_as_pdf,
          tooltip: 'Score / PDF',
          kind: LinkKind.media,
          context: context,
          category: LinkCategory.scores,
        ),

        const SizedBox(width: 4),
      ],
    );
  }

  Widget _linkIcon({
    required IconData icon,
    required String tooltip,
    required LinkKind kind,
    required BuildContext context,
    LinkCategory? category,
  }) {
    final has = song.links.any((l) => l.kind == kind.name);

    return IconButton(
      icon: Icon(icon),
      iconSize: 20,
      tooltip: tooltip,
      onPressed:
          has
              ? () => onIconPressed(kind)
              : () => _navigateToAddLink(context, kind, category),
    );
  }

  void _navigateToAddLink(
    BuildContext context,
    LinkKind kind, [
    LinkCategory? category,
  ]) {
    Navigator.pushNamed(
      context,
      '/user-songs',
      arguments: {
        'initialScrollToTitle': song.title,
        'expandInitially': true,
        'addLinkForKind': kind.name,
        if (category != null) 'addLinkForCategory': category.name,
      },
    );
  }
}
