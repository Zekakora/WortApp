/// 训练题目生成提示词（任务书 §4.3）
///
/// 设计要点：
/// - 系统提示里给出**完整 JSON 骨架**，字段名与 `ExerciseSchema` 的解析逻辑一一对应；
/// - 每道题必须自带 `answerKey` / `points` / `explanation`；
/// - 解析用语言跟随应用界面语言（[AppLocale.code]），德语原文永远保留；
/// - 题型差异只体现在「题型说明」段落，骨架共用，避免六套提示词漂移。
library;

import '../../core/i18n/app_localizations.dart';
import '../../data/models/training.dart';

/// 一次生成请求的提示词
class ExercisePrompt {
  final String systemPrompt;
  final String userMessage;

  const ExercisePrompt({required this.systemPrompt, required this.userMessage});
}

/// 提示词构造器
class ExercisePrompts {
  /// 提示词版本（写入 exercises.prompt_version，便于对比不同版本的质量）
  static const String version = 'v1';

  /// 估算输出 token 上限：题目越多、答案越长，需要的空间越大
  static int maxTokensFor(int questionCount, ExerciseType type) {
    final perQuestion = switch (type) {
      ExerciseType.readingComprehension ||
      ExerciseType.listeningComprehension ||
      ExerciseType.readingCloze => 320,
      ExerciseType.sentenceBuilding || ExerciseType.errorCorrection => 460,
      ExerciseType.mixedPractice => 430,
      _ => 260,
    };
    final total = 1200 + perQuestion * questionCount;
    return total.clamp(2048, 8192);
  }

  static ExercisePrompt build({
    required ExerciseType type,
    required CefrLevel level,
    required TrainingDifficulty difficulty,
    required String topic,
    required int questionCount,
    String? vocabularyFocus,
  }) {
    final systemPrompt = [
      '你是德语教学专家，负责为德语学习应用出题。',
      '严格要求：只返回一个 JSON 对象，不要代码块围栏、不要任何解释文字。',
      _difficultyDirective(difficulty),
      _languageDirective(),
      '',
      '通用规则：',
      '1. 德语必须地道、自然、无歧义、语法正确，且严格符合 ${level.code} 等级的词汇与句法难度。',
      '2. 每道题必须有唯一 id（q1、q2…）、题干、标准答案、分值和解析。',
      '3. 标准答案必须能由材料或题干确定推出，不得依赖材料之外的信息。',
      '4. 选择题的选项之间要有明确区分度，不要出现两个都成立的选项。',
      '5. 题量为 $questionCount 题，不得多也不得少。',
      '6. points 用正整数：客观题通常 1 分，写作类题目 10 分。',
      '',
      _typeDirective(type, questionCount),
      '',
      _jsonSkeleton(type),
    ].join('\n');

    final topicText = topic.isEmpty ? '日常生活中的常见话题' : topic;
    final vocabText =
        (vocabularyFocus == null || vocabularyFocus.trim().isEmpty)
        ? ''
        : '\n参考词（来自学习者最近的学习记录，**不是必用词表**）：$vocabularyFocus'
              '\n关于参考词的要求：这些词只作参考，能自然融入时用 1–3 个即可；'
              '不要为了用上它们而堆砌或改变话题，用不上就直接忽略；'
              '不要让这些词左右整体难度（难度仍以等级与难度参数为准）。';

    final userMessage = [
      '请生成一套练习：',
      '- 题型：${type.code}（${type.titleZh}）',
      '- 技能：${type.skill.code}',
      '- 等级：${level.code}',
      '- 难度：${difficulty.code}',
      '- 主题：$topicText（请把主题理解为德语语境下的场景，内容用德语写）',
      '- 题量：$questionCount 题',
      vocabText,
    ].join('\n');

    return ExercisePrompt(systemPrompt: systemPrompt, userMessage: userMessage);
  }

  /// 解析/错误说明的输出语言
  static String _languageDirective() {
    switch (AppLocale.code) {
      case AppLocale.en:
        return 'Language: write all "explanation" fields in English; keep all German stimulus text, prompts, options and answers in German.';
      case AppLocale.de:
        return 'Sprache: Schreibe alle "explanation"-Felder auf Deutsch; der deutsche Materialtext, die Aufgabenstellungen, Optionen und Antworten bleiben auf Deutsch.';
      default:
        return '语言：所有 explanation 解析字段用简体中文书写；材料正文、题干、选项和答案一律用德语。';
    }
  }

  static String _difficultyDirective(TrainingDifficulty difficulty) {
    switch (difficulty) {
      case TrainingDifficulty.easy:
        return '难度（与 CEFR 等级是两个维度，请同时满足）：简单 —— 短句为主，直白提问，答案在材料中直接给出。';
      case TrainingDifficulty.normal:
        return '难度（与 CEFR 等级是两个维度，请同时满足）：普通 —— 长短句结合，需要一定推断，同义改写常见。';
      case TrainingDifficulty.hard:
        return '难度（与 CEFR 等级是两个维度，请同时满足）：困难 —— 含从句与复杂结构，需要综合推断，干扰项较强。';
    }
  }

