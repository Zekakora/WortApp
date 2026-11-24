/// 连续打卡天数计算
///
/// 判定规则：
/// - 传入的日期集合视为「已打卡日期」（study_stats 表中存在答题记录的日期）
/// - 若今天已打卡，从今天开始向前连续计数；
///   若今天未打卡但昨天已打卡，从昨天开始计数（当天尚未学习不算断签）；
///   最近打卡日早于昨天则视为断签，返回 0
/// - 重复日期与乱序输入会自动去重排序，不影响结果
int calculateCheckInStreak(Iterable<DateTime> studyDates, DateTime now) {
  final days = studyDates
      .map(_dateOnly)
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));
  if (days.isEmpty) return 0;

  final today = _dateOnly(now);
  final yesterday = _dayBefore(today);
  final latest = days.first;
  if (latest != today && latest != yesterday) return 0;

  var streak = 0;
  var expected = latest;
  for (final day in days) {
    if (day != expected) break;
    streak++;
    expected = _dayBefore(expected);
  }
  return streak;
}

/// 归一到当日零点（本地时区）
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 前一天零点（用 Date 构造自动处理跨月/跨年，避免夏令时偏移问题）
DateTime _dayBefore(DateTime d) => DateTime(d.year, d.month, d.day - 1);
