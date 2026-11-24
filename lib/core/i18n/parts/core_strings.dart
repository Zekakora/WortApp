/// 非 Widget 环境（算法 / Provider / Service）使用的中文文案——由本地化任务填充。
///
/// key 为中文原文；带占位符的 key 使用 `{0}`、`{1}`…（与 AppLocale.trArgs 对应）。
const Map<String, String> coreStringsEn = <String, String>{
  // SM-2 反馈标签与描述
  '忘记': 'Forgot',
  '模糊': 'Vague',
  '熟悉': 'Familiar',
  '简单': 'Easy',
  '1 天后复习': 'Review in 1 day',
  '{0} 天后复习': 'Review in {0} days',
  // 德语词形解析
  '名词首字母需要大写':
      'The first letter of a noun must be capitalized',
  '首字母应小写': 'The first letter should be lowercase',
  // 数据库 Provider
  '数据库初始化超时': 'Database initialization timed out',
  '数据库初始化失败: {0}': 'Database initialization failed: {0}',
  // 批量任务
  '无任务': 'No tasks',
  // OneDrive Provider
  '登录失败或已取消': 'Sign-in failed or was cancelled',
  '退出登录失败: {0}': 'Sign-out failed: {0}',
  '服务未初始化': 'Service not initialized',
  '上传失败: {0}': 'Upload failed: {0}',
  '同步失败: {0}': 'Sync failed: {0}',
  '下载恢复失败: {0}': 'Download/restore failed: {0}',
  // OneDrive 同步服务
  '备份生成失败': 'Failed to create backup',
  '上传失败': 'Upload failed',
  '云端还没有备份，请先执行上传':
      'There is no backup in the cloud yet. Please upload first',
  '下载失败': 'Download failed',
  '云端备份文件为空': 'The cloud backup file is empty',
  '恢复完成，但有 {0} 条错误':
      'Restore completed, but with {0} error(s)',
  '云端备份解析失败: {0}': 'Failed to parse cloud backup: {0}',
  '云端备份由更新版本的 WortApp 生成（备份 v{0}），'
          '请先更新应用后再同步，以免数据格式不兼容':
      'The cloud backup was created by a newer version of WortApp '
          '(backup v{0}). Please update the app before syncing to avoid '
          'incompatible data formats',
  '合并写入本地失败: {0}': 'Failed to write merged data locally: {0}',
  // 导入服务
  '不支持的文件格式: .{0}': 'Unsupported file format: .{0}',
  '文件不存在: {0}': 'File not found: {0}',
  '未提供文件数据': 'No file data provided',
  'Excel 文件没有工作表': 'The Excel file has no worksheets',
  '行 {0}: 列索引超出范围': 'Row {0}: column index out of range',
  '行 {0}: 单词为空': 'Row {0}: the word is empty',
  '（已存在于词书「{0}」）': '(already exists in the wordbook "{0}")',
  '行 {0}: 单词“{1}”{2}已存在，已跳过':
      'Row {0}: the word "{1}"{2} already exists; skipped',
  '行 {0}: 导入失败 - {1}': 'Row {0}: import failed - {1}',
  '行 {0}: 列数不足，至少需要德语和中文两列':
      'Row {0}: not enough columns; at least German and Chinese columns '
          'are required',
  '行 {0}: 德语或中文为空': 'Row {0}: German or Chinese is empty',
  '文件不存在': 'File not found',
  '备份文件解析失败: {0}': 'Failed to parse backup file: {0}',
  '不是有效的 WortApp 备份文件': 'Not a valid WortApp backup file',
  '备份文件中缺少词书数据': 'The backup file is missing wordbook data',
  '清空现有数据失败: {0}': 'Failed to clear existing data: {0}',
  '跳过：备份中存在无名称的词书':
      'Skipped: the backup contains an unnamed wordbook',
  '词书导入失败: {0}': 'Wordbook import failed: {0}',
  'AI 缓存恢复失败: {0}': 'Failed to restore AI cache: {0}',
  '设置恢复失败: {0}': 'Failed to restore settings: {0}',
  '单词导入失败: {0}': 'Word import failed: {0}',
  // 导出服务
  '词书不存在': 'Wordbook not found',
  '德语单词': 'German word',
  '中文释义': 'Chinese definition',
  '例句和拓展': 'Example sentences & extras',
  '标记': 'Tags',
  '上次学习日期': 'Last studied',
  '熟练程度': 'Proficiency',
  '重复次数': 'Repetitions',
  '复习间隔(天)': 'Review interval (days)',
  '简易度因子': 'Ease factor',
  '下次复习日期': 'Next review date',
  '生成 Excel 文件失败': 'Failed to generate Excel file',
  '导出失败: {0}': 'Export failed: {0}',
  // 批量任务组件
  'AI 任务进行中': 'AI task in progress',
  'AI 任务记录': 'AI task records',
  'AI 任务列表': 'AI task list',
  '清除已完成': 'Clear completed',
  '清除全部': 'Clear all',
  '暂无任务记录': 'No task records',
  '关闭': 'Close',
  '移除': 'Remove',
  '完成: {0} 成功, {1} 失败{2}':
      'Completed: {0} succeeded, {1} failed{2}',
  '（{0} 秒）': '({0} s)',
  '排队中...': 'Queued...',
  // OneDrive 同步结果与冲突弹窗
  '同步完成': 'Sync complete',
  '新词书 {0} 个': '{0} new wordbook(s)',
  '新词 {0} 个': '{0} new word(s)',
  '更新 {0} 个': '{0} updated',
  '（{0}）': '({0})',
  '检测到 {0} 处数据冲突，未处理':
      'Detected {0} data conflict(s), not resolved',
  '操作失败': 'Operation failed',
  '• {0}（{1}）\n  本地 {2} · 云端 {3}':
      '• {0} ({1})\n  Local {2} · Cloud {3}',
  '\n…等共 {0} 处': '\n…and {0} more in total',
  '检测到词义编辑冲突': 'Conflicting definition edits detected',
  '以下单词的词义内容在本地与云端都被编辑过：\n\n{0}{1}\n\n'
          '学习进度与收藏已自动合并，仅需选择以哪台设备编辑的词义为准'
          '（另一台设备的词义修改将被覆盖）：':
      'The definitions of the following words were edited both locally and '
          'in the cloud:\n\n{0}{1}\n\nThe learning progress and favorites have '
          'been merged automatically. You only need to choose which device\'s '
          'definition to keep (the other device\'s definition changes will be '
          'overwritten):',
  '暂不处理': 'Not now',
  '以云端为准': 'Use cloud version',
  '以本地为准': 'Use local version',
  '无记录': 'No record',
  '{0}月{1}日 {2}': '{0}/{1} {2}',
};

