# WortApp - 德语背单词与语法助手

一款基于 **Anki SM-2 间隔重复算法** 的（纯AI生成的）德语学习应用，集成 **AI 变位练习** 与 **联网查词** 功能，采用 Material Design 3 设计规范。

## ✨ 功能特性

### 📚 背单词学习
- **SM-2 间隔重复算法**：科学的记忆曲线调度复习
- **5 种学习模式**：
  - 翻牌模式（Flip Card）
  - 快闪卡模式（滑动评分）
  - 看德语选中文
  - 看中文选德语
  - 听音选词（TTS 朗读）
- **拼写模式**：德语拼写练习
- **每轮词量与每日学习上限控制**，支持循环复习
- 干扰项从全词库随机抽取，避免选项重复

### 🧠 AI 变位练习
- 动词变位（现在时 / 过去时 / 完成时）
- 名词变格（冠词 / 复数）
- 形容词比较级练习
- AI 批量生成变位数据并缓存

### 🔍 联网查词
- AI 深度解析（词性、释义、例句、AI 分析）
- Wiktionary 引擎
- 查词结果一键加入词书
- AI 释义缓存到本地数据库

### 📖 词书管理
- 词书 CRUD、多词书切换
- Excel / CSV 导入导出
- AI 批量更新词义（后台任务 + 进度查看）
- 单词编辑、收藏、熟练度标记
- 学习统计（每日学习量、正确率等）

### 🗄️ 数据管理
- 备份恢复：JSON 导出 / 导入，兼容收藏与错误统计
- AI 缓存清理与状态管理

## 🛠️ 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter + Dart |
| 数据库 | drift (SQLite ORM)，支持 Android / Web (WASM) |
| 状态管理 | flutter_riverpod |
| 文件处理 | file_picker、csv、excel |
| 网络 | dio、http |
| TTS | flutter_tts |
| AI 接口 | MiMo API（OpenAI 兼容格式） |

## 📱 支持平台

- **Android**（主目标，APK 约 43MB）
- **Web**（调试 / 演示）

## 🚀 快速开始

```bash
# 安装依赖
flutter pub get

# 生成代码（修改 drift 表 / DAO 后执行）
dart run build_runner build

# 运行（Windows 桌面调试）
flutter run -d windows

# 构建 Android APK（仅 64 位）
flutter build apk --release --target-platform android-arm64 --target-platform android-x64
# 输出: build/app/outputs/flutter-apk/app-release.apk

# 构建 Web 版本
flutter build web --release
```

### 应用图标

修改 `icon.png` 后重新生成图标：

```bash
dart run flutter_launcher_icons
```

## 📁 项目结构

```
lib/
├── main.dart                        # 入口
├── app.dart                         # MaterialApp 配置
├── core/                            # 常量、主题、工具
├── data/
│   ├── database/                    # drift 表定义、DAO、迁移
│   ├── models/
│   └── repositories/
├── algorithms/                      # SM-2、复习调度、干扰项生成
├── services/
│   ├── ai/                          # MiMo AI、变位生成
│   ├── dictionary/                  # AI / Wiktionary 查词引擎
│   └── import_export/               # Excel/CSV 导入导出
├── providers/                       # Riverpod 状态
└── ui/
    ├── navigation/                  # 底部导航
    ├── screens/                     # 主页、学习、词书、变位、查词、设置
    └── widgets/                     # 通用组件
test/                                # 单元测试
```

## 🧪 测试

```bash
flutter test
```

## 📄 数据库

核心表：`decks`（词书）、`words`（单词）、`sm2_states`（SM-2 复习状态）、`conjugation_cache`（变位缓存）、`study_stats`（学习统计）、`ai_request_status`（AI 任务状态）。

## 📦 环境要求

- Flutter 3.44+ / Dart 3.12+
- Android SDK（API 34+）
