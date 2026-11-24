import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../core/i18n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/sync_refresh.dart';
import '../../../services/import_export/export_service.dart';
import '../../../services/import_export/import_service.dart';
import 'onedrive_sync_section.dart';

/// 当前应用版本号（与 pubspec.yaml 保持一致）
const String _appVersion = '1.2.0';

/// 设置页面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final aiConfig = settings.aiConfig;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('设置')),
      ),
      body: ListView(
        children: [
          // 外观设置
          _SectionHeader(title: context.tr('外观')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'system',
                    label: Text(context.tr('跟随系统')),
                    icon: const Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: 'light',
                    label: Text(context.tr('日间')),
                    icon: const Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: 'dark',
                    label: Text(context.tr('夜间')),
                    icon: const Icon(Icons.dark_mode),
                  ),
                ],
                selected: {settings.themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateThemeMode(selection.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 界面语言（中文 / 英语 / 德语）
          _SectionHeader(title: context.tr('语言')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'zh', label: Text('中文')),
                  ButtonSegment(value: 'en', label: Text('English')),
                  ButtonSegment(value: 'de', label: Text('Deutsch')),
                ],
                selected: {settings.languageCode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateLanguageCode(selection.first);
                },
              ),
            ),
          ),
          const Divider(),

          // AI 设置
          _SectionHeader(title: context.tr('AI 设置')),
          ListTile(
            leading: Icon(
              Icons.smart_toy,
              color: aiConfig.isConfigured ? Colors.green : Colors.grey,
            ),
            title: Text(context.tr('AI 配置')),
            subtitle: Text(
              aiConfig.isConfigured
                  ? '${_getProviderName(aiConfig.baseUrl)} - ${aiConfig.model}'
                  : context.tr('未配置'),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editAiConfig(context, ref),
          ),
          if (aiConfig.isConfigured)
            ListTile(
              leading: const Icon(Icons.key, size: 20),
              title: Text(context.tr('API Key')),
              subtitle: Text(
                '${aiConfig.apiKey.substring(0, aiConfig.apiKey.length.clamp(0, 8))}...',
              ),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () => _editApiKey(context, ref),
            ),
          // AI 批量查词并发数（支持键盘输入，范围 1~500）
          const _AiConcurrencyTile(),
          const Divider(),

          // 快速预设
          _SectionHeader(title: context.tr('AI 预设')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AiConfig.presets.entries.map((entry) {
                final isSelected = aiConfig.baseUrl == entry.value.baseUrl &&
                    aiConfig.model == entry.value.model;
                return FilterChip(
                  label: Text(entry.key),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(settingsProvider.notifier).applyAiPreset(entry.key);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(),

          // 学习设置
          _SectionHeader(title: context.tr('学习设置')),
          ListTile(
            leading: const Icon(Icons.new_releases),
            title: Text(context.tr('每日新词上限')),
            subtitle: Text('${settings.dailyNewLimit} ${context.tr('个')}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editDailyLimit(context, ref, isNew: true),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: Text(context.tr('每日复习上限')),
            subtitle: Text('${settings.dailyReviewLimit} ${context.tr('个')}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editDailyLimit(context, ref, isNew: false),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.done_all),
            title: Text(context.tr('回答后自动确认')),
            subtitle: Text(context.tr('选择答案后自动确认，无需点击确认按钮')),
            value: settings.autoConfirm,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateAutoConfirm(value);
            },
          ),
          const Divider(),

          // 语音设置
          _SectionHeader(title: context.tr('语音设置')),
          ListTile(
            leading: const Icon(Icons.speed),
            title: Text(context.tr('TTS 语速')),
            subtitle: Slider(
              value: settings.ttsSpeed,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: '${(settings.ttsSpeed * 100).round()}%',
              onChanged: (value) {
                ref.read(settingsProvider.notifier).updateTtsSpeed(value);
              },
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: Text(context.tr('自动发音')),
            subtitle: Text(context.tr('题目出现时自动播放德语发音（翻牌/看德语选中文/听德语选单词/拼写模式）')),
            value: settings.autoPlayTts,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateAutoPlayTts(value);
            },
          ),
          const Divider(),

          // 拼写设置
          _SectionHeader(title: context.tr('拼写设置')),
          SwitchListTile(
            secondary: const Icon(Icons.spellcheck),
            title: Text(context.tr('宽容拼写')),
            subtitle: Text(context.tr('支持宽容拼写: ae→ä, oe→ö, ue→ü, ss→ß')),
            value: settings.tolerantSpelling,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateTolerantSpelling(value);
            },
          ),
          const Divider(),

          // 数据备份
          _SectionHeader(title: context.tr('数据备份')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _backupAllData(context, ref),
                    icon: const Icon(Icons.backup_outlined),
                    label: Text(context.tr('软件数据备份')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _restoreAllData(context, ref),
                    icon: const Icon(Icons.restore),
                    label: Text(context.tr('软件数据恢复')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade800,
                      side: BorderSide(color: Colors.amber.shade700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.tr('备份包含所有词书、单词、学习记录与 AI 缓存；恢复将完全覆盖当前全部数据'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const Divider(),

          // OneDrive 云同步
          const OneDriveSyncSection(),

          // 关于
          _SectionHeader(title: context.tr('关于')),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.tr('关于德语背单词')),
            subtitle: Text(
              '${context.trArgs('版本 {0}', [_appVersion])}\n${context.tr('© ZEKAKORA 版权所有')}',
            ),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'WortApp',
                applicationVersion: _appVersion,
                applicationLegalese: context.tr('德语背单词与语法助手'),
                children: [
                  const SizedBox(height: 16),
                  Text(context.tr(
                      '基于 SM-2 间隔重复算法，结合 AI 变位练习与联网查词。\nhttps://github.com/Zekakora/WortApp\n\n© ZEKAKORA All Right Reserved')),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getProviderName(String baseUrl) {
    if (baseUrl.contains('xiaomimimo')) return 'MiMo';
    if (baseUrl.contains('deepseek')) return 'DeepSeek';
    if (baseUrl.contains('openai')) return 'OpenAI';
    if (baseUrl.contains('anthropic')) return 'Claude';
    if (baseUrl.contains('generativelanguage')) return 'Gemini';
    if (baseUrl.contains('dashscope')) return '通义千问';
    if (baseUrl.contains('maas.aliyuncs.com')) return '阿里云';
    return AppLocale.tr('自定义');
  }

  void _editAiConfig(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final aiConfig = settings.aiConfig;

    final apiKeyController = TextEditingController(text: aiConfig.apiKey);
    final baseUrlController = TextEditingController(text: aiConfig.baseUrl);
    final modelController = TextEditingController(text: aiConfig.model);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('AI 配置')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('支持 OpenAI 兼容格式的 API'),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiKeyController,
                decoration: InputDecoration(
                  labelText: context.tr('API Key'),
                  hintText: context.tr('输入你的 API Key'),
                  prefixIcon: const Icon(Icons.key),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baseUrlController,
                decoration: InputDecoration(
                  labelText: context.tr('API 地址'),
                  hintText: context.tr('例如: https://api.openai.com/v1'),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: InputDecoration(
                  labelText: context.tr('模型名称'),
                  hintText: context.tr('例如: gpt-4o-mini'),
                  prefixIcon: const Icon(Icons.smart_toy),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('常用配置:'),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // 用可点击的预设标签替代一整列灰色网址：点一下即填入地址与模型
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AiConfig.presets.entries.map((entry) {
                    return ActionChip(
                      label: Text(entry.key),
                      onPressed: () {
                        baseUrlController.text = entry.value.baseUrl;
                        modelController.text = entry.value.model;
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('取消')),
          ),
          FilledButton(
            onPressed: () {
              final config = AiConfig(
                apiKey: apiKeyController.text.trim(),
                baseUrl: baseUrlController.text.trim(),
                model: modelController.text.trim(),
              );
              ref.read(settingsProvider.notifier).updateAiConfig(config);
              Navigator.pop(context);
            },
            child: Text(context.tr('保存')),
          ),
        ],
      ),
    ).whenComplete(() {
      apiKeyController.dispose();
      baseUrlController.dispose();
      modelController.dispose();
    });
  }

  void _editApiKey(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final controller = TextEditingController(text: settings.aiConfig.apiKey);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('修改 API Key')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: context.tr('API Key'),
            hintText: context.tr('输入新的 API Key'),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('取消')),
          ),
          FilledButton(
            onPressed: () {
              final config = settings.aiConfig.copyWith(
                apiKey: controller.text.trim(),
              );
              ref.read(settingsProvider.notifier).updateAiConfig(config);
              Navigator.pop(context);
            },
            child: Text(context.tr('保存')),
          ),
        ],
      ),
    ).whenComplete(() => controller.dispose());
  }

  void _editDailyLimit(BuildContext context, WidgetRef ref,
      {required bool isNew}) {
    final settings = ref.read(settingsProvider);
    final controller = TextEditingController(
      text: isNew
          ? settings.dailyNewLimit.toString()
          : settings.dailyReviewLimit.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(isNew ? '每日新词上限' : '每日复习上限')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: context.tr('个'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('取消')),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text) ?? 0;
              if (value <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('请输入大于 0 的正整数'))),
                );
                return;
              }
              if (isNew) {
                ref
                    .read(settingsProvider.notifier)
                    .updateDailyNewLimit(value);
              } else {
                ref
                    .read(settingsProvider.notifier)
                    .updateDailyReviewLimit(value);
              }
              Navigator.pop(context);
            },
            child: Text(context.tr('保存')),
          ),
        ],
      ),
    ).whenComplete(() => controller.dispose());
  }

  /// 备份全部数据（所有词书、单词、学习记录、AI 缓存与设置）
  Future<void> _backupAllData(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    if (db == null) {
      _showSnack(context, context.tr('数据库未就绪'));
      return;
    }

    try {
      final result = await ExportService(db).exportBackup();
      if (!context.mounted) return;
      if (!result.success || result.data == null) {
        _showSnack(context, result.error ?? context.tr('备份失败'));
        return;
      }
      await _saveBackupFile(context, result.data!);
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, context.trArgs('备份失败: {0}', [e]));
    }
  }

  /// 恢复全部数据（完全覆盖：先删除现有数据，再整体还原为备份内容）
  Future<void> _restoreAllData(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    if (db == null) {
      _showSnack(context, context.tr('数据库未就绪'));
      return;
    }

    // 选择备份文件
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: kIsWeb, // Web平台需要读取字节数据
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final fileName = file.name;
    final fileBytes = file.bytes;
    String? filePath;
    if (!kIsWeb) {
      filePath = file.path;
    }
    if (kIsWeb && fileBytes == null) return;
    if (!kIsWeb && filePath == null) return;

    // 黄色弹窗二次确认：恢复会完全覆盖当前所有数据
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: Colors.amber.shade800,
        ),
        title: Text(context.tr('恢复数据警告')),
        content: Text(
          '${context.tr('恢复操作将完全覆盖当前所有数据：\n\n')}'
          '${context.tr('• 删除当前全部词书、单词与学习记录\n')}'
          '${context.tr('• 删除全部 AI 查词缓存与应用设置\n')}'
          '${context.tr('• 整体替换为备份文件中的内容\n\n')}'
          '${context.tr('该操作不可撤销！建议先执行“软件数据备份”。')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('取消')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('我已了解，覆盖恢复')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final importResult = await ImportService(db).importBackup(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        wipeExisting: true,
      );

      // 数据已整体替换，刷新所有依赖数据库的 Provider（含连续打卡 / 待复习）
      invalidateDbDerivedProviders(ref);

      if (!context.mounted) return;
      Navigator.pop(context); // 关闭加载对话框

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr(
              importResult.errors.isEmpty ? '恢复成功' : '恢复完成（有错误）')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.trArgs('恢复词书: {0}', [importResult.deckCount])),
              Text(context.trArgs('恢复单词: {0}', [importResult.wordCount])),
              if (importResult.skipCount > 0)
                Text(context.trArgs('跳过: {0}', [importResult.skipCount])),
              if (importResult.errors.isNotEmpty) ...[
                ...importResult.errors
                    .take(5)
                    .map((e) => Text('• $e')),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('完成')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 关闭加载对话框
        _showSnack(context, context.trArgs('恢复失败: {0}', [e]));
      }
    }
  }

  /// 保存/分享备份文件（跨平台：Web/Android 触发系统分享，其余原生平台保存到文档目录）
  Future<void> _saveBackupFile(BuildContext context, ExportData data) async {
    try {
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
        await Share.shareXFiles(
          [
            XFile.fromData(
              data.bytes,
              mimeType: data.mimeType,
              name: data.fileName,
            ),
          ],
          fileNameOverrides: [data.fileName],
          text: context.trArgs('WortApp 数据备份：{0}', [data.fileName]),
        );
      } else {
        // 原生平台：保存到文档目录
        final dir = await getApplicationDocumentsDirectory();
        final filePath = p.join(dir.path, data.fileName);
        await File(filePath).writeAsBytes(data.bytes, flush: true);
        if (!context.mounted) return;
        _showSnack(context, context.trArgs('备份已保存到: {0}', [filePath]));
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, context.trArgs('保存备份文件失败: {0}', [e]));
    }
  }

  void _showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// AI 并发查询数设置项：支持 +/- 按钮和键盘直接输入（范围 1~500）
