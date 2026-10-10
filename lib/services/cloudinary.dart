/// Cloudinary delivery transforms. Uploads already store a 1600px
/// q_auto master; requesting sized renditions cuts transfer bytes
/// (~70% on list thumbs) with zero backend change. Non-Cloudinary
/// URLs pass through untouched, as do already-transformed ones.
String cloudinaryThumb(String url, {int width = 800}) {
  final u = url.trim();
  if (u.isEmpty || !u.contains('res.cloudinary.com')) return u;
  const marker = '/image/upload/';
  final i = u.indexOf(marker);
  if (i < 0) return u;
  final head = u.substring(0, i + marker.length);
  final tail = u.substring(i + marker.length);
  if (tail.startsWith('f_auto')) return u;
  return '$head${'f_auto,q_auto,w_$width'}/$tail';
}
