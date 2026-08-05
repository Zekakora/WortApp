# WortApp 项目文档

## 📋 项目概览

**WortApp** 是一款德语背单词与语法助手 App，基于 **Anki SM-2 间隔重复算法**，结合 **AI 变位练习** 与 **联网查词** 功能。界面采用 **Material Design 3** 设计规范，支持夜间模式。

**当前版本**: v1.1.0+1 (2026-08-05)

### 技术栈
- **框架**: Flutter 3.44.8 + Dart 3.12.2
- **数据库**: drift (SQLite ORM) - 支持 Android/iOS/Web
- **状态管理**: flutter_riverpod 2.6.1
- **AI 接口**: MiMo API (OpenAI 兼容格式)
- **目标平台**: Android + Web (调试用)

### 核心功能
1. **SM-2 间隔重复学习** - 6种学习模式（含快闪卡）
2. **AI 变位练习** - 动词/名词/形容词变位变格
3. **联网查词** - AI深度解析 + Wiktionary
4. **词书管理** - Excel/CSV 导入导出
5. **Material Design 3 界面** - 德语冠词颜色系统 + 夜间模式
6. **学习统计与数据管理** - 错误统计、AI 请求状态管理、备份恢复

---

## 📁 项目结构

```
WortApp/
├── lib/
│   ├── main.dart                          # App 入口
│   ├── app.dart                           # MaterialApp 配置
│   │
│   ├── core/                              # 核心工具层
│   │   ├── constants/
│   │   │   └── app_colors.dart            # M3 颜色 + Gender Color System
│   │   ├── theme/
│   │   │   └── app_theme.dart             # M3 主题配置
│   │   └── utils/
│   │       └── german_parser.dart         # 德语词形解析工具
│   │
│   ├── data/                              # 数据层
│   │   └── database/
│   │       ├── app_database.dart          # drift 数据库主文件
│   │       ├── app_database_native.dart   # Android/iOS 连接
│   │       ├── app_database_web.dart      # Web WASM 连接
│   │       ├── tables/                    # 数据表定义
│   │       │   ├── decks.dart             # 词书表
│   │       │   ├── words.dart             # 单词表
│   │       │   ├── sm2_states.dart        # SM-2 状态表
│   │       │   └── conjugation_cache.dart # 变位缓存表
│   │       └── daos/                      # 数据访问对象
│   │           ├── deck_dao.dart          # 词书 DAO
│   │           ├── word_dao.dart          # 单词 DAO
│   │           ├── sm2_dao.dart           # SM-2 DAO
│   │           └── conjugation_dao.dart   # 变位 DAO
│   │
│   ├── algorithms/                        # 算法层
│   │   ├── sm2_algorithm.dart             # SM-2 核心算法
│   │   ├── review_scheduler.dart          # 复习队列调度
│   │   └── distractor_generator.dart      # 干扰项生成器
│   │
│   ├── services/                          # 服务层
│   │   ├── ai/
│   │   │   ├── ai_service.dart            # AI 服务接口 + MiMo 实现
│   │   │   └── conjugation_service.dart   # 变位数据生成服务
│   │   ├── dictionary/
│   │   │   ├── dictionary_engine.dart     # 查词引擎接口
│   │   │   ├── ai_dictionary_engine.dart  # AI 查词引擎
│   │   │   └── wiktionary_engine.dart     # Wiktionary 引擎
│   │   └── import_export/
│   │       ├── import_service.dart        # CSV/Excel 导入
│   │       └── export_service.dart        # CSV/Excel 导出
│   │
│   ├── providers/                         # Riverpod 状态管理
│   │   ├── database_provider.dart         # 数据库实例
│   │   ├── deck_provider.dart             # 词书状态
│   │   ├── study_provider.dart            # 学习会话状态
│   │   ├── conjugation_provider.dart      # 变位练习状态
│   │   ├── search_provider.dart           # 查词状态
│   │   └── settings_provider.dart         # 应用设置
│   │
│   └── ui/                                # 界面层
│       ├── navigation/
│       │   └── app_navigation.dart        # 底部导航栏
│       ├── widgets/                       # 通用组件
│       ├── screens/
│       │   ├── home/                      # 主页
│       │   │   ├── home_screen.dart
│       │   │   └── widgets/
│       │   │       ├── progress_card.dart
│       │   │       └── feature_cards.dart
│       │   ├── study/                     # 背词模式
│       │   │   ├── study_screen.dart      # 模式选择
│       │   │   └── widgets/
│       │   │       ├── flip_mode_screen.dart    # 翻牌模式
│       │   │       ├── de_to_cn_screen.dart     # 看德选中
│       │   │       ├── cn_to_de_screen.dart     # 看中选德
│       │   │       ├── listen_mode_screen.dart  # 听音选词
│       │   │       └── spell_mode_screen.dart   # 拼写模式
│       │   ├── deck/                      # 词书管理
│       │   │   ├── deck_list_screen.dart
│       │   │   └── word_list_screen.dart
│       │   ├── conjugation/               # 变位练习
│       │   │   ├── conjugation_screen.dart
│       │   │   └── conjugation_drill.dart
│       │   ├── search/                    # 联网查词
│       │   │   └── search_screen.dart
│       │   └── settings/                  # 设置
│       │       └── settings_screen.dart
│   │
├── web/                                   # Web 平台文件
├── android/                               # Android 平台文件
├── memory/                                # 项目文档 (本文件)
└── pubspec.yaml                           # 依赖配置
```

