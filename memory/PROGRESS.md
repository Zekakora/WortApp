# WortApp 项目进度文档

## 📅 更新日期
2026-08-05 (最新)

---

## ✅ 已完成功能

### 核心架构
- [x] Flutter 项目初始化 (Flutter 3.44.8 + Dart 3.12.2)
- [x] Material Design 3 主题系统
- [x] 德语冠词颜色系统 (der蓝/die红/das绿/复数黄)
- [x] Riverpod 状态管理
- [x] drift 数据库 ORM (支持 Android/iOS/Web)

### 数据库设计
- [x] `decks` 表 - 词书管理
- [x] `words` 表 - 单词存储（含动词三态、名词变格、形容词比较级）
- [x] `sm2_states` 表 - SM-2 算法状态
- [x] `conjugation_cache` 表 - 变位数据缓存
- [x] `ai_lookup_cache` 表 - AI 查词缓存（(word, engine) 唯一键）
- [x] `ai_request_status` 表 - AI 请求状态记录（成功/失败/错误信息，数据管理用）
- [x] `study_stats` 表 - 每日学习统计（wordId+date 唯一键，记录出现/错误次数）
- [x] `settings` 表 - 应用设置存储（使用数据库，非 SharedPreferences）

### 算法实现
- [x] SM-2 间隔重复算法
- [x] 复习队列调度器
- [x] 干扰项生成器（选择题）
- [x] 德语词形解析器（冠词提取、词性判断、宽容拼写）

### 词书管理
- [x] 词书 CRUD（创建、重命名、删除）
- [x] 词书切换
- [x] 单词列表（搜索、筛选、熟练度标记）
- [x] 单词三点菜单删除（确认对话框，删除后自动清理 SM2/变位缓存；无其他词书引用时释放 AI 释义缓存与请求状态）
- [x] 重置学习进度按钮（新建单词上方，黄色警告弹窗二次确认，清空全部 SM2 状态并归零熟练度）
- [x] Excel/CSV 导入服务
- [x] Excel/CSV 导出服务

### 学习模式
- [x] 经典翻牌模式（Flip Mode）
- [x] 看德语选中文
- [x] 看中文选德语
- [x] 听德语选单词
- [x] 德语拼写模式（含特殊字符键盘）
- [x] SM-2 反馈按钮（忘记/模糊/熟悉/简单）
- [x] 学习完成统计
- [x] 快闪卡模式（Flash Card，全屏卡片左右滑动评分，iOS 风格动效）
- [x] 每轮词量与每日上限控制（新词/复习独立限额）+ 抽词兜底循环复习
- [x] 抓词模式（正常抓词 / 收藏优先 / 只抓收藏）
- [x] 四选一干扰项全词库随机抽取（池化机制）
- [x] 学习统计：study_stats 表 + 底部错误统计排行榜（今日/历史，独立二级页面）

### AI 集成
- [x] 可配置 AI 服务（支持 OpenAI 兼容格式）
- [x] 自定义 AI 配置（API Key / API 地址 / 模型名称）
- [x] 快速预设（MiMo / DeepSeek / OpenAI / Gemini / 通义千问 / 阿里云百炼）
- [x] AI 查词引擎
- [x] AI 变位数据生成
- [x] Wiktionary 查词引擎
- [x] 查词结果展示（释义/例句/AI分析）
- [x] AI 查词结果缓存到数据库（ai_lookup_cache 表）
- [x] 单词本多选 AI 批量更新词义（后台任务 + 进度查看）
- [x] AI 批量更新防数据丢失（空释义跳过、overwrite 生效、坏缓存自愈）
- [x] AI 结果字段落库（复数 nounPlural、名词类型 nounType、词性）
- [x] AI 词性/名词类型解析源头规范化（兼容 "Verb"/"动词" 等不规范值）
- [x] 词书页“数据管理”入口（新建单词按钮上方）
- [x] 数据管理页：单词 AI 释义状态列表（已有释义/请求失败/无释义）+ 筛选 + 一键选择重试
- [x] AI 请求状态自动记录（引擎真实请求时写入 ai_request_status，缓存命中不记录）
- [x] 共享批量更新进度对话框组件（BatchUpdateDialog，wordIds/deckId 双模式）
- [x] 备份 JSON v3：导出/导入含 aiStatus 状态信息（wipe 覆盖模式同步清理）

### 词性标注系统
- [x] 词性颜色系统（WordTypeColors）
  - 动词 Verb: 紫色系
  - 可分动词 trennbar: 深紫色
  - 不可分动词 untrennbar: 浅紫色
  - 形容词 Adjektiv: 橙色系
  - 副词 Adverb: 青色系
  - 介词 Präposition: 粉色系
  - 连词 Konjunktion: 棕色系
  - 名词 Substantiv: 使用冠词颜色
