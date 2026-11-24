import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/algorithms/sm2_algorithm.dart';

void main() {
  group('SM2Algorithm 模糊（quality=2）部分遗忘处理', () {
    test('模糊不重置重复序列，间隔压回 1 天', () {
      final result = SM2Algorithm.calculate(
        quality: 2,
        currentN: 5,
        currentInterval: 30,
        currentEF: 2.5,
      );

      expect(result.repetitionN, 5, reason: '保留重复序列，不清零');
      expect(result.intervalDays, 1, reason: '间隔压回 1 天');
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(
        result.nextReview.day,
        tomorrow.day,
        reason: '下次复习为明天（与结果生成时刻一致）',
      );
    });

    test('忘记（quality=0）仍完全重置', () {
      final result = SM2Algorithm.calculate(
        quality: 0,
        currentN: 5,
        currentInterval: 30,
        currentEF: 2.5,
      );

      expect(result.repetitionN, 0, reason: '忘记重置序列');
      expect(result.intervalDays, 1);
    });

    test('模糊轻微降低简易度因子', () {
      final result = SM2Algorithm.calculate(
        quality: 2,
        currentN: 3,
        currentInterval: 10,
        currentEF: 2.5,
      );

      expect(result.easeFactor, lessThan(2.5), reason: 'EF 微降');
      expect(result.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('模糊后答对（good）延续序列', () {
      final partial = SM2Algorithm.calculate(
        quality: 2,
        currentN: 5,
        currentInterval: 30,
        currentEF: 2.5,
      );

      final after = SM2Algorithm.calculate(
        quality: 4,
        currentN: partial.repetitionN,
        currentInterval: partial.intervalDays,
        currentEF: partial.easeFactor,
      );

      expect(after.repetitionN, 6, reason: '序列从保留值继续 +1');
    });
  });
}
