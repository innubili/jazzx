import 'package:flutter/material.dart';
import 'package:jazzx_app/models/link_type.dart';
import '../utils/log.dart';

class SongLinkWidget extends StatelessWidget {
  final String link; // The link URL
  final LinkType type; // The type of link (YouTube, iRealPro, etc.)

  const SongLinkWidget({super.key, required this.link, required this.type});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          // Handle tap to open link using url_launcher or custom logic
          log.warning("Open ${type.name} link: $link");
        },
        child: Card(
          elevation: 4,
          child: ListTile(
            leading: Image.asset(type.icon), // Use the icon based on LinkType
            title: Text('Open ${type.name} Link'), // Display the link type name
            subtitle: Text(link), // Show the link URL
            trailing: Icon(Icons.arrow_forward_ios),
          ),
        ),
      ),
    );
  }
}