- [x] WordTypeChip 组件（词性标签）
- [x] VerbSeparabilityChip 组件（可分性标签）
- [x] PrepositionChip 组件（介词搭配标签，显示支配三格/四格）

### 单词详情页面
- [x] 完整单词信息展示
- [x] 动词变位（现在时/过去时/完成时）
- [x] 名词变格（第二格/复数）
- [x] 形容词比较级/最高级
- [x] 学习状态（复习次数、连续正确、简易度、下次复习）
- [x] 标签显示
- [x] TTS 发音
- [x] 单词编辑对话框（优先 AI 缓存初始化，保存后同步写回缓存）
- [x] 释义/例句完整列表展示（与查词界面一致）
- [x] 动词搭配、AI 解析展示（来自缓存）

### 其他功能
- [x] TTS 德语发音
- [x] 加词入库（选择词书/新建词书）
- [x] 设置页面（AI配置、每日上限、TTS语速、宽容拼写、主题模式）
- [x] 词书列表显示词性标签
- [x] 夜间模式（跟随系统/日间/夜间，Material 3 暗色配色）
- [x] 单词收藏标记（words.isFavorite）
- [x] 备份 JSON v4：导出/导入兼容收藏标记与错误统计
- [x] 平板分屏双栏布局（StudySplitLayout）
- [x] 单词详情页下滑关闭（SwipeDownDetailRoute）
- [x] APK 仅打包 64 位架构（arm64-v8a / x86_64），排除 32 位减小体积
- [x] 完整备份：gradle-wrapper.jar / gradlew 等关键构建文件纳入版本控制

---

## 🐛 已知问题

### Web 平台问题
1. **数据库初始化不稳定** - sql.js 在某些浏览器环境下会报错
2. **WASM 加载问题** - 需要手动复制 sql-wasm.wasm 文件到 build 目录
3. **页面刷新后数据丢失** - 如果 sql.js 初始化失败，会使用内存数据库

### 功能限制
1. **AI JSON 解析** - 部分 AI 响应格式不标准导致解析失败
2. **Web 平台设置** - 数据库写入可能失败，设置可能不持久

### 解决方案建议
- **Android 平台**：不会有上述 Web 问题，使用原生 SQLite
- **Web 调试**：仅用于界面调试，数据持久化在 Android 上测试

---

## 📋 待实现功能

### 中优先级
- [ ] 学习统计图表（连续打卡、掌握率趋势）
- [ ] 批量删除单词

### 低优先级
- [ ] 手写识别功能
- [ ] 德语助手网页解析引擎
- [ ] 暗色主题优化
- [ ] 多语言界面支持
- [ ] 单元测试覆盖
- [ ] 名词第二格变格练习
- [x] 数据备份/恢复功能（JSON v4：含收藏与错误统计）

---

## 🛠️ 技术说明

### 平台差异
| 功能 | Android | Web |
|------|---------|-----|
| 数据库 | 原生 SQLite (稳定) | sql.js WASM (不稳定) |
| 设置存储 | 数据库 | 数据库 (可能失败) |
| TTS | 系统 TTS | 浏览器 TTS |
| 文件导入 | 文件选择器 | 文件选择器 |

### 建议开发流程
1. **界面开发**：可在 Web 平台调试
2. **数据持久化**：在 Android 平台测试
3. **最终发布**：构建 Android APK

---

## 📁 关键文件路径

```
lib/
├── core/constants/
│   └── app_colors.dart          # 颜色系统（冠词+词性）
├── providers/
│   ├── database_provider.dart   # 数据库状态
│   ├── settings_provider.dart   # 设置（含 AI 配置）
│   ├── study_provider.dart      # 学习会话
│   └── deck_provider.dart       # 词书状态
├── data/database/
│   ├── app_database.dart        # 数据库定义
│   ├── app_database_web.dart    # Web 平台实现
│   └── tables/                  # 数据表
├── services/
│   ├── ai/ai_service.dart       # 可配置 AI 服务
│   └── dictionary/              # 查词引擎
├── ui/widgets/
│   └── word_type_chip.dart      # 词性标签组件
└── ui/screens/
    ├── deck/
    │   ├── word_list_screen.dart   # 单词列表
    │   └── word_detail_screen.dart # 单词详情
    ├── study/widgets/              # 学习模式
    ├── search/search_screen.dart   # 查词
    └── settings/settings_screen.dart # 设置
```

---

## 🧪 构建命令

