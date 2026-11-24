import 'package:flutter/material.dart';

import '../../data/models/training.dart';

/// 训练模块的图标映射：听 / 读 / 写 三个技能各用一个固定图标，
/// 列表、卡片、历史记录都用它，避免同一个技能在不同页面长得不一样。
IconData trainingSkillIcon(TrainingSkill skill) => switch (skill) {
  TrainingSkill.listening => Icons.headphones,
  TrainingSkill.reading => Icons.auto_stories,
  TrainingSkill.writing => Icons.edit_note,
  TrainingSkill.mixed => Icons.shuffle,
};
