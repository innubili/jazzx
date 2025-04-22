import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/link.dart';

class LinkWidget extends StatelessWidget {
  final Link link;
  final VoidCallback onViewPressed;
  final ValueChanged<Link> onUpdated;
  final VoidCallback onDelete;
  final String? highlightQuery;
  final bool readOnly;

  const LinkWidget({
    super.key,
    required this.link,
    required this.onViewPressed,
    required this.onUpdated,
    required this.onDelete,
    this.highlightQuery,
    this.readOnly = false,
  });

  Widget _iconForKind(LinkKind kind) {
    switch (kind) {
      case LinkKind.youtube:
        return const Icon(FontAwesomeIcons.youtube);
      case LinkKind.spotify:
        return const Icon(FontAwesomeIcons.spotify);
      case LinkKind.media:
        return const Icon(Icons.audiotrack);
      case LinkKind.skool:
        return const Icon(Icons.school);
      case LinkKind.soundslice:
        return const Icon(Icons.slideshow);
      case LinkKind.iReal:
        return SvgPicture.asset(
          'assets/icons/iRP_icon.svg',
          height: 24,
          width: 24,
        );
      default:
        return const Icon(Icons.link);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      leading: IconButton(
        icon: _iconForKind(link.kind),
        tooltip: 'Open Link',
        onPressed: onViewPressed,
      ),
      title: Text(
        '${link.key} • ${link.name}',
        style: const TextStyle(fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      trailing:
          readOnly
              ? null
              : IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: const Text(
                            'Are you sure you want to delete this link?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) onDelete();
                },
              ),
    );
  }
}
