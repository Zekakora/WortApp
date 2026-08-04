import 'dart:math';

/// SM-2 算法核心实现
///
/// 基于 SuperMemo 2 算法，用于间隔重复学习调度
/// 参考: https://supermemo.guru/wiki/SuperMemo_Algorithm:_Two-component_model_of_memory
class SM2Algorithm {
  SM2Algorithm._();

  /// 计算 SM-2 更新结果
  ///
  /// [quality] 评分 0-5:
  ///   0 = 完全忘记
  ///   1 = 错误，但看到答案后记起
  ///   2 = 错误，但答案很熟悉
  ///   3 = 正确，但很费力
  ///   4 = 正确，略有犹豫
  ///   5 = 完美回忆
  ///
  /// [currentN] 当前重复次数
  /// [currentInterval] 当前复习间隔（天）
  /// [currentEF] 当前简易度因子
  static SM2Result calculate({
    required int quality,
    required int currentN,
    required double currentInterval,
    required double currentEF,
  }) {
    assert(quality >= 0 && quality <= 5, 'Quality must be between 0 and 5');

    // 1. 更新简易度因子 EF
    // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    double newEF = currentEF +
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    newEF = max(1.3, newEF); // EF 最小值为 1.3

    int newN;
    double newInterval;

    if (quality < 3) {
      // 忘记 → 重置重复序列
      newN = 0;
      newInterval = 1;
    } else {
      // 正确 → 进入下一阶段
      newN = currentN + 1;
      if (newN == 1) {
        newInterval = 1;
      } else if (newN == 2) {
        newInterval = 6;
      } else {
        newInterval = (currentInterval * newEF).roundToDouble();
      }
    }

    final now = DateTime.now();
    final nextReview = DateTime(now.year, now.month, now.day + newInterval.toInt());

    return SM2Result(
      repetitionN: newN,
      intervalDays: newInterval,
      easeFactor: newEF,
      nextReview: nextReview,
      quality: quality,
    );
  }

  /// 将用户反馈转换为 0-5 分数
  static int feedbackToQuality(FeedbackLevel feedback) {
    switch (feedback) {
      case FeedbackLevel.forgot:
        return 0;
      case FeedbackLevel.hard:
        return 2;
      case FeedbackLevel.good:
        return 4;
      case FeedbackLevel.easy:
        return 5;
    }
  }

  /// 获取反馈按钮的标签
  static String feedbackLabel(FeedbackLevel feedback) {
    switch (feedback) {
      case FeedbackLevel.forgot:
        return '忘记';
      case FeedbackLevel.hard:
        return '模糊';
      case FeedbackLevel.good:
        return '熟悉';
      case FeedbackLevel.easy:
        return '简单';
    }
  }

  /// 获取反馈按钮的描述（显示下次复习时间）
  static String feedbackDescription(FeedbackLevel feedback, SM2Result result) {
    switch (feedback) {
      case FeedbackLevel.forgot:
        return '1 天后复习';
      case FeedbackLevel.hard:
        return '${result.intervalDays.toInt()} 天后复习';
      case FeedbackLevel.good:
        return '${result.intervalDays.toInt()} 天后复习';
      case FeedbackLevel.easy:
        return '${result.intervalDays.toInt()} 天后复习';
    }
  }
}

/// SM-2 计算结果
class SM2Result {
  final int repetitionN;
  final double intervalDays;
  final double easeFactor;
  final DateTime nextReview;
  final int quality;

  const SM2Result({
    required this.repetitionN,
    required this.intervalDays,
    required this.easeFactor,
    required this.nextReview,
    required this.quality,
  });

  @override
  String toString() =>
      'SM2Result(n=$repetitionN, interval=${intervalDays}d, EF=${easeFactor.toStringAsFixed(2)}, next=$nextReview)';
}

/// 用户反馈等级
enum FeedbackLevel {
  forgot, // 忘记
  hard,   // 模糊
  good,   // 熟悉
  easy,   // 简单
}
