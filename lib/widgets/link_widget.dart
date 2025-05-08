import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/link.dart';
import 'link_editor_widgets.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import 'package:logging/logging.dart';
import '../utils/utils.dart';
import 'link_view_panel.dart';

class LinkWidget extends StatelessWidget {
  final Link link;
  final VoidCallback onOpenViewer; // opens the viewer
  final VoidCallback onCloseViewer; // closes the viewer (if open)
  final bool isViewerOpen;
  //final bool onViewPressed; // tells whether it's currently open
  final ValueChanged<Link> onUpdated;
  final VoidCallback onDelete;
  final String? highlightQuery;
  final bool readOnly;

  LinkWidget({
    super.key,
    required this.link,
    required this.onOpenViewer,
    required this.onCloseViewer,
    required this.isViewerOpen,
    //required this.onViewPressed,
    required this.onUpdated,
    required this.onDelete,
    this.highlightQuery,
    this.readOnly = false,
  });

  final log = Logger('LinkWidget');

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

  Future<void> _handleIconTap(BuildContext context) async {
    log.info(
      'YouTube Icon tapped for link: ${prettyPrintJson({'key': link.key, 'name': link.name, 'kind': link.kind.toString(), 'category': link.category.toString(), 'url': link.link, 'isViewerOpen': isViewerOpen, 'readOnly': readOnly})}',
    );
    if (link.category == LinkCategory.playlist) {
      final uri = Uri.tryParse(link.link);
      if (uri != null) await launchUrl(uri);
    } else if (isViewerOpen) {
      onCloseViewer();
    } else {
      onOpenViewer();
    }
  }

  Future<void> _handleTextTap(BuildContext context) async {
    if (isViewerOpen) {
      onCloseViewer();
      await Future.delayed(const Duration(milliseconds: 150));
      if (!context.mounted) return;
    }
    final edited = await showDialog<Link?>(
      context: context,
      builder: (_) => LinkConfirmationDialog(initialLink: link),
    );
    await Future.delayed(const Duration(milliseconds: 150));
    if (!context.mounted) return;
    if (edited != null) {
      onUpdated(edited);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          leading: IconButton(
            icon: _iconForKind(link.kind),
            tooltip: 'toggle viewer',
            onPressed: () => _handleIconTap(context),
          ),
          title: GestureDetector(
            onTap: readOnly ? null : () => _handleTextTap(context),
            child: Text(
              '${link.key} • ${link.name}',
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
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
                              (context) => AlertDialog(
                                title: const Text('Delete Link'),
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
                        if (!context.mounted) return;
                        if (confirm == true) {
                          onDelete();
                          // Also update provider if available
                          final userProfileProvider =
                              Provider.of<UserProfileProvider>(
                                context,
                                listen: false,
                              );
                          final song = userProfileProvider.profile?.songs[link.name];
                          if (song != null) {
                            userProfileProvider.removeSongLink(link.name, link.key);
                          }
                        }
                      },
                    ),
        ),
        if (isViewerOpen)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: LinkViewPanel(
              link: link,
              onButtonPressed: onCloseViewer,
              buttonText: 'Close',
            ),
          ),
      ],
    );
  }
}
