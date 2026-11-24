/// 写作类错误对应的「知识点」
///
/// 用途：历史统计只统计写作的知识点（第二虚拟式、动词变位错误等），
/// 不统计客观题对错。AI 评分时从这份固定枚举里挑一个写进 corrections[].knowledge，
/// 存储与统计都用 [code]（稳定、可序列化），界面显示 [titleZh]。
enum WritingKnowledge {
  konjunktivII('konjunktiv_ii', '第二虚拟式'),
  verbConjugation('verb_conjugation', '动词变位'),
  verbTense('verb_tense', '时态'),
  caseArticle('case_article', '格与冠词'),
  preposition('preposition', '介词搭配'),
  wordOrder('word_order', '语序'),
  adjectiveDeclension('adjective_declension', '形容词变格'),
  nounGender('noun_gender', '名词性数与复数'),
  spelling('spelling', '拼写与大小写'),
  vocabularyChoice('vocabulary_choice', '用词选择'),
  naturalness('naturalness', '表达自然度'),
  taskCompletion('task_completion', '任务完成度'),
  other('other', '其他');

  const WritingKnowledge(this.code, this.titleZh);

  /// 持久化编码（写入 corrections[].knowledge）
  final String code;

  /// 中文名（i18n key）
  final String titleZh;

  static WritingKnowledge fromCode(String code) => WritingKnowledge.values
      .firstWhere((k) => k.code == code, orElse: () => WritingKnowledge.other);

  /// 给 AI 的候选清单（code: 中文名）
  static String get promptList =>
      WritingKnowledge.values.map((k) => '${k.code}(${k.titleZh})').join('、');
}