const Map<String, String> coreStringsDe = <String, String>{
  // SM-2 反馈标签与描述
  '忘记': 'Vergessen',
  '模糊': 'Unsicher',
  '熟悉': 'Vertraut',
  '简单': 'Einfach',
  '1 天后复习': 'Wiederholung in 1 Tag',
  '{0} 天后复习': 'Wiederholung in {0} Tagen',
  // 德语词形解析
  '名词首字母需要大写': 'Nomen müssen großgeschrieben werden',
  '首字母应小写': 'Der erste Buchstabe sollte klein sein',
  // 数据库 Provider
  '数据库初始化超时': 'Zeitüberschreitung bei der Datenbankinitialisierung',
  '数据库初始化失败: {0}':
      'Datenbankinitialisierung fehlgeschlagen: {0}',
  // 批量任务
  '无任务': 'Keine Aufgaben',
  // OneDrive Provider
  '登录失败或已取消': 'Anmeldung fehlgeschlagen oder abgebrochen',
  '退出登录失败: {0}': 'Abmeldung fehlgeschlagen: {0}',
  '服务未初始化': 'Dienst nicht initialisiert',
  '上传失败: {0}': 'Upload fehlgeschlagen: {0}',
  '同步失败: {0}': 'Synchronisierung fehlgeschlagen: {0}',
  '下载恢复失败: {0}': 'Herunterladen/Wiederherstellen fehlgeschlagen: {0}',
  // OneDrive 同步服务
  '备份生成失败': 'Backup konnte nicht erstellt werden',
  '上传失败': 'Upload fehlgeschlagen',
  '云端还没有备份，请先执行上传':
      'Es gibt noch kein Backup in der Cloud. Bitte zuerst hochladen',
  '下载失败': 'Download fehlgeschlagen',
  '云端备份文件为空': 'Die Cloud-Backup-Datei ist leer',
  '恢复完成，但有 {0} 条错误':
      'Wiederherstellung abgeschlossen, aber mit {0} Fehler(n)',
  '云端备份解析失败: {0}': 'Cloud-Backup konnte nicht gelesen werden: {0}',
  '云端备份由更新版本的 WortApp 生成（备份 v{0}），'
          '请先更新应用后再同步，以免数据格式不兼容':
      'Das Cloud-Backup wurde von einer neueren WortApp-Version erstellt '
          '(Backup v{0}). Bitte die App zuerst aktualisieren, um inkompatible '
          'Datenformate zu vermeiden',
  '合并写入本地失败: {0}':
      'Zusammengeführte Daten konnten nicht lokal gespeichert werden: {0}',
  // 导入服务
  '不支持的文件格式: .{0}': 'Nicht unterstütztes Dateiformat: .{0}',
  '文件不存在: {0}': 'Datei nicht gefunden: {0}',
  '未提供文件数据': 'Keine Dateidaten bereitgestellt',
  'Excel 文件没有工作表': 'Die Excel-Datei enthält kein Arbeitsblatt',
  '行 {0}: 列索引超出范围':
      'Zeile {0}: Spaltenindex außerhalb des gültigen Bereichs',
  '行 {0}: 单词为空': 'Zeile {0}: Das Wort ist leer',
  '（已存在于词书「{0}」）':
      '(bereits in der Wortliste „{0}“ vorhanden)',
  '行 {0}: 单词“{1}”{2}已存在，已跳过':
      'Zeile {0}: Das Wort „{1}“{2} ist bereits vorhanden; übersprungen',
  '行 {0}: 导入失败 - {1}': 'Zeile {0}: Import fehlgeschlagen - {1}',
  '行 {0}: 列数不足，至少需要德语和中文两列':
      'Zeile {0}: Zu wenige Spalten; mindestens eine deutsche und eine '
          'chinesische Spalte sind erforderlich',
  '行 {0}: 德语或中文为空': 'Zeile {0}: Deutsch oder Chinesisch ist leer',
  '文件不存在': 'Datei nicht gefunden',
  '备份文件解析失败: {0}':
      'Backup-Datei konnte nicht gelesen werden: {0}',
  '不是有效的 WortApp 备份文件': 'Keine gültige WortApp-Backup-Datei',
  '备份文件中缺少词书数据': 'In der Backup-Datei fehlen Wortlistendaten',
  '清空现有数据失败: {0}':
      'Vorhandene Daten konnten nicht gelöscht werden: {0}',
  '跳过：备份中存在无名称的词书':
      'Übersprungen: Das Backup enthält eine Wortliste ohne Namen',
  '词书导入失败: {0}': 'Import der Wortliste fehlgeschlagen: {0}',
  'AI 缓存恢复失败: {0}':
      'AI-Cache konnte nicht wiederhergestellt werden: {0}',
  '设置恢复失败: {0}':
      'Einstellungen konnten nicht wiederhergestellt werden: {0}',
  '单词导入失败: {0}': 'Import des Wortes fehlgeschlagen: {0}',
  // 导出服务
  '词书不存在': 'Wortliste nicht gefunden',
  '德语单词': 'Deutsches Wort',
  '中文释义': 'Chinesische Bedeutung',
  '例句和拓展': 'Beispielsätze und Ergänzungen',
  '标记': 'Markierungen',
  '上次学习日期': 'Zuletzt gelernt am',
  '熟练程度': 'Kenntnisstand',
  '重复次数': 'Wiederholungen',
  '复习间隔(天)': 'Wiederholungsintervall (Tage)',
  '简易度因子': 'Leichtigkeitsfaktor',
  '下次复习日期': 'Nächstes Wiederholungsdatum',
  '生成 Excel 文件失败': 'Excel-Datei konnte nicht erstellt werden',
  '导出失败: {0}': 'Export fehlgeschlagen: {0}',
  // 批量任务组件
  'AI 任务进行中': 'AI-Aufgabe läuft',
  'AI 任务记录': 'AI-Aufgabenprotokoll',
  'AI 任务列表': 'AI-Aufgabenliste',
  '清除已完成': 'Abgeschlossene löschen',
  '清除全部': 'Alle löschen',
  '暂无任务记录': 'Keine Aufgabenaufzeichnungen',
  '关闭': 'Schließen',
  '移除': 'Entfernen',
  '完成: {0} 成功, {1} 失败{2}':
      'Abgeschlossen: {0} erfolgreich, {1} fehlgeschlagen{2}',
  '（{0} 秒）': '({0} Sek.)',
  '排队中...': 'In Warteschlange...',
  // OneDrive 同步结果与冲突弹窗
  '同步完成': 'Synchronisierung abgeschlossen',
  '新词书 {0} 个': '{0} neue Wortliste(n)',
  '新词 {0} 个': '{0} neue Wörter',
  '更新 {0} 个': '{0} aktualisiert',
  '（{0}）': '({0})',
  '检测到 {0} 处数据冲突，未处理':
      '{0} Datenkonflikt(e) erkannt, nicht behandelt',
  '操作失败': 'Vorgang fehlgeschlagen',
  '• {0}（{1}）\n  本地 {2} · 云端 {3}':
      '• {0} ({1})\n  Lokal {2} · Cloud {3}',
  '\n…等共 {0} 处': '\n…und insgesamt {0} weitere',
  '检测到词义编辑冲突': 'Konflikte bei Bedeutungsänderungen erkannt',
  '以下单词的词义内容在本地与云端都被编辑过：\n\n{0}{1}\n\n'
          '学习进度与收藏已自动合并，仅需选择以哪台设备编辑的词义为准'
          '（另一台设备的词义修改将被覆盖）：':
      'Die Bedeutungen der folgenden Wörter wurden sowohl lokal als auch in '
          'der Cloud bearbeitet:\n\n{0}{1}\n\nLernfortschritt und Favoriten '
          'wurden automatisch zusammengeführt. Sie müssen nur wählen, welche '
          'Definition gilt (die Änderungen des anderen Geräts werden '
          'überschrieben):',
  '暂不处理': 'Nicht jetzt',
  '以云端为准': 'Cloud-Version verwenden',
  '以本地为准': 'Lokale Version verwenden',
  '无记录': 'Kein Eintrag',
  '{0}月{1}日 {2}': '{0}.{1}. {2}',
};
