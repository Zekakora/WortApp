/// 设置页与 OneDrive 云同步相关文案——权威分片（由主流程维护）。
const Map<String, String> settingsEn = <String, String>{
  // 外观 / 语言
  '外观': 'Appearance',
  '跟随系统': 'Follow system',
  '日间': 'Light',
  '夜间': 'Dark',
  '语言': 'Language',
  '中文': '中文',
  '英语': 'English',
  '德语': 'Deutsch',
  // AI 设置
  'AI 设置': 'AI settings',
  'AI 配置': 'AI configuration',
  '未配置': 'Not configured',
  'API Key': 'API Key',
  'AI 并发查询数': 'AI concurrency',
  '批量查词同时查询的单词数，范围 1~500，越大越快，注意 API 限流':
      'Number of words queried in parallel. Range 1–500; higher is faster but mind API rate limits.',
  '减少并发': 'Decrease concurrency',
  '增加并发': 'Increase concurrency',
  'AI 预设': 'AI presets',
  '自定义': 'Custom',
  // 学习设置
  '学习设置': 'Study settings',
  '每日新词上限': 'Daily new-word limit',
  '每日复习上限': 'Daily review limit',
  '回答后自动确认': 'Auto-confirm after answering',
  '选择答案后自动确认，无需点击确认按钮':
      'Confirm automatically after selecting an answer; no need to tap the confirm button',
  // 语音设置
  '语音设置': 'Voice settings',
  'TTS 语速': 'TTS speed',
  '自动发音': 'Auto-pronounce',
  '题目出现时自动播放德语发音（翻牌/看德语选中文/听德语选单词/拼写模式）':
      'Automatically play German pronunciation when a question appears (flip / DE→ZH / listen / spelling)',
  // 拼写设置
  '拼写设置': 'Spelling settings',
  '宽容拼写': 'Tolerant spelling',
  '支持宽容拼写: ae→ä, oe→ö, ue→ü, ss→ß':
      'Tolerant spelling: ae→ä, oe→ö, ue→ü, ss→ß',
  // 数据备份
  '数据备份': 'Data backup',
  '软件数据备份': 'Back up data',
  '软件数据恢复': 'Restore data',
  '备份包含所有词书、单词、学习记录与 AI 缓存；恢复将完全覆盖当前全部数据':
      'Backup includes all wordbooks, words, study records and AI cache; restoring will completely overwrite all current data',
  // 关于
  '关于': 'About',
  '关于德语背单词': 'About WortApp',
  '版本 {0}': 'Version {0}',
  '© ZEKAKORA 版权所有': '© ZEKAKORA All rights reserved',
  '德语背单词与语法助手': 'German vocabulary & grammar assistant',
  '基于 SM-2 间隔重复算法，结合 AI 变位练习与联网查词。\nhttps://github.com/Zekakora/WortApp\n\n© ZEKAKORA All Right Reserved':
      'Spaced repetition based on the SM-2 algorithm, combined with AI conjugation practice and online word lookup.\nhttps://github.com/Zekakora/WortApp\n\n© ZEKAKORA All Right Reserved',
  // AI 配置弹窗
  '支持 OpenAI 兼容格式的 API': 'Supports OpenAI-compatible APIs',
  '输入你的 API Key': 'Enter your API Key',
  'API 地址': 'API URL',
  '例如: https://api.openai.com/v1': 'e.g. https://api.openai.com/v1',
  '模型名称': 'Model name',
  '例如: gpt-4o-mini': 'e.g. gpt-4o-mini',
  '常用配置:': 'Common presets:',
  '修改 API Key': 'Edit API Key',
  '输入新的 API Key': 'Enter a new API Key',
  '个': 'words',
  '请输入大于 0 的正整数': 'Please enter a positive integer greater than 0',
  // 恢复数据警告
  '恢复数据警告': 'Restore warning',
  '恢复操作将完全覆盖当前所有数据：\n\n':
      'Restoring will completely overwrite all current data:\n\n',
  '• 删除当前全部词书、单词与学习记录\n':
      '• Delete all current wordbooks, words and study records\n',
  '• 删除全部 AI 查词缓存与应用设置\n':
      '• Delete all AI lookup cache and app settings\n',
  '• 整体替换为备份文件中的内容\n\n':
      '• Replace everything with the backup file content\n\n',
  '该操作不可撤销！建议先执行“软件数据备份”。':
      'This action cannot be undone! Back up your data first.',
  '我已了解，覆盖恢复': 'I understand, overwrite',
  // 恢复结果
  '恢复成功': 'Restore successful',
  '恢复完成（有错误）': 'Restore finished (with errors)',
  '恢复词书: {0}': 'Wordbooks restored: {0}',
  '恢复单词: {0}': 'Words restored: {0}',
  '跳过: {0}': 'Skipped: {0}',
  // 提示
  '备份失败': 'Backup failed',
  '备份失败: {0}': 'Backup failed: {0}',
  '备份已保存到: {0}': 'Backup saved to: {0}',
  '保存备份文件失败: {0}': 'Failed to save backup file: {0}',
  '恢复失败: {0}': 'Restore failed: {0}',
  'WortApp 数据备份：{0}': 'WortApp data backup: {0}',
  // OneDrive
  'OneDrive 同步': 'OneDrive sync',
  '尚未配置 Azure 应用（Client ID）。\n在 Azure 门户注册应用并填写 Client ID 后，即可启用 OneDrive 同步。':
      'Azure app (Client ID) not configured.\nRegister an app in the Azure portal and enter the Client ID to enable OneDrive sync.',
  '配置位置: lib/core/constants/onedrive_config.dart':
      'Config location: lib/core/constants/onedrive_config.dart',
  '登录微软账号后，可在你的 OneDrive 专属文件夹（Apps/WortApp）中同步词书与学习进度，应用无法访问你的其他文件。':
      'After signing in with your Microsoft account, you can sync wordbooks and progress in your OneDrive app folder (Apps/WortApp). The app cannot access your other files.',
  '登录 OneDrive': 'Sign in to OneDrive',
  '已连接 OneDrive（尚未同步）': 'OneDrive connected (not synced yet)',
  '已连接 OneDrive · 上次同步: {0}':
      'OneDrive connected · Last sync: {0}',
  '立即同步': 'Sync now',
  '从云端恢复': 'Restore from cloud',
  '同步为双向差异合并：只合并有变化的词书、单词、学习进度与收藏，不删除任何数据；同一单词两端都修改过时才会弹窗选择方向。「从云端恢复」将用云端备份完全覆盖当前设备的数据，需二次确认。':
      'Sync is a two-way diff merge: only changed wordbooks, words, progress and favorites are merged, nothing is deleted; a dialog appears only when the same word was edited on both sides. "Restore from cloud" will completely overwrite this device\'s data with the cloud backup and requires confirmation.',
  '退出登录': 'Sign out',
  '已连接到 OneDrive': 'Connected to OneDrive',
  '登录失败或已取消': 'Sign-in failed or cancelled',
  '已退出 OneDrive 登录': 'Signed out of OneDrive',
  '云端还没有备份，请先在其他设备上传':
      'No backup in the cloud yet. Upload from another device first.',
  '从 OneDrive 恢复数据': 'Restore data from OneDrive',
  '将使用云端备份完全覆盖当前设备的数据：\n\n':
      'This will completely overwrite this device\'s data with the cloud backup:\n\n',
  '• 备份导出时间：{0}\n': '• Backup exported at: {0}\n',
  '• 词书 {0} 个 / 单词 {1} 个\n\n': '• {0} wordbooks / {1} words\n\n',
  '当前设备上的词书与学习记录将被替换，该操作不可撤销！':
      'Wordbooks and study records on this device will be replaced. This cannot be undone!',
  '（词书 {0} 个 / 单词 {1} 个）': '({0} wordbooks / {1} words)',
  '已从 OneDrive 恢复': 'Restored from OneDrive',
};

const Map<String, String> settingsDe = <String, String>{
  // Darstellung / Sprache
  '外观': 'Darstellung',
  '跟随系统': 'System',
  '日间': 'Hell',
  '夜间': 'Dunkel',
  '语言': 'Sprache',
  '中文': '中文',
  '英语': 'English',
  '德语': 'Deutsch',
  // KI
  'AI 设置': 'KI-Einstellungen',
  'AI 配置': 'KI-Konfiguration',
  '未配置': 'Nicht konfiguriert',
  'API Key': 'API-Schlüssel',
  'AI 并发查询数': 'KI-Parallelität',
  '批量查词同时查询的单词数，范围 1~500，越大越快，注意 API 限流':
      'Anzahl parallel abgefragter Wörter. Bereich 1–500; höher ist schneller, aber API-Ratelimits beachten.',
  '减少并发': 'Parallelität verringern',
  '增加并发': 'Parallelität erhöhen',
  'AI 预设': 'KI-Voreinstellungen',
  '自定义': 'Benutzerdefiniert',
  // Lernen
  '学习设置': 'Lern-Einstellungen',
  '每日新词上限': 'Tägliches Limit neuer Wörter',
  '每日复习上限': 'Tägliches Wiederholungslimit',
  '回答后自动确认': 'Nach Antwort automatisch bestätigen',
  '选择答案后自动确认，无需点击确认按钮':
      'Nach Auswahl automatisch bestätigen, ohne Bestätigungstaste',
  // Sprache
  '语音设置': 'Sprach-Einstellungen',
  'TTS 语速': 'TTS-Geschwindigkeit',
  '自动发音': 'Automatische Aussprache',
  '题目出现时自动播放德语发音（翻牌/看德语选中文/听德语选单词/拼写模式）':
      'Deutsche Aussprache automatisch abspielen, wenn eine Frage erscheint (Umdrehen / DE→ZH / Hören / Buchstabieren)',
  // Rechtschreibung
  '拼写设置': 'Rechtschreib-Einstellungen',
  '宽容拼写': 'Tolerante Schreibweise',
  '支持宽容拼写: ae→ä, oe→ö, ue→ü, ss→ß':
      'Tolerante Schreibweise: ae→ä, oe→ö, ue→ü, ss→ß',
  // Sicherung
  '数据备份': 'Datensicherung',
  '软件数据备份': 'Daten sichern',
  '软件数据恢复': 'Daten wiederherstellen',
  '备份包含所有词书、单词、学习记录与 AI 缓存；恢复将完全覆盖当前全部数据':
      'Die Sicherung enthält alle Wortlisten, Wörter, Lernfortschritte und den KI-Cache; die Wiederherstellung überschreibt alle aktuellen Daten vollständig',
  // Über
  '关于': 'Über',
  '关于德语背单词': 'Über WortApp',
  '版本 {0}': 'Version {0}',
  '© ZEKAKORA 版权所有': '© ZEKAKORA Alle Rechte vorbehalten',
  '德语背单词与语法助手': 'Deutsch-Vokabel- und Grammatik-Assistent',
  '基于 SM-2 间隔重复算法，结合 AI 变位练习与联网查词。\nhttps://github.com/Zekakora/WortApp\n\n© ZEKAKORA All Right Reserved':
      'Spaced Repetition nach dem SM-2-Algorithmus, kombiniert mit KI-Konjugationsübungen und Online-Wortsuche.\nhttps://github.com/Zekakora/WortApp\n\n© ZEKAKORA All Right Reserved',
  // KI-Dialog
  '支持 OpenAI 兼容格式的 API': 'Unterstützt OpenAI-kompatible APIs',
  '输入你的 API Key': 'API-Schlüssel eingeben',
  'API 地址': 'API-Adresse',
  '例如: https://api.openai.com/v1': 'z. B. https://api.openai.com/v1',
  '模型名称': 'Modellname',
  '例如: gpt-4o-mini': 'z. B. gpt-4o-mini',
  '常用配置:': 'Häufige Konfigurationen:',
  '修改 API Key': 'API-Schlüssel ändern',
  '输入新的 API Key': 'Neuen API-Schlüssel eingeben',
  '个': 'Wörter',
  '请输入大于 0 的正整数': 'Bitte eine positive ganze Zahl größer 0 eingeben',
  // Warnung
  '恢复数据警告': 'Wiederherstellungswarnung',
  '恢复操作将完全覆盖当前所有数据：\n\n':
      'Die Wiederherstellung überschreibt alle aktuellen Daten vollständig:\n\n',
  '• 删除当前全部词书、单词与学习记录\n':
      '• Alle aktuellen Wortlisten, Wörter und Lernfortschritte löschen\n',
  '• 删除全部 AI 查词缓存与应用设置\n':
      '• Den gesamten KI-Suchcache und die App-Einstellungen löschen\n',
  '• 整体替换为备份文件中的内容\n\n':
      '• Alles durch den Inhalt der Sicherungsdatei ersetzen\n\n',
  '该操作不可撤销！建议先执行“软件数据备份”。':
      'Dieser Vorgang kann nicht rückgängig gemacht werden! Bitte zuvor eine Datensicherung durchführen.',
  '我已了解，覆盖恢复': 'Verstanden, überschreiben',
  // Ergebnis
  '恢复成功': 'Wiederherstellung erfolgreich',
  '恢复完成（有错误）': 'Wiederherstellung abgeschlossen (mit Fehlern)',
  '恢复词书: {0}': 'Wortlisten wiederhergestellt: {0}',
  '恢复单词: {0}': 'Wörter wiederhergestellt: {0}',
  '跳过: {0}': 'Übersprungen: {0}',
  // Hinweise
  '备份失败': 'Sicherung fehlgeschlagen',
  '备份失败: {0}': 'Sicherung fehlgeschlagen: {0}',
  '备份已保存到: {0}': 'Sicherung gespeichert unter: {0}',
  '保存备份文件失败: {0}':
      'Sicherungsdatei konnte nicht gespeichert werden: {0}',
  '恢复失败: {0}': 'Wiederherstellung fehlgeschlagen: {0}',
  'WortApp 数据备份：{0}': 'WortApp-Datensicherung: {0}',
  // OneDrive
  'OneDrive 同步': 'OneDrive-Synchronisierung',
  '尚未配置 Azure 应用（Client ID）。\n在 Azure 门户注册应用并填写 Client ID 后，即可启用 OneDrive 同步。':
      'Azure-App (Client-ID) nicht konfiguriert.\nRegistrieren Sie eine App im Azure-Portal und geben Sie die Client-ID ein, um die OneDrive-Synchronisierung zu aktivieren.',
  '配置位置: lib/core/constants/onedrive_config.dart':
      'Konfigurationsort: lib/core/constants/onedrive_config.dart',
  '登录微软账号后，可在你的 OneDrive 专属文件夹（Apps/WortApp）中同步词书与学习进度，应用无法访问你的其他文件。':
      'Nach der Anmeldung mit Ihrem Microsoft-Konto können Sie Wortlisten und Fortschritt im OneDrive-App-Ordner (Apps/WortApp) synchronisieren. Die App kann nicht auf Ihre anderen Dateien zugreifen.',
  '登录 OneDrive': 'Bei OneDrive anmelden',
  '已连接 OneDrive（尚未同步）': 'OneDrive verbunden (noch nicht synchronisiert)',
  '已连接 OneDrive · 上次同步: {0}':
      'OneDrive verbunden · Letzte Synchronisierung: {0}',
  '立即同步': 'Jetzt synchronisieren',
  '从云端恢复': 'Aus der Cloud wiederherstellen',
  '同步为双向差异合并：只合并有变化的词书、单词、学习进度与收藏，不删除任何数据；同一单词两端都修改过时才会弹窗选择方向。「从云端恢复」将用云端备份完全覆盖当前设备的数据，需二次确认。':
      'Die Synchronisierung ist eine bidirektionale Diff-Zusammenführung: nur geänderte Wortlisten, Wörter, Fortschritte und Favoriten werden zusammengeführt, nichts wird gelöscht; ein Dialog erscheint nur, wenn dasselbe Wort auf beiden Seiten bearbeitet wurde. „Aus der Cloud wiederherstellen“ überschreibt die Daten dieses Geräts vollständig mit der Cloud-Sicherung und erfordert eine Bestätigung.',
  '退出登录': 'Abmelden',
  '已连接到 OneDrive': 'Mit OneDrive verbunden',
  '登录失败或已取消': 'Anmeldung fehlgeschlagen oder abgebrochen',
  '已退出 OneDrive 登录': 'Von OneDrive abgemeldet',
  '云端还没有备份，请先在其他设备上传':
      'Noch keine Sicherung in der Cloud. Bitte zuerst von einem anderen Gerät hochladen.',
  '从 OneDrive 恢复数据': 'Daten von OneDrive wiederherstellen',
  '将使用云端备份完全覆盖当前设备的数据：\n\n':
      'Die Daten dieses Geräts werden vollständig durch die Cloud-Sicherung überschrieben:\n\n',
  '• 备份导出时间：{0}\n': '• Sicherung exportiert am: {0}\n',
  '• 词书 {0} 个 / 单词 {1} 个\n\n': '• {0} Wortlisten / {1} Wörter\n\n',
  '当前设备上的词书与学习记录将被替换，该操作不可撤销！':
      'Wortlisten und Lernfortschritte auf diesem Gerät werden ersetzt. Dies kann nicht rückgängig gemacht werden!',
  '（词书 {0} 个 / 单词 {1} 个）': '({0} Wortlisten / {1} Wörter)',
  '已从 OneDrive 恢复': 'Von OneDrive wiederhergestellt',
};
