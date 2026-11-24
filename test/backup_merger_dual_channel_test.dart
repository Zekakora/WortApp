import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/services/sync/backup_merger.dart';

/// 双通道 LWW 合并测试：
/// - 学习通道（sm2/proficiency/lastStudyDate）：按学习状态时间戳静默新者胜
/// - 内容通道（chinese/example/tags/变形）：按 word.updatedAt 新者胜，
///   仅两端都编辑过词义内容才判定冲突弹窗
/// - 收藏取并集、每日统计按日期取较大值、缓存内容相同则跳过
void main() {
  // 时间线：T0 创建 → T1 上次同步 → T1.5 云端备份导出 → T2/T3 两端后续活动
  const t0 = '2026-01-01T08:00:00.000Z';
  const t1 = '2026-01-02T08:00:00.000Z';
  const t15 = '2026-01-03T08:00:00.000Z';
  const t2 = '2026-01-04T08:00:00.000Z';
  const t3 = '2026-01-05T08:00:00.000Z';

  Map<String, dynamic> makeBackup({
    required Map<String, dynamic> word,
    String? exportedAt,
  }) {
    return {
      'version': 4,
      'exportedAt': exportedAt,
      'deckCount': 1,
      'wordCount': 1,
      'decks': [
        {
          'name': 'A1',
          'description': '',
          'createdAt': t0,
          'updatedAt': t0,
          'words': [word],
        },
      ],
    };
  }

  Map<String, dynamic> makeWord({
    required String chinese,
    required String updatedAt,
    String? sm2UpdatedAt,
    int repetitionN = 0,
    int proficiency = 0,
    bool isFavorite = false,
    Map<String, dynamic>? conjugation,
  }) {
    return {
      'german': 'Haus',
      'chinese': chinese,
      'article': 'das',
      'example': null,
      'proficiency': proficiency,
      'isFavorite': isFavorite,
      'createdAt': t0,
      'updatedAt': updatedAt,
      if (sm2UpdatedAt != null)
        'sm2': {
          'repetitionN': repetitionN,
          'intervalDays': 1.0,
          'easeFactor': 2.5,
          'nextReview': t3,
          'lastReview': sm2UpdatedAt,
          'totalReviews': repetitionN,
          'correctStreak': repetitionN,
          'createdAt': t0,
          'updatedAt': sm2UpdatedAt,
        },
      'conjugation': ?conjugation,
    };
  }

  group('双通道合并：复习 vs 编辑', () {
    test('一端仅复习（sm2 更新、内容未动），另一端编辑词义 → 静默合并不弹窗', () {
      // 本地：只复习过（sm2.updatedAt=T2），word.updatedAt 保持创建时间
      final local = makeWord(
        chinese: '房子',
        updatedAt: t0,
        sm2UpdatedAt: t2,
        repetitionN: 3,
        proficiency: 2,
      );
      // 云端：编辑了词义（word.updatedAt=T3），从未复习
      final cloud = makeWord(
        chinese: '房子（修订）',
        updatedAt: t3,
        sm2UpdatedAt: t0,
      );

      final result = BackupMerger.merge(
        local: makeBackup(word: local, exportedAt: t15),
        cloud: makeBackup(word: cloud, exportedAt: t15),
        lastSyncAt: DateTime.parse(t1),
      );

      expect(result.hasConflicts, isFalse,
          reason: '复习 + 编辑词义不应视为内容冲突');
      final merged =
          (result.mergedBackup['decks'] as List).first['words'] as List;
      final word = merged.first as Map<String, dynamic>;
      expect(word['chinese'], '房子（修订）',
          reason: '词义内容应取编辑过的一侧（云端）');
      expect((word['sm2'] as Map)['repetitionN'], 3,
          reason: '学习进度应取复习过的一侧（本地）');
      expect(word['proficiency'], 2);
    });

    test('两端都复习、内容一致 → 无冲突，学习取更新时间新者', () {
      final local = makeWord(
        chinese: '房子',
        updatedAt: t0,
        sm2UpdatedAt: t2,
        repetitionN: 3,
      );
      final cloud = makeWord(
        chinese: '房子',
        updatedAt: t0,
        sm2UpdatedAt: t3,
        repetitionN: 5,
      );

      final result = BackupMerger.merge(
        local: makeBackup(word: local, exportedAt: t15),
        cloud: makeBackup(word: cloud, exportedAt: t15),
        lastSyncAt: DateTime.parse(t1),
      );

      expect(result.hasConflicts, isFalse);
      final word =
          ((result.mergedBackup['decks'] as List).first['words'] as List)
              .first as Map<String, dynamic>;
      expect((word['sm2'] as Map)['repetitionN'], 5,
          reason: '学习状态应取最近复习的一侧');
    });
  });

  group('双通道合并：内容冲突', () {
    test('两端都编辑了词义且内容不同 → 判定冲突，未选择时不写库', () {
      final local = makeWord(chinese: '房子A', updatedAt: t2);
      final cloud = makeWord(chinese: '房子B', updatedAt: t3);

      final result = BackupMerger.merge(
        local: makeBackup(word: local, exportedAt: t15),
        cloud: makeBackup(word: cloud, exportedAt: t15),
        lastSyncAt: DateTime.parse(t1),
      );

      expect(result.hasConflicts, isTrue);
      expect(result.conflicts.single.german, 'Haus');
    });

    test('两端都编辑过、云端备份在本地编辑后才导出 → 仍判定冲突（锚点用上次同步时间）', () {
      // 时间线：T1 上次同步 → 本地 01-03 12:00 编辑 → 云端 01-03 18:00 编辑
      // 并同步（云端备份导出时间 t3 晚于本地编辑）→ 本次本地同步
      final local =
          makeWord(chinese: '房子A', updatedAt: '2026-01-03T12:00:00.000Z');
      final cloud =
          makeWord(chinese: '房子B', updatedAt: '2026-01-03T18:00:00.000Z');

      final result = BackupMerger.merge(
        local: makeBackup(word: local, exportedAt: t3),
        cloud: makeBackup(word: cloud, exportedAt: t3),
        lastSyncAt: DateTime.parse(t1),
      );

      expect(result.hasConflicts, isTrue,
          reason: '两端都在上次同步之后编辑过词义，应弹窗选择而非静默覆盖本地编辑');
    });

    test('首次同步（无上次同步锚点）→ 不判冲突，按 LWW 合并', () {
      // 云端单词更新于其备份导出时间之前（现实不变量），本地随后才编辑
      final local = makeWord(chinese: '房子A', updatedAt: t3);
      final cloud = makeWord(chinese: '房子B', updatedAt: t15);

      final result = BackupMerger.merge(
        local: makeBackup(word: local, exportedAt: t15),
        cloud: makeBackup(word: cloud, exportedAt: t15),
      );

      expect(result.hasConflicts, isFalse,
          reason: '首次同步没有对齐锚点，不应把全部内容都弹成冲突');
      final word =
          ((result.mergedBackup['decks'] as List).first['words'] as List)
              .first as Map<String, dynamic>;
      expect(word['chinese'], '房子A', reason: '无冲突时取 updatedAt 新者（本地）');
    });

    test('冲突解决后：词义取所选一侧，学习进度仍按学习通道合并不丢失', () {
      final local = makeWord(
        chinese: '房子A',
        updatedAt: t2,
        sm2UpdatedAt: t3,
        repetitionN: 7,
      );
      final cloud = makeWord(chinese: '房子B', updatedAt: t2);

      // 以本地为准：词义取本地，但复习进度（本地 sm2 更新）仍然保留
      final localWins = BackupMerger.merge(
        local: makeBackup(word: local, exportedAt: t15),
        cloud: makeBackup(word: cloud, exportedAt: t15),
        lastSyncAt: DateTime.parse(t1),
        resolution: ConflictResolution.local,
      );
      expect(localWins.hasConflicts, isTrue);
      var word = ((localWins.mergedBackup['decks'] as List).first['words']
              as List)
          .first as Map<String, dynamic>;
      expect(word['chinese'], '房子A');
      expect((word['sm2'] as Map)['repetitionN'], 7,
          reason: '选择词义方向不应丢失复习进度');

      // 以云端为准：词义取云端
      final cloudWins = BackupMerger.merge(
        local: makeBackup(word: local, exportedAt: t15),
        cloud: makeBackup(word: cloud, exportedAt: t15),
        lastSyncAt: DateTime.parse(t1),
        resolution: ConflictResolution.cloud,
      );
      word = ((cloudWins.mergedBackup['decks'] as List).first['words'] as List)
          .first as Map<String, dynamic>;
      expect(word['chinese'], '房子B');
      expect((word['sm2'] as Map)['repetitionN'], 7,
          reason: '选择云端词义时本地复习进度依然保留');
    });
  });

  group('双通道合并：统计与收藏', () {
    test('每日统计按日期取较大值，收藏取并集', () {
      final local = makeWord(chinese: '房子', updatedAt: t0, isFavorite: true);
      local['stats'] = [
        {'date': t0, 'appearances': 5, 'errors': 2},
      ];
      final cloud = makeWord(chinese: '房子', updatedAt: t0);
      cloud['stats'] = [
        {'date': t0, 'appearances': 3, 'errors': 1},
        {'date': t1, 'appearances': 2, 'errors': 0},
      ];

      final result = BackupMerger.merge(
        local: makeBackup(word: local, exportedAt: t15),
        cloud: makeBackup(word: cloud, exportedAt: t15),
        lastSyncAt: DateTime.parse(t1),
      );

      expect(result.hasConflicts, isFalse);
      final word =
          ((result.mergedBackup['decks'] as List).first['words'] as List)
              .first as Map<String, dynamic>;
      expect(word['isFavorite'], isTrue, reason: '收藏取并集');
      final stats = (word['stats'] as List).cast<Map<String, dynamic>>();
      expect(stats, hasLength(2));
      final t0Entry = stats.firstWhere((s) => s['date'] == t0);
      expect(t0Entry['appearances'], 5, reason: '同日出现次数取较大值');
      expect(t0Entry['errors'], 2, reason: '同日错误数取较大值');
    });
  });

  group('缓存合并', () {
    test('两端变位缓存内容相同 → 直接保留不覆盖', () {
      final local = makeWord(chinese: '房子', updatedAt: t0, sm2UpdatedAt: t2);
      local['conjugation'] = {'json': '{"a":1}', 'updatedAt': t3};
      final cloud = makeWord(chinese: '房子', updatedAt: t0, sm2UpdatedAt: t2);
      cloud['conjugation'] = {'json': '{"a":1}', 'updatedAt': t2};

      final result = BackupMerger.merge(
        local: makeBackup(word: local, exportedAt: t15),
        cloud: makeBackup(word: cloud, exportedAt: t15),
        lastSyncAt: DateTime.parse(t1),
      );

      final word =
          ((result.mergedBackup['decks'] as List).first['words'] as List)
              .first as Map<String, dynamic>;
      expect((word['conjugation'] as Map)['json'], '{"a":1}');
    });

    test('两端变位缓存内容不同 → 取更新时间新者', () {
      final local = makeWord(chinese: '房子', updatedAt: t0, sm2UpdatedAt: t2);
      local['conjugation'] = {'json': '{"a":1}', 'updatedAt': t3};
      final cloud = makeWord(chinese: '房子', updatedAt: t0, sm2UpdatedAt: t2);
      cloud['conjugation'] = {'json': '{"b":2}', 'updatedAt': t2};

      final result = BackupMerger.merge(
        local: makeBackup(word: local, exportedAt: t15),
        cloud: makeBackup(word: cloud, exportedAt: t15),
        lastSyncAt: DateTime.parse(t1),
      );

      final word =
          ((result.mergedBackup['decks'] as List).first['words'] as List)
              .first as Map<String, dynamic>;
      expect((word['conjugation'] as Map)['json'], '{"a":1}',
          reason: '内容不同时取 updatedAt 新者');
    });
  });
}
