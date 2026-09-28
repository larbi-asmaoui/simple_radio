/// Podcast descriptions arrive as HTML; we only render plain text.
String stripHtml(String input) {
  var text = input
      .replaceAll(RegExp(r'<br\s*/?>|</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '');
  const entities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
    '&rsquo;': '’',
    '&lsquo;': '‘',
    '&ldquo;': '“',
    '&rdquo;': '”',
    '&hellip;': '…',
    '&mdash;': '—',
    '&ndash;': '–',
  };
  entities.forEach((k, v) => text = text.replaceAll(k, v));
  text = text.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (m) => String.fromCharCode(int.parse(m[1]!)),
  );
  return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Sep 21, 2026"
String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// "1 h 05 min", "42 min"
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '${d.inMinutes.clamp(1, 59)} min';
  return '$h h ${m.toString().padLeft(2, '0')} min';
}

/// Player clock: "4:07", "1:02:09".
String formatClock(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
