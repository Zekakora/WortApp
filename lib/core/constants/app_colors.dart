import 'package:flutter/material.dart';

/// 德语冠词颜色系统 (Gender Color System)
/// 阳性 (der): 蓝色系
/// 阴性 (die): 红色/粉色系
/// 中性 (das): 绿色系
/// 复数 (die Plural): 黄色/橙色系
class GenderColors {
  GenderColors._();

  // 阳性 der - 蓝色系
  static const Color derPrimary = Color(0xFF1565C0);
  static const Color derLight = Color(0xFF64B5F6);
  static const Color derSurface = Color(0xFFE3F2FD);

  // 阴性 die - 红色/粉色系
  static const Color diePrimary = Color(0xFFC62828);
  static const Color dieLight = Color(0xFFEF5350);
  static const Color dieSurface = Color(0xFFFFEBEE);

  // 中性 das - 绿色系
  static const Color dasPrimary = Color(0xFF2E7D32);
  static const Color dasLight = Color(0xFF66BB6A);
  static const Color dasSurface = Color(0xFFE8F5E9);

  // 复数 die Plural - 黄色/橙色系
  static const Color pluralPrimary = Color(0xFFE65100);
  static const Color pluralLight = Color(0xFFFF9800);
  static const Color pluralSurface = Color(0xFFFFF3E0);

  /// 根据冠词返回对应颜色
  static Color forArticle(String? article, {bool plural = false}) {
    if (plural) return pluralPrimary;
    switch (article?.toLowerCase()) {
      case 'der':
        return derPrimary;
      case 'die':
        return diePrimary;
      case 'das':
        return dasPrimary;
      default:
        return Colors.grey;
    }
  }

  /// 根据冠词返回对应浅色
  static Color forArticleLight(String? article, {bool plural = false}) {
    if (plural) return pluralLight;
    switch (article?.toLowerCase()) {
      case 'der':
        return derLight;
      case 'die':
        return dieLight;
      case 'das':
        return dasLight;
      default:
        return Colors.grey.shade300;
    }
  }

  /// 根据冠词返回对应背景色
  static Color forArticleSurface(String? article, {bool plural = false}) {
    if (plural) return pluralSurface;
    switch (article?.toLowerCase()) {
      case 'der':
        return derSurface;
      case 'die':
        return dieSurface;
      case 'das':
        return dasSurface;
      default:
        return Colors.grey.shade100;
    }
  }
}

/// SM-2 反馈分数对应颜色
class ScoreColors {
  ScoreColors._();

  static const Color forgot = Color(0xFFD32F2F);    // 0-1: 忘记
  static const Color hard = Color(0xFFFF6F00);       // 2: 模糊
  static const Color good = Color(0xFF2E7D32);       // 3-4: 熟悉
  static const Color easy = Color(0xFF1565C0);       // 5: 简单
}

/// 词性颜色系统 (Word Type Color System)
/// 动词 (Verb): 紫色系
/// 形容词 (Adjektiv): 橙色系
/// 副词 (Adverb): 青色系
/// 名词 (Substantiv): 使用冠词颜色
class WordTypeColors {
  WordTypeColors._();

  // 动词 - 紫色系
  static const Color verbPrimary = Color(0xFF7B1FA2);
  static const Color verbLight = Color(0xFFCE93D8);
  static const Color verbSurface = Color(0xFFF3E5F5);

  // 可分动词 (trennbar) - 深紫色
  static const Color verbTrennbarPrimary = Color(0xFF4A148C);
  static const Color verbTrennbarLight = Color(0xFFAB47BC);

  // 不可分动词 (untrennbar) - 浅紫色
  static const Color verbUntrennbarPrimary = Color(0xFF9C27B0);
  static const Color verbUntrennbarLight = Color(0xFFBA68C8);

  // 形容词 - 橙色系
  static const Color adjPrimary = Color(0xFFE65100);
  static const Color adjLight = Color(0xFFFF9800);
  static const Color adjSurface = Color(0xFFFFF3E0);

  // 副词 - 青色系
  static const Color advPrimary = Color(0xFF00695C);
  static const Color advLight = Color(0xFF26A69A);
  static const Color advSurface = Color(0xFFE0F2F1);

  // 介词 - 粉色系
  static const Color prepPrimary = Color(0xFFAD1457);
  static const Color prepLight = Color(0xFFEC407A);
  static const Color prepSurface = Color(0xFFFCE4EC);

  // 连词 - 棕色系
  static const Color conjPrimary = Color(0xFF4E342E);
  static const Color conjLight = Color(0xFF8D6E63);
  static const Color conjSurface = Color(0xFFEFEBE9);

  /// 根据词性返回对应颜色
  static Color forWordType(String? wordType, {String? article}) {
    // 如果是名词，使用冠词颜色
    if (wordType == 'noun' && article != null) {
      return GenderColors.forArticle(article);
    }

    switch (wordType) {
      case 'verb':
        return verbPrimary;
      case 'verb_trennbar':
        return verbTrennbarPrimary;
      case 'verb_untrennbar':
        return verbUntrennbarPrimary;
      case 'adjective':
      case 'adj':
        return adjPrimary;
      case 'adverb':
      case 'adv':
        return advPrimary;
      case 'preposition':
      case 'prep':
        return prepPrimary;
      case 'conjunction':
      case 'conj':
        return conjPrimary;
      default:
        return Colors.grey;
    }
  }

  /// 根据词性返回对应背景色
  static Color forWordTypeSurface(String? wordType, {String? article}) {
    if (wordType == 'noun' && article != null) {
      return GenderColors.forArticleSurface(article);
    }

    switch (wordType) {
      case 'verb':
      case 'verb_trennbar':
      case 'verb_untrennbar':
        return verbSurface;
      case 'adjective':
      case 'adj':
        return adjSurface;
      case 'adverb':
      case 'adv':
        return advSurface;
      case 'preposition':
      case 'prep':
        return prepSurface;
      case 'conjunction':
      case 'conj':
        return conjSurface;
      default:
        return Colors.grey.shade100;
    }
  }

  /// 获取词性的显示标签
  static String getWordTypeLabel(String? wordType) {
    switch (wordType) {
      case 'noun':
        return 'N';
      case 'verb':
        return 'V';
      case 'verb_trennbar':
        return 'V.trenn';
      case 'verb_untrennbar':
        return 'V.untrenn';
      case 'adjective':
      case 'adj':
        return 'Adj';
      case 'adverb':
      case 'adv':
        return 'Adv';
      case 'preposition':
      case 'prep':
        return 'Präp';
      case 'conjunction':
      case 'conj':
        return 'Konj';
      default:
        return '?';
    }
  }

  /// 获取完整的词性描述
  static String getWordTypeDescription(String? wordType) {
    switch (wordType) {
      case 'noun':
        return '名词';
      case 'verb':
        return '动词';
      case 'verb_trennbar':
        return '可分动词';
      case 'verb_untrennbar':
        return '不可分动词';
      case 'adjective':
      case 'adj':
        return '形容词';
      case 'adverb':
      case 'adv':
        return '副词';
      case 'preposition':
      case 'prep':
        return '介词';
      case 'conjunction':
      case 'conj':
        return '连词';
      default:
        return '未知';
    }
  }
}
