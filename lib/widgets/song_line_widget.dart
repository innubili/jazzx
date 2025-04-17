import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/irealpro_provider.dart'; // Assuming this is the name

class SongLineWidget extends StatelessWidget {
  final Song song;
  final void Function(SongLinkType type)? onIconPressed;

  const SongLineWidget({super.key, required this.song, this.onIconPressed});

  @override
  Widget build(BuildContext context) {
    final iconSize = 20.0;
    //  final spacing = 8.0;
    final iRealAvailable = context.watch<IRealProProvider>().isInstalled;

    return Row(
      children: [
        // Song Title
        Expanded(
          child: Text(
            song.title,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        // iReal Pro (only if available and song has link)
        if (song.hasLink(SongLinkType.iRealBackingTrack))
          IconButton(
            icon: const Icon(Icons.music_note),
            iconSize: iconSize,
            tooltip: 'iReal Pro',
            onPressed:
                iRealAvailable
                    ? () => onIconPressed?.call(SongLinkType.iRealBackingTrack)
                    : null, // disabled if not available
          ),

        // YouTube
        if (song.hasLink(SongLinkType.youtubeBackingTrack))
          IconButton(
            icon: const Icon(Icons.play_circle_fill),
            iconSize: iconSize,
            tooltip: 'YouTube',
            onPressed:
                () => onIconPressed?.call(SongLinkType.youtubeBackingTrack),
          ),

        // Spotify
        if (song.hasLink(SongLinkType.spotifyBackingTrack))
          IconButton(
            icon: const Icon(Icons.music_video),
            iconSize: iconSize,
            tooltip: 'Spotify',
            onPressed:
                () => onIconPressed?.call(SongLinkType.spotifyBackingTrack),
          ),

        // Score / PDF
        if (song.hasLink(SongLinkType.pdf) || song.hasLink(SongLinkType.scores))
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            iconSize: iconSize,
            tooltip: 'Score / PDF',
            onPressed:
                () => onIconPressed?.call(
                  song.hasLink(SongLinkType.pdf)
                      ? SongLinkType.pdf
                      : SongLinkType.scores,
                ),
          ),

        const SizedBox(width: 4), // Padding at end
      ],
    );
  }
}