---

## ✅ 已完成工作

### Phase 1: 项目基础 (已完成)
- [x] Flutter 项目初始化
- [x] 依赖配置 (drift, riverpod, dio, flutter_tts 等)
- [x] Material Design 3 主题系统
- [x] 德语冠词颜色系统 (der蓝/die红/das绿/复数黄)
- [x] 数据库表设计 (4张表)
- [x] DAO 层实现

### Phase 2: 核心算法与服务 (已完成)
- [x] SM-2 间隔重复算法实现
- [x] 复习队列调度器
- [x] 干扰项生成器
- [x] 德语词形解析器 (冠词提取、词性判断、宽容拼写)
- [x] Excel/CSV 导入服务
- [x] Excel/CSV 导出服务
- [x] MiMo AI 服务集成
- [x] 变位数据生成与缓存
- [x] 查词引擎架构 (AI + Wiktionary)

### Phase 3: UI 交互 (已完成)
- [x] 底部导航栏 + 路由系统
- [x] 主页 Dashboard (进度环、功能入口)
- [x] 词书列表管理 (CRUD、切换、导入)
- [x] 词书内单词列表 (搜索、筛选、熟练度标记)
- [x] 5种背词模式 UI + 数据连接
- [x] 学习会话管理 (SM-2 反馈、进度跟踪)
- [x] 学习完成统计页面

### Phase 4: AI 变位练习 (已完成)
- [x] 变位练习界面 (填空/选择题)
- [x] 动词变位练习 (现在时/过去时/完成时)
- [x] 名词变格练习 (冠词/复数)
- [x] 形容词比较级练习
- [x] AI 批量生成变位数据
- [x] 设置页面 (API Key、每日上限、TTS 语速)

### Phase 5: 联网查词 (已完成)
- [x] 查词界面 + 引擎切换
- [x] AI 深度解析引擎
- [x] Wiktionary 引擎
- [x] 查词结果展示 (释义/例句/AI分析)
- [x] 加词入库功能 (选择词书/新建词书)
- [x] AI 查词结果缓存到数据库 (ai_lookup_cache)

### Phase 6: AI 词义更新与数据一致性 (已完成)
- [x] 单词本多选 AI 批量更新词义（后台任务 + 进度查看）
- [x] AI 批量更新防数据丢失（空释义跳过、overwrite 生效、坏缓存自愈）
- [x] AI 结果完整字段落库（nounPlural/nounType/词性，Value.absent 不覆盖）
- [x] 详情页释义/例句完整列表展示（与查词界面一致）
- [x] 单词编辑对话框（优先 AI 缓存初始化，保存后同步写回缓存）
- [x] AI 词性/名词类型解析源头规范化（防 Dropdown 断言崩溃）

### Phase 7: Android 构建发布 (已完成)
- [x] 修复 OneDrive 目录下 Gradle VFS 缓存失效风暴（禁用文件监控）
- [x] 升级 file_picker 8.3.7 → 11.0.3（AGP 9 兼容）
- [x] AGP 9.0.1 → 8.13.1、Kotlin 2.3.20 → 2.2.20（修复旧插件 MissingValueException）
- [x] 修复 android-34 SDK 平台不完整（Android Studio 重装 Android 14 SDK）
- [x] **APK 构建成功**：`build/app/outputs/flutter-apk/app-release.apk` (61.2MB)

