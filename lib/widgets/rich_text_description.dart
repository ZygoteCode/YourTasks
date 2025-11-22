import 'package:fluent_ui/fluent_ui.dart';

class RichTextDescription extends StatelessWidget {
  final String text;
  final Color color;

  const RichTextDescription(
      {super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: color, fontSize: 13, fontFamily: 'Segoe UI'),
        children: _parseMarkdown(text, context),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<InlineSpan> _parseMarkdown(String text, BuildContext context) {
    List<InlineSpan> spans = [];
    final regex = RegExp(
        r'(\*\*[^*]+\*\*)|(__[^_]+__)|(`[^`]+`)|(\*[^*]+\*)|(_[^_]+_)');

    int start = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      String matchText = match.group(0)!;

      if (matchText.startsWith('**') || matchText.startsWith('__')) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ));
      } else if (matchText.startsWith('`')) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Text(
              matchText.substring(1, matchText.length - 1),
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 11),
            ),
          ),
        ));
      } else if (matchText.startsWith('*') || matchText.startsWith('_')) {
        spans.add(TextSpan(
          text: matchText.substring(1, matchText.length - 1),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }
}