  /// 题型专属说明
  static String _typeDirective(ExerciseType type, int count) {
    switch (type) {
      case ExerciseType.listeningComprehension:
      case ExerciseType.dialogComprehension:
        return '题型说明：生成一段约 80–140 词的德语听力文本（独白或对话），放在 stimulus.text，'
            'stimulus.kind 填 "audio"。每题给出 3 个德语选项，questionType 用 "single_choice"，'
            'answerKey.correctAnswers 用字母（如 ["B"]）。题目问的是听音频后的理解，不要复述原文。';
      case ExerciseType.dictation:
        return '题型说明：生成 $count 个互相独立的德语句子，每句 8–14 词。'
            '每题的 context 字段放**该句德语原文**（用于朗读），prompt 只写指示语'
            '（例如 "Schreibe den Satz, den du hörst."），**绝对不要在 prompt 里泄露句子内容**。'
            'questionType 用 "dictation"，answerKey.acceptedAnswers 放该句原文（可附一个标点变体）。'
            'stimulus.kind 填 "none"，stimulus.text 留空。';
      case ExerciseType.readingComprehension:
        return '题型说明：生成一篇约 160–260 词的德语短文放在 stimulus.text，stimulus.kind 填 "text"。'
            '每题为 3–4 个德语选项的单选题，questionType 用 "single_choice"，'
            'answerKey.correctAnswers 用字母。问题要覆盖细节、主旨与推断。';
      case ExerciseType.listeningCloze:
        return '题型说明：生成一段约 100–160 词的德语听力文本，放在 stimulus.text，'
            'stimulus.kind 填 "audio_text"（学习者既能播放音频，也能看到挖空文本）。'
            '文本中挖空 $count 处，用 (1) ___、(2) ___ 这样带序号的空位标注。'
            '每题的 prompt 写 "Lücke (n): <含 ___ 的那一句>"，context 放同一个句子，'
            'questionType 用 "fill_blank"，answerKey.acceptedAnswers 放正确答案（最多 3 个等价写法）。'
            '挖空应是听音后能确定的成分（介词、冠词、动词变位、连词），不要挖可有可无的修饰语。';
      case ExerciseType.readingCloze:
        return '题型说明：生成一篇约 120–200 词的德语短文放在 stimulus.text，'
            '其中挖空 $count 处（用三个下划线 ___ 表示），stimulus.kind 填 "text"。'
            '每题的 prompt 是**包含 ___ 的那一句**（不要给整段），context 放同一个句子，'
            'questionType 用 "fill_blank"，answerKey.acceptedAnswers 放正确答案'
            '（若有合理的等价写法，一并放进 acceptedAnswers，最多 3 个）。'
            '挖空应是介词、冠词、动词变位、连词等有唯一或有限答案的成分，不要挖可有可无的修饰语。';
      case ExerciseType.contextVocabulary:
        return '题型说明：每题给一个含目标词的德语句子作为 context，'
            'prompt 写 "Was bedeutet „<目标词>“ in diesem Satz?"，'
            'options 为 3–4 个德语近义解释，answerKey.correctAnswers 用字母。'
            'stimulus.kind 填 "none"，stimulus.text 留空；不要重复同一个目标词。';
      case ExerciseType.trueFalseReading:
        return '题型说明：生成一篇约 120–200 词的德语短文放在 stimulus.text，stimulus.kind 填 "text"。'
            '每题为一句德语陈述（prompt），questionType 用 "true_false"，'
            'answerKey.acceptedAnswers 只用 "richtig" 或 "falsch"（全篇至少各一个，避免全对或全错）。';
      case ExerciseType.headingMatching:
        return '题型说明：生成 $count 个德语段落（约 250–400 词总量），放在 stimulus.text，'
            '每段以 "(1) "、"(2) " 这样的编号开头并用换行分隔。每题对应其中一段：'
            'context 放该段原文，prompt 写 "Welche Überschrift passt zu Absatz (n)?"，'
            'options 为 4 个德语标题（其中只有 1 个正确，其余为其他段落的干扰项），'
            'questionType 用 "single_choice"，answerKey.correctAnswers 用字母。';
      case ExerciseType.listeningSentenceOrdering:
        return '题型说明：生成一段由 4–6 个德语句子组成的听力材料（约 60–100 词），'
            '放在 stimulus.text，stimulus.kind 填 "audio"。'
            '然后把这些句子**打乱顺序**放进 options（options 的顺序就是学习者看到的初始顺序），'
            'questionType 用 "ordering"，answerKey.correctOrder 用 options 下标表示正确顺序'
            '（例如 options 有 4 项时为 [2,0,3,1]，必须是 0..n-1 的完整排列）。'
            '只生成 1 道排序题，prompt 写 "Bringe die Sätze in die richtige Reihenfolge."。';
      case ExerciseType.paragraphOrdering:
        return '题型说明：生成一篇由 4–6 个德语段落组成的短文（约 200–320 词），'
            '把这些段落**打乱顺序**放进 options（options 的顺序就是学习者看到的初始顺序），'
            'stimulus.kind 填 "none"，stimulus.text 留空。'
            'questionType 用 "ordering"，answerKey.correctOrder 用 options 下标表示正确顺序'
            '（必须是 0..n-1 的完整排列）。只生成 1 道排序题，'
            'prompt 写 "Bringe die Absätze in die richtige Reihenfolge."。';
      case ExerciseType.sentenceBuilding:
        return '题型说明：每题的 prompt 给出**德语要求与给定的词块/关键词**（例如 '
            '"Bilde einen Satz mit: weil / ich / heute / keine Zeit haben"），'
            'questionType 用 "free_text"。answerKey.referenceAnswers 给出 1–2 个正确参考句，'
            'rubric 用五个维度：grammar(3)、vocabulary(2)、sentenceStructure(2)、'
            'taskCompletion(2)、naturalness(1)。';
      case ExerciseType.errorCorrection:
        return '题型说明：每题给一个含 1–2 处语法或搭配错误的德语句子，放在 prompt 里并附指示语'
            '（例如 "Korrigiere den Satz:"），questionType 用 "free_text"。'
            'answerKey.referenceAnswers 给出改正后的句子（可给 2 个等价改法），'
            'explanation 说明错误点与原因，rubric 维度同写入类。';
      case ExerciseType.mixedPractice:
        return '题型说明：生成  道**混合题**，按下面配比覆盖听力、语法词汇与写作：'
            '① 约 1/3 为听写（questionType "dictation"）：每题 context 放该句德语原文（用于朗读），'
            'prompt 只写指示语，**不得泄露句子内容**，answerKey.acceptedAnswers 放原句；'
            '② 约 1/3 为语法词汇题（questionType "fill_blank" 或 "true_false"）：'
            'fill_blank 的 prompt 用含 ___ 的句子，answerKey.acceptedAnswers 给答案；'
            'true_false 的 prompt 给一句德语陈述，answerKey.acceptedAnswers 只用 "richtig"/"falsch"；'
            '③ 其余为写作题（questionType "free_text"，最多 2 题）：每题 10 分，'
            'answerKey.referenceAnswers 给参考句，rubric 用五维 grammar(3)/vocabulary(2)/'
            'sentenceStructure(2)/taskCompletion(2)/naturalness(1)。'
            'stimulus.kind 填 "none"，stimulus.text 留空；客观题 points 为 1。';
      case ExerciseType.translationWriting:
      case ExerciseType.situationalWriting:
      case ExerciseType.freeWriting:
        return '题型说明：开放式写作题。prompt 给出德语写作任务与字数要求，questionType 用 "free_text"，'
            'answerKey.referenceAnswers 给一个参考版本（不作为唯一标准），'
            'rubric 用五个维度：grammar(3)、vocabulary(2)、sentenceStructure(2)、'
            'taskCompletion(2)、naturalness(1)。';
    }
  }