### Phase 8: v1.1.0 功能增强与发布 (已完成)
- [x] 快闪卡模式（全屏滑动评分，iOS 风格动效）
- [x] 学习统计：study_stats 表 + 错误统计排行榜（今日/历史二级页面）
- [x] 收藏功能（words.isFavorite）+ 抓词模式（收藏优先/只抓收藏）
- [x] AI 数据管理：ai_request_status 表 + 数据管理页（筛选/一键重试）
- [x] 夜间模式（设置页跟随系统/日间/夜间）
- [x] AI 预设扩充（Gemini / 通义千问 / 阿里云百炼）
- [x] 备份 JSON v4：导出/导入兼容收藏与错误统计
- [x] 单词删除与缓存释放、重置学习进度
- [x] 平板分屏双栏布局、单词详情页下滑关闭
- [x] 完整备份：gradle wrapper 关键文件纳入版本控制
- [x] APK 仅打包 64 位架构（arm64-v8a / x86_64），减小体积
- [x] 项目迁出 OneDrive（D:\Project Data\WortApp），移除 VFS 禁用配置
- [x] **版本 v1.1.0+1 发布，74 个测试全部通过**

---

## 🗄️ 数据库设计

### 表 1: `decks` (词书)
```sql
id            INTEGER PRIMARY KEY
name          TEXT NOT NULL
description   TEXT
is_active     BOOLEAN DEFAULT FALSE
created_at    DATETIME
updated_at    DATETIME
```

### 表 2: `words` (单词)
```sql
id              INTEGER PRIMARY KEY
deck_id         INTEGER → decks.id
german          TEXT NOT NULL        -- 德语原词
article         TEXT                 -- der/die/das
base_form       TEXT                 -- 词根
word_type       TEXT                 -- noun/verb/adjective
chinese         TEXT NOT NULL        -- 中文释义
example         TEXT                 -- 例句
tags            TEXT                 -- 标记
proficiency     INTEGER DEFAULT 0    -- 熟练度 0-5
last_study_date DATETIME
verb_present    TEXT                 -- 动词现在时
verb_past       TEXT                 -- 动词过去时
verb_perfect    TEXT                 -- 动词完成时
noun_genitive   TEXT                 -- 名词第二格
noun_plural     TEXT                 -- 名词复数
adj_comparative TEXT                 -- 形容词比较级
adj_superlative TEXT                 -- 形容词最高级
is_favorite     BOOLEAN DEFAULT FALSE -- 收藏标记
created_at      DATETIME
updated_at      DATETIME
```

### 表 3: `sm2_states` (SM-2 状态)
```sql
id              INTEGER PRIMARY KEY
word_id         INTEGER → words.id (UNIQUE)
repetition_n    INTEGER DEFAULT 0    -- 重复次数
interval_days   REAL DEFAULT 0       -- 复习间隔(天)
ease_factor     REAL DEFAULT 2.5     -- 简易度因子
next_review     DATETIME             -- 下次复习日期
last_review     DATETIME
total_reviews   INTEGER DEFAULT 0
correct_streak  INTEGER DEFAULT 0
created_at      DATETIME
updated_at      DATETIME
```

### 表 4: `conjugation_cache` (变位缓存)
```sql
id               INTEGER PRIMARY KEY
word_id          INTEGER → words.id (UNIQUE)
conjugation_json TEXT NOT NULL        -- 变位 JSON
source           TEXT DEFAULT 'ai'    -- ai/manual
created_at       DATETIME
updated_at       DATETIME
```

### 表 5: `study_stats` (每日学习统计)
```sql
id            INTEGER PRIMARY KEY
word_id       INTEGER → words.id
date          DATETIME NOT NULL       -- 学习日期（当天 00:00:00）
appearances   INTEGER DEFAULT 0       -- 当天出现次数
errors        INTEGER DEFAULT 0       -- 当天错误次数（忘记/模糊）
UNIQUE(word_id, date)                 -- 每词每天一条记录
```

### 表 6: `ai_request_status` (AI 请求状态)
```sql
id            INTEGER PRIMARY KEY
word_id       INTEGER → words.id
engine        TEXT                    -- 请求引擎
status        TEXT                    -- success / failed
error_message TEXT                    -- 失败原因
created_at    DATETIME
updated_at    DATETIME
```

> schemaVersion: 3（自动迁移创建新表；words 表新增 is_favorite 收藏标记）

---

## 🔧 开发环境配置

### 依赖安装
```bash
flutter pub get
```

