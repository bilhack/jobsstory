/// Relative "posted at" label for a job, mirroring LinkedIn's meta line.
String jobPostedLabel(DateTime? createdAt, bool isAr) {
  if (createdAt == null) return '';
  final days = DateTime.now().difference(createdAt).inDays;
  if (isAr) {
    if (days <= 0) return 'نُشر اليوم';
    if (days == 1) return 'نُشر منذ يوم';
    if (days == 2) return 'نُشر منذ يومين';
    return 'نُشر منذ $days أيام';
  }
  if (days <= 0) return 'Posted today';
  if (days == 1) return 'Posted 1 day ago';
  return 'Posted $days days ago';
}