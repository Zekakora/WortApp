import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/settings_provider.dart';

/// 设置页面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final aiConfig = settings.aiConfig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // AI 设置
          _SectionHeader(title: 'AI 设置'),
          ListTile(
            leading: Icon(
              Icons.smart_toy,
              color: aiConfig.isConfigured ? Colors.green : Colors.grey,
            ),
            title: const Text('AI 配置'),
            subtitle: Text(
              aiConfig.isConfigured
                  ? '${_getProviderName(aiConfig.baseUrl)} - ${aiConfig.model}'
                  : '未配置',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editAiConfig(context, ref),
          ),
          if (aiConfig.isConfigured)
            ListTile(
              leading: const Icon(Icons.key, size: 20),
              title: const Text('API Key'),
              subtitle: Text(
                '${aiConfig.apiKey.substring(0, aiConfig.apiKey.length.clamp(0, 8))}...',
              ),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () => _editApiKey(context, ref),
            ),
          // AI 批量查词并发数
          ListTile(
            leading: const Icon(Icons.bolt),
            title: const Text('AI 并发查询数'),
            subtitle: const Text('批量查词同时查询的单词数，越大越快，注意 API 限流'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: '减少并发',
                  onPressed: settings.aiConcurrency > 1
                      ? () {
                          ref
                              .read(settingsProvider.notifier)
                              .updateAiConcurrency(settings.aiConcurrency - 1);
                        }
                      : null,
                ),
                Text(
                  '${settings.aiConcurrency}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: '增加并发',
                  onPressed: settings.aiConcurrency < 5
                      ? () {
                          ref
                              .read(settingsProvider.notifier)
                              .updateAiConcurrency(settings.aiConcurrency + 1);
                        }
                      : null,
                ),
              ],
            ),
          ),
          const Divider(),

          // 快速预设
          _SectionHeader(title: 'AI 预设'),
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
          _SectionHeader(title: '学习设置'),
          ListTile(
            leading: const Icon(Icons.new_releases),
            title: const Text('每日新词上限'),
            subtitle: Text('${settings.dailyNewLimit} 个'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editDailyLimit(context, ref, isNew: true),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('每日复习上限'),
            subtitle: Text('${settings.dailyReviewLimit} 个'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editDailyLimit(context, ref, isNew: false),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.done_all),
            title: const Text('回答后自动确认'),
            subtitle: const Text('选择答案后自动确认，无需点击确认按钮'),
            value: settings.autoConfirm,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateAutoConfirm(value);
            },
          ),
          const Divider(),

          // 语音设置
          _SectionHeader(title: '语音设置'),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('TTS 语速'),
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
            title: const Text('自动发音'),
            subtitle: const Text('题目出现时自动播放德语发音（翻牌/看德语选中文/听德语选单词/拼写模式）'),
            value: settings.autoPlayTts,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateAutoPlayTts(value);
            },
          ),
          const Divider(),

          // 拼写设置
          _SectionHeader(title: '拼写设置'),
          SwitchListTile(
            secondary: const Icon(Icons.spellcheck),
            title: const Text('宽容拼写'),
            subtitle: const Text('ae→ä, oe→ö, ue→ü, ss→ß'),
            value: settings.tolerantSpelling,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateTolerantSpelling(value);
            },
          ),
          const Divider(),

          // 关于
          _SectionHeader(title: '关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于德语背单词'),
            subtitle: const Text('版本 1.0.1\n© ZEKAKORA版权所有'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '德语背单词',
                applicationVersion: '1.0.1',
                applicationLegalese: '德语背单词与语法助手',
                children: [
                  const SizedBox(height: 16),
                  const Text('基于 SM-2 间隔重复算法，结合 AI 变位练习与联网查词。'),
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
    return '自定义';
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
        title: const Text('AI 配置'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '支持 OpenAI 兼容格式的 API',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: '输入你的 API Key',
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'API 地址',
                  hintText: '例如: https://api.openai.com/v1',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: '模型名称',
                  hintText: '例如: gpt-4o-mini',
                  prefixIcon: Icon(Icons.smart_toy),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '常用配置:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...AiConfig.presets.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${entry.key}: ${entry.value.baseUrl}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
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
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _editApiKey(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final controller = TextEditingController(text: settings.aiConfig.apiKey);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改 API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: '输入新的 API Key',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final config = settings.aiConfig.copyWith(
                apiKey: controller.text.trim(),
              );
              ref.read(settingsProvider.notifier).updateAiConfig(config);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
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
        title: Text(isNew ? '每日新词上限' : '每日复习上限'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            suffixText: '个',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text) ?? 0;
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
            child: const Text('保存'),
          ),
        ],
      ),
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