class _AiConcurrencyTile extends ConsumerStatefulWidget {
  const _AiConcurrencyTile();

  @override
  ConsumerState<_AiConcurrencyTile> createState() =>
      _AiConcurrencyTileState();
}

class _AiConcurrencyTileState extends ConsumerState<_AiConcurrencyTile> {
  static const int _minConcurrency = 1;
  static const int _maxConcurrency = 500;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: '${ref.read(settingsProvider).aiConcurrency}',
    );
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // 失焦时提交输入
    if (!_focusNode.hasFocus) {
      _commitInput();
    }
  }

  /// 解析输入并保存；无效或越界时回退到当前有效值
  void _commitInput() {
    final value = int.tryParse(_controller.text);
    if (value == null) {
      _controller.text = '${ref.read(settingsProvider).aiConcurrency}';
      return;
    }
    final clamped = value.clamp(_minConcurrency, _maxConcurrency);
    _controller.text = '$clamped';
    ref.read(settingsProvider.notifier).updateAiConcurrency(clamped);
  }

  void _update(int next) {
    ref.read(settingsProvider.notifier).updateAiConcurrency(next);
    _controller.text = '$next';
  }

  @override
  Widget build(BuildContext context) {
    final concurrency = ref.watch(settingsProvider).aiConcurrency;

    return ListTile(
      leading: const Icon(Icons.bolt),
      title: Text(context.tr('AI 并发查询数')),
      subtitle: Text(context.tr('批量查词同时查询的单词数，范围 1~500，越大越快，注意 API 限流')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: context.tr('减少并发'),
            onPressed: concurrency > _minConcurrency
                ? () => _update(concurrency - 1)
                : null,
          ),
          SizedBox(
            width: 64,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 3,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                isDense: true,
                counterText: '', // 隐藏字数计数
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _commitInput(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: context.tr('增加并发'),
            onPressed: concurrency < _maxConcurrency
                ? () => _update(concurrency + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