```bash
# 安装依赖
flutter pub get

# 生成数据库代码
dart run build_runner build

# Web 调试构建
flutter build web --release

# 复制 WASM 文件（Web 平台需要）
cp web/sqljs/sql-wasm.wasm build/web/
cp web/sqljs/sql-wasm.js build/web/

# 启动本地服务器
cd build/web && python -m http.server 8080

# Android 构建（需要 Android SDK；Windows 下 Flutter 未配置 PATH，需用绝对路径）
C:\flutter\bin\flutter build apk --release

# 详细日志模式（建议重定向到文件，避免终端日志淹没）
C:\flutter\bin\flutter build apk --release -v > build\flutter_build.log 2>&1

# 输出文件
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 🏗️ Android 构建版本组合（2026-08-05 验证成功）

| 组件 | 版本 | 配置位置 | 说明 |
|------|------|---------|------|
| Gradle | 9.1.0 | `android/gradle/wrapper/gradle-wrapper.properties` | Flutter 3.44 官方默认，**勿随意升级**（Flutter 工具支持范围 9.0~9.3.1） |
| AGP | 8.13.1 | `android/settings.gradle.kts` | 原 9.0.1 与旧插件不兼容，已降级 |
| Kotlin | 2.2.20 | `android/settings.gradle.kts` | 原 2.3.20 已降级，匹配 AGP |
| compileSdk | flutter 默认 (36) | `android/app/build.gradle.kts` | 跟随 Flutter 默认值 |
| Maven 镜像 | 阿里云 | `android/settings.gradle.kts` | 国内加速 |
| Gradle 分发 | 腾讯云 | `gradle-wrapper.properties` | 国内加速 |
| VFS 监控 | 已恢复默认启用 | `android/gradle.properties` | 项目已迁出 OneDrive（现位于 `D:\Project Data\WortApp`），2026-08-05 移除 `org.gradle.vfs.watch=false` |

**构建失败修复经验（2026-08-05）**：
1. OneDrive 同步目录 → Gradle VFS 缓存失效风暴（构建"卡住"）→ `gradle.properties` 禁用 VFS 监控（**项目已迁出 OneDrive，该配置已于 2026-08-05 移除**）
2. file_picker 8.3.7 等旧插件与 AGP 9 不兼容（`MissingValueException`）→ 升级 file_picker 至 11.0.3 并迁移 API
3. 多个旧插件均不兼容 AGP 9 → **AGP 降级 9.0.1 → 8.13.1、Kotlin 2.3.20 → 2.2.20**
4. `Failed to find target 'android-34'` → Android Studio 重装 Android 14 SDK（需确认 `android.jar` 与 `source.properties` 存在）
5. 最终组合验证：`BUILD SUCCESSFUL in 2m 13s`，产出 `app-release.apk` (61.2MB)

---

## 📝 开发日志

### 2026-08-03 (上午)
- 完成项目基础架构搭建
- 实现 SM-2 算法和 5 种学习模式
- 集成 MiMo AI API
- 发现 Web 平台数据库兼容性问题

### 2026-08-03 (下午)
- [x] 添加自定义 AI 配置功能（支持 DeepSeek/OpenAI/MiMo）
- [x] 添加词性色块标注系统（动词/形容词/副词/介词/连词）
- [x] 添加单词详情页面（显示完整信息、变位、学习状态）
- [x] 添加动词可分性标签（trennbar/untrennbar）
- [x] 添加介词搭配标签（支配三格/四格）
- [x] 更新词书列表显示词性标签
- [x] 优化 Web 平台数据库实现
- [x] 将设置存储从 SharedPreferences 改为数据库

### 2026-08-05 (Android 构建修复与 APK 发布)
- [x] 修复 OneDrive 同步目录导致的 Gradle VFS 缓存失效风暴（禁用文件监控）
- [x] 升级 file_picker 8.3.7 → 11.0.3 并迁移 pickFiles API（AGP 9 兼容）
- [x] AGP 9.0.1 → 8.13.1、Kotlin 2.3.20 → 2.2.20（修复旧插件 MissingValueException）
- [x] 修复 android-34 SDK 平台不完整问题（Android Studio 重装 Android 14 SDK）
- [x] Gradle 保持 9.1.0（Flutter 3.44 官方默认，与 AGP 8.13.1 组合验证成功）
- [x] **APK 构建成功**：`build/app/outputs/flutter-apk/app-release.apk` (61.2MB，BUILD SUCCESSFUL 2m 13s)

### 2026-08-05 (AI 数据管理)
- [x] 新增 `ai_request_status` 表 + AiStatusDao（schemaVersion 2→3，自动迁移创建新表）
- [x] AI 引擎接入 statusCallback：真实请求时记录成功/失败状态（缓存命中不重复记录）
- [x] 词书页添加上方“数据管理”按钮（新建单词 FAB 上方，多选模式隐藏）
- [x] 数据管理页：状态统计卡片（总单词/已有AI释义/请求失败/无AI释义）+ 筛选 + 勾选重试
- [x] 一键选择需重试单词（通过 AI 缓存检测已有释义，已更新的单词不会重复请求）
- [x] 抽取共享 BatchUpdateDialog（word_list/deck_list/data_management 三处复用）
- [x] 备份 JSON 升级 v3：aiStatus 全表导出/导入恢复，wipe 覆盖时同步清空
- [x] 测试更新：备份导出/导入/wipe 均验证 aiStatus；`flutter analyze` 无 error，55 个测试全部通过

### 2026-08-05 (单词删除与缓存释放)
- [x] 单词三点菜单新增“删除单词”（红色确认对话框，提示 AI 缓存释放规则）
- [x] AppDatabase.deleteWordWithCleanup 事务：删 SM2 状态 + 变位缓存 + 单词记录
- [x] 跨词书引用检测（忽略大小写，与词书内查重规则一致）：无其他词书引用时释放 ai_lookup_cache 与 ai_request_status
- [x] 新增 delete_word_cleanup_test.dart（唯一词释放缓存 / 多词书保留缓存 / 大小写差异保留 / 删除不存在不报错）
- [x] 验证：flutter analyze 无 error，68 个测试全部通过

### 2026-08-05 (重置学习进度)
- [x] 词书页新建单词上方添加“重置学习进度”按钮（restart_alt 图标）
- [x] 黄色警告弹窗二次确认（amber 背景 + 警告图标，提示不可恢复）
- [x] AppDatabase.resetAllLearningProgress 事务：清空全部 sm2_states，proficiency 归零、lastStudyDate 置空，所有单词变回新词
- [x] 重置后 invalidate studyPlanProvider 全家（主页进度卡与学习计划同步刷新）
- [x] 新增 reset_progress_test.dart（重置清空 / 变回新词可抽取 / 空库不报错）
- [x] 验证：flutter analyze 无 error，74 个测试全部通过

### 2026-08-05 (v1.1.0 发布：夜间模式 / 完整备份 / AI 预设扩充)
- [x] 项目迁移出 OneDrive 至 `D:\Project Data\WortApp`，移除 `org.gradle.vfs.watch=false`（VFS 监控恢复默认）
- [x] 完整备份：gradle-wrapper.jar / gradlew / gradlew.bat 纳入版本控制（.gitignore 移除相关项）
- [x] 夜间模式：app_theme.dart 新增 darkTheme()，设置页主题切换（跟随系统/日间/夜间）
- [x] AI 预设扩充：新增 Gemini / 通义千问 / 阿里云百炼，DeepSeek 模型更新为 deepseek-v4-flash
- [x] APK 仅打包 64 位架构（abiFilters arm64-v8a/x86_64 + packaging 排除 32 位 .so）
- [x] 应用图标更新
- [x] 发布版本：v1.1.0+1，生成 RELEASE_NOTES.md

### 2026-08-04
- [x] 修复 AI 批量更新词义后释义未保存问题（空释义覆盖、overwrite 无效、坏缓存命中、提示词截断）
- [x] 修复 AI 结果复数（nounPlural）不落库、名词类型（nounType）"null" 字符串污染导致标签不显示
- [x] 新增缓存污染检测（_isPollutedCache）与防御性解析（_asNullableString）
- [x] 修复导入单词 AI 识别与查词界面展示不一致（详情页释义/例句优先展示缓存完整列表）
- [x] 编辑对话框数据源与详情页同步（优先 AI 缓存初始化，保存后写回缓存）
- [x] 修复编辑对话框 DropdownButton 断言崩溃（AI 词性 "Verb"/"名词" 等不规范值导致）
- [x] AI 词性/名词类型解析源头规范化（_normalizePartOfSpeech/_normalizeNounType）

### 待解决
- [ ] Web 平台数据库稳定性（建议直接在 Android 测试）

---

## 💡 下次开发建议

1. **优先在 Android 平台测试**
   - Web 平台的数据库问题在 Android 上不存在
   - 构建 APK 后安装到手机测试

2. **完善 AI 功能**
   - 缓存查词结果到数据库
   - 添加动词介词搭配详细信息

3. **添加学习统计**
   - 连续打卡天数
   - 掌握率趋势图表

4. **优化用户体验**
   - 单词编辑功能
   - 批量操作

---

*文档最后更新: 2026-08-05*