  /// JSON 骨架（与 ExerciseSchema 的解析字段严格对应）
  static String _jsonSkeleton(ExerciseType type) {
    final needsStimulusText = switch (type) {
      ExerciseType.dictation ||
      ExerciseType.sentenceBuilding ||
      ExerciseType.errorCorrection ||
      ExerciseType.paragraphOrdering ||
      ExerciseType.mixedPractice => '',
      _ => '短文或听力原文（德语）',
    };

    return '''
输出 JSON 结构（字段名必须完全一致）：
{
  "schemaVersion": 1,
  "skill": "${type.skill.code}",
  "exerciseType": "${type.code}",
  "level": "A1|A2|B1|B2|C1|C2",
  "difficulty": "easy|normal|hard",
  "title": "德语标题",
  "instructions": "德语作答指示",
  "stimulus": {"kind": "text|audio|audio_text|none", "text": "$needsStimulusText"},
  "questions": [
    {
      "id": "q1",
      "questionType": "single_choice|multiple_choice|true_false|fill_blank|dictation|ordering|free_text",
      "prompt": "德语题干（或填空所在句）",
      "context": "可选：题目上下文",
      "options": ["选项1", "选项2", "选项3"],
      "answerKey": {
        "correctAnswers": ["A"],
        "acceptedAnswers": ["可接受答案"],
        "correctOrder": [0, 2, 1],
        "referenceAnswers": ["参考句"]
      },
      "points": 1,
      "explanation": "解析（说明为什么这个答案成立、其他选项为何不成立）",
      "rubric": {
        "dimensions": [{"name": "grammar", "maxScore": 3}]
      }
    }
  ]
}
注意：只填当前题型需要的字段；选择题用 correctAnswers（字母），填空题与听写用 acceptedAnswers，排序题用 correctOrder，写作题用 referenceAnswers + rubric。''';
  }
}