### 代码生成 (drift)
```bash
dart run build_runner build
```

### Web 调试
```bash
# 构建 Web 版本
flutter build web --release

# 启动本地服务器
cd build/web
python -m http.server 8080

# 浏览器访问 http://localhost:8080
```

### Android 构建
```bash
# 需要先安装 Android SDK（API 34+，路径 C:\Users\DOOGE\AppData\Local\Android\sdk）
# Windows 下 Flutter 未配置 PATH，需使用绝对路径
C:\flutter\bin\flutter build apk --release

# 输出: build/app/outputs/flutter-apk/app-release.apk
```

### Android 构建版本组合（2026-08-05 验证成功，勿随意变更）
| 组件 | 版本 | 配置位置 |
|------|------|---------|
| Gradle | 9.1.0（Flutter 3.44 官方默认） | `android/gradle/wrapper/gradle-wrapper.properties` |
| AGP | 8.13.1（9.0.1 降级，兼容旧插件） | `android/settings.gradle.kts` |
| Kotlin | 2.2.20（2.3.20 降级） | `android/settings.gradle.kts` |
| 镜像源 | 阿里云 Maven + 腾讯云 Gradle | `settings.gradle.kts` / `gradle-wrapper.properties` |
| ABI | 仅 64 位（arm64-v8a / x86_64） | `android/app/build.gradle.kts` | abiFilters + packaging 排除 32 位 .so |
| VFS 监控 | 已恢复默认启用 | `android/gradle.properties` |

> 项目原位于 OneDrive 同步目录，曾通过 `org.gradle.vfs.watch=false` 禁用文件监控避免缓存失效风暴；
> **2026-08-05 项目已迁移至 `D:\Project Data\WortApp`（非 OneDrive 目录），该配置已移除，VFS 监控恢复默认。**
> 升级 Gradle/AGP/Kotlin 前务必验证插件兼容性。

---

## 📝 待完成事项

### 高优先级
- [x] 安装 Android SDK 并测试 Android 构建（2026-08-05 完成，APK 构建成功）
- [ ] Web 平台 SQLite WASM 配置优化
- [ ] TTS 功能 Web 平台适配
- [ ] 文件导入导出 Web 平台适配

### 中优先级
- [ ] 词书重命名对话框完善
- [x] 学习统计数据持久化（study_stats 表）
- [ ] 连续打卡天数统计
- [x] 暗色主题测试（夜间模式已实现）

### 低优先级
- [ ] 手写识别功能
- [ ] 德语助手网页解析引擎
- [ ] 多语言界面支持
- [x] 单元测试覆盖（74 个测试）
- [ ] 性能优化

---

## 🐛 已知问题

1. **Web 平台**:
   - SQLite WASM 首次加载较慢
   - TTS 功能可能不可用
   - 文件操作需要浏览器 API 支持

2. **代码警告** (不影响运行):
   - 部分未使用的 import
   - Radio 组件 deprecation 警告
   - 一些 info 级别的代码风格提示

---

## 💡 开发建议

### 继续开发流程
1. 修改代码后运行 `dart run build_runner build` 重新生成
2. Web 调试: `flutter build web` → 本地服务器
3. Android 调试: `flutter run` (需要 Android SDK)

### 添加新功能
1. 在 `providers/` 添加状态管理
2. 在 `services/` 添加业务逻辑
3. 在 `ui/screens/` 添加界面
4. 更新 `app_navigation.dart` 添加路由

### 数据库迁移
修改表结构后需要:
1. 更新 `tables/` 中的表定义
2. 增加 `schemaVersion`
3. 在 `migration` 中添加迁移逻辑

---

## 📚 参考资源

- [Flutter 官方文档](https://docs.flutter.dev)
- [drift 文档](https://drift.simonbinder.eu/docs/getting-started/)
- [Riverpod 文档](https://riverpod.dev/docs/introduction/getting_started)
- [MiMo API 文档](https://api.xiaomimimo.com)
- [SM-2 算法说明](https://supermemo.guru/wiki/SuperMemo_Algorithm:_Two-component_model_of_memory)

---

## 📊 项目统计

- **代码文件数**: ~60 个 Dart 文件
- **代码行数**: ~8000+ 行
- **依赖包数**: ~25 个
- **数据库表**: 6 张
- **UI 页面**: 12+ 个
- **学习模式**: 6 种

---

*最后更新: 2026-08-05*
*开发者: Claude AI Assistant*
