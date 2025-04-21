import 'package:flutter/material.dart';
import '../screens/link_search_screen.dart';

class SearchResultsList extends StatelessWidget {
  final List<SearchResult> results;
  final ValueChanged<SearchResult> onSelected;
  final SearchResult? selected;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.onSelected,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = results[index];
        final isActive = selected?.url == result.url;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          leading:
              result.thumbnailUrl != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      result.thumbnailUrl!,
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                  : const Icon(Icons.music_video, size: 40),
          title: Text(
            result.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          tileColor: isActive ? Colors.deepPurple.shade50 : null,
          // trailing: Icon(
          //   isActive ? Icons.visibility : Icons.visibility_outlined,
          //   color: isActive ? Colors.deepPurple : null,
          // ),
          onTap: () => onSelected(result),
        );
      },
    );
  }
}
