import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../../services/import_export/import_service.dart';
import '../../providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 导入模式选择结果
class ImportConfig {
  final ImportMode mode;
  final int? wordColumnIndex; // 简单模式下选择的列索引
  final bool hasHeader;

  const ImportConfig({
    required this.mode,
    this.wordColumnIndex,
    this.hasHeader = true,
  });
}

/// 导入对话框
class ImportDialog extends ConsumerStatefulWidget {
  final String? filePath;
  final Uint8List? fileBytes;
  final String fileName;
  final int deckId;
  final String deckName;

  const ImportDialog({
    super.key,
    this.filePath,
    this.fileBytes,
    required this.fileName,
    required this.deckId,
    required this.deckName,
  });

  /// 显示导入对话框
  static Future<ImportConfig?> show({
    required BuildContext context,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required int deckId,
    required String deckName,
  }) {
    return showDialog<ImportConfig>(
      context: context,
      builder: (context) => ImportDialog(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        deckId: deckId,
        deckName: deckName,
      ),
    );
  }

  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<ImportDialog> {
  FilePreview? _preview;
  bool _isLoading = true;
  String? _error;
  ImportMode _selectedMode = ImportMode.simple;
  int? _selectedColumnIndex;
  bool _hasHeader = true;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final db = ref.read(databaseProvider);
      if (db == null) {
        setState(() {
          _error = '数据库未就绪';
          _isLoading = false;
        });
        return;
      }

      final importService = ImportService(db);
      final preview = await importService.previewFile(
        filePath: widget.filePath,
        fileBytes: widget.fileBytes,
        fileName: widget.fileName,
        maxRows: 5,
      );

      setState(() {
        _preview = preview;
        _isLoading = false;
        // 默认选择第一列
        if (preview.headers.isNotEmpty) {
          _selectedColumnIndex = 0;
        }
      });
    } catch (e) {
      setState(() {
        _error = '加载文件失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入选项'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                : _buildContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _canImport() ? _onImport : null,
          child: const Text('开始导入'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文件信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _preview!.fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_preview!.headers.length} 列, ${_preview!.rows.length} 行预览',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 导入模式选择
          const Text('导入模式', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildModeOption(
            mode: ImportMode.simple,
            icon: Icons.auto_awesome,
            title: '智能导入',
            subtitle: '只选择单词列，AI自动获取词意、词性等信息',
          ),
          const SizedBox(height: 8),
          _buildModeOption(
            mode: ImportMode.full,
            icon: Icons.table_chart,
            title: '完整导入',
            subtitle: '按固定格式导入（德语、中文、例句等）',
          ),
          const SizedBox(height: 16),

          // 简单模式：列选择
          if (_selectedMode == ImportMode.simple) ...[
            const Text('选择单词列', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildColumnSelector(),
            const SizedBox(height: 16),
          ],

          // 表头选项
          CheckboxListTile(
            value: _hasHeader,
            onChanged: (value) {
              setState(() {
                _hasHeader = value ?? true;
              });
            },
            title: const Text('首行为表头'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          // 数据预览
          if (_preview!.rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('数据预览', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPreviewTable(),
          ],
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required ImportMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            Radio<ImportMode>(
              value: mode,
              groupValue: _selectedMode,
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
            ),
            Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_preview!.headers.length, (index) {
        final header = _preview!.headers[index];
        final isSelected = _selectedColumnIndex == index;
        final displayText = header.isNotEmpty ? header : '列 ${index + 1}';

        return ChoiceChip(
          label: Text(displayText),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedColumnIndex = index;
              });
            }
          },
        );
      }),
    );
  }

  Widget _buildPreviewTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 40,
          headingRowHeight: 36,
          columns: _preview!.headers.asMap().entries.map((entry) {
            final isWordColumn = _selectedMode == ImportMode.simple &&
                _selectedColumnIndex == entry.key;
            return DataColumn(
              label: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: isWordColumn
                    ? BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                child: Text(
                  entry.value.isNotEmpty ? entry.value : '列${entry.key + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isWordColumn
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
          rows: _preview!.rows.take(3).map((row) {
            return DataRow(
              cells: row.asMap().entries.map((entry) {
                final isWordColumn = _selectedMode == ImportMode.simple &&
                    _selectedColumnIndex == entry.key;
                return DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: isWordColumn
                        ? BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          )
                        : null,
                    child: Text(
                      entry.value?.toString() ?? '',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _canImport() {
    if (_selectedMode == ImportMode.simple) {
      return _selectedColumnIndex != null;
    }
    return true;
  }

  void _onImport() {
    Navigator.pop(
      context,
      ImportConfig(
        mode: _selectedMode,
        wordColumnIndex: _selectedColumnIndex,
        hasHeader: _hasHeader,
      ),
    );
  }
}
