/// 变位/变格练习相关文案——由本地化任务填充。
const Map<String, String> conjugationEn = <String, String>{
  // ── 通用按钮 / 标签 ──────────────────────────────
  '取消': 'Cancel',
  '确定': 'OK',
  '完成': 'Done',
  '保存': 'Save',
  '删除': 'Delete',
  '返回': 'Back',
  '后台运行': 'Run in background',
  '格式化': 'Format',
  '自定义': 'Custom',
  '手动': 'Manual',

  // ── 变位练习主界面 ───────────────────────────────
  '变位练习': 'Conjugation practice',
  '请先选择一个词书': 'Please select a deck first',
  '当前词书': 'Current deck',
  '练习参数': 'Practice settings',
  '单次练习词量': 'Words per session',
  '{0} 个': '{0}',
  '当前: {0} 个': 'Current: {0}',
  '练习范围': 'Practice range',
  '随机练习': 'Random practice',
  '只练今日单词': "Today's words only",
  '仅从今天学习过的单词中抽取': 'Draw only from words studied today',
  '从整个词书随机抽取': 'Draw randomly from the whole deck',
  '选择练习类型': 'Choose practice type',
  '动词变位': 'Verb conjugation',
  '名词变格': 'Noun declension',
  '形容词变级': 'Adjective comparison',
  'Adjektiv Steigerung · 比较级 & 最高级':
      'Adjektiv Steigerung · Comparative & Superlative',
  '变位数据管理': 'Conjugation data management',
  '管理变位数据': 'Manage conjugation data',
  '查看各单词变位数据状态，可多选更新 / 删除':
      'View the conjugation data status of each word; update or delete in bulk',
  'AI 批量生成变位数据': 'Batch-generate conjugation data with AI',
  '使用 AI 分析词书中的词汇，生成变位数据并缓存到本地':
      'Use AI to analyze the words in the deck, generate conjugation data, and cache it locally',
  '请先在设置中配置 AI API Key':
      'Please configure the AI API key in settings first',
  '今日还没有学习过的单词，请先在学习模式中学习':
      "No words have been studied today yet. Please study in Study mode first",
  '，请先在下方"变位数据管理"中生成变位数据':
      ', please generate conjugation data in "Conjugation data management" below first',
  '词书中没有可练习的{0}数据{1}':
      'No practice data for {0} is available in the deck{1}',
  '错误: {0}': 'Error: {0}',

  // ── 自定义词量对话框 ─────────────────────────────
  '自定义单次练习词量': 'Custom words per session',
  '单词数量': 'Number of words',
  '请输入正整数': 'Enter a positive integer',
  '请输入有效的正整数': 'Please enter a valid positive integer',

  // ── 进度对话框 ───────────────────────────────────
  'AI 生成变位数据（{0} 个单词）':
      'AI is generating conjugation data ({0} words)',
  '无需生成': 'Nothing to generate',
  '生成完成': 'Generation complete',
  'AI 生成变位数据': 'AI-generate conjugation data',
  '{0} 个单词需要生成': '{0} words need to be generated',
  '正在处理: {0}': 'Processing: {0}',
  '关闭窗口可后台运行': 'Close the window to keep running in the background',
  '所有单词已有变位数据': 'All words already have conjugation data',
  '成功 {0} 个': 'Succeeded: {0}',
  '，失败 {0} 个': ', failed: {0}',

  // ── 练习模式标题 / 题干 ──────────────────────────
  '现在时': 'Present tense',
  '过去时': 'Past tense',
  '现在完成时': 'Present perfect',
  '被动语态': 'Passive voice',
  '定冠词/性属': 'Definite article/gender',
  '第二格单数': 'Genitive singular',
  '复数形式': 'Plural form',
  '变级练习': 'Comparison practice',
  '请填写 "{0}" 的{1}全部人称变位':
      'Fill in all person conjugations of "{0}" ({1})',
  '请填写 "{0}" 的定冠词': 'Fill in the definite article of "{0}"',
  '请填写 "{0}" 的第二格单数形式（Genitiv Singular）':
      'Fill in the genitive singular of "{0}" (Genitiv Singular)',
  '请填写 "{0}" 的复数形式（Plural）':
      'Fill in the plural form of "{0}" (Plural)',
  '请填写 "{0}" 的比较级与最高级':
      'Fill in the comparative and superlative of "{0}"',

  // ── 变位练习作答界面 ─────────────────────────────
  '没有题目': 'No questions',
  '请完整填写 {0} 的 6 个人称变位形态':
      'Fill in all 6 person forms of {0}',
  '提示：被动语态 = werden 的现在时变位 + 动词第二分词（Partizip II）':
      'Hint: passive = present-tense conjugation of werden + past participle (Partizip II)',
  '提示：比较级一般加 -er，最高级一般用 am ...-sten（注意变音与词尾变化）':
      'Hint: the comparative usually adds -er, the superlative usually uses am ...-sten (watch for umlauts and endings)',
  '定冠词': 'Definite article',
  '比较级': 'Comparative',
  '最高级': 'Superlative',
  '未填写': 'Not filled in',
  '正确: {0}': 'Correct: {0}',
  '请输入...': 'Enter...',
  '请输入 {0}...': 'Enter {0}...',
  '全部正确！': 'All correct!',
  '有 {0} 处错误': '{0} mistake(s)',
  '正确 {0} / {1}': 'Correct {0} / {1}',
  '下一题': 'Next',
  '检查答案': 'Check answer',
  '练习完成': 'Practice complete',
  '练习完成！': 'Practice complete!',
  '完成题目': 'Questions completed',
  '{0} 道': '{0}',
  '全部正确': 'All correct',
  '正确率': 'Accuracy',

  // ── 变位数据管理界面 ─────────────────────────────
  'AI 更新变位数据': 'AI update conjugation data',
  '确定要使用 AI 重新生成选中的 {0} 个单词的变位数据吗？\n\n将覆盖已有的变位数据，未配置过变位数据的单词将自动补全。':
      'Regenerate conjugation data for the {0} selected words with AI?\n\nExisting conjugation data will be overwritten, and words without conjugation data will be filled in automatically.',
  '更新完成：成功 {0} 个，失败 {1} 个':
      'Update complete: {0} succeeded, {1} failed',
  '变位数据更新完成（{0} 个）': 'Conjugation data updated ({0})',
  '删除变位数据': 'Delete conjugation data',
  '确定要删除选中的 {0} 个单词的变位数据吗？\n\n删除后：动词时态练习将不再出现这些单词（可重新生成恢复）；\n名词变格 / 形容词变级将回退使用单词表中的基础字段。':
      'Delete conjugation data for the {0} selected words?\n\nAfter deletion: these words will no longer appear in verb tense practice (they can be restored by regenerating);\nnoun declension / adjective comparison will fall back to the basic fields in the word list.',
  '已删除 {0} 个单词的变位数据':
      'Deleted conjugation data for {0} words',
  '已保存 {0} 的变位数据': 'Saved conjugation data for {0}',
  '已选择 {0} 项': '{0} selected',
  '退出多选': 'Exit multi-select',
  '全选': 'Select all',
  '筛选词性': 'Filter by part of speech',
  '全部词性': 'All parts of speech',
  '动词': 'Verb',
  '名词': 'Noun',
  '形容词': 'Adjective',
  '多选': 'Multi-select',
  '词书中没有可管理的单词':
      'There are no words available to manage in the deck',
  '删除选中': 'Delete selected',
  'AI 更新选中': 'AI update selected',
  '已缓存 · {0} · 更新于 {1}': 'Cached · {0} · updated {1}',
  '无变位数据': 'No conjugation data',
  '编辑变位数据': 'Edit conjugation data',
  'AI 更新变位数据 {0} 个单词':
      'AI update conjugation data ({0} words)',
  '更新完成': 'Update complete',
  'JSON 格式无效，无法格式化': 'Invalid JSON format, cannot format',
  '变位数据不能为空': 'Conjugation data cannot be empty',
  'JSON 格式无效：{0}': 'Invalid JSON format: {0}',
  '变位数据必须是 JSON 对象（{...}）':
      'Conjugation data must be a JSON object ({...})',
  '保存失败：{0}': 'Save failed: {0}',
  '编辑变位数据 - {0}': 'Edit conjugation data - {0}',
  '词性：{0} · 结构参考：{1}': 'Part of speech: {0} · structure reference: {1}',
  '6人称': '6 persons',
  '该单词暂无变位数据，保存后将新建并标记为手动':
      'This word has no conjugation data yet; saving will create it and mark it as manual',
};

const Map<String, String> conjugationDe = <String, String>{
  // ── 通用按钮 / 标签 ──────────────────────────────
  '取消': 'Abbrechen',
  '确定': 'OK',
  '完成': 'Fertig',
  '保存': 'Speichern',
  '删除': 'Löschen',
  '返回': 'Zurück',
  '后台运行': 'Im Hintergrund ausführen',
  '格式化': 'Formatieren',
  '自定义': 'Benutzerdefiniert',
  '手动': 'Manuell',

  // ── 变位练习主界面 ───────────────────────────────
  '变位练习': 'Konjugationsübung',
  '请先选择一个词书': 'Bitte zuerst ein Deck auswählen',
  '当前词书': 'Aktuelles Deck',
  '练习参数': 'Übungseinstellungen',
  '单次练习词量': 'Wörter pro Übung',
  '{0} 个': '{0}',
  '当前: {0} 个': 'Aktuell: {0}',
  '练习范围': 'Übungsbereich',
  '随机练习': 'Zufällige Übung',
  '只练今日单词': 'Nur heutige Wörter',
  '仅从今天学习过的单词中抽取':
      'Nur aus heute gelernten Wörtern auswählen',
  '从整个词书随机抽取': 'Zufällig aus dem gesamten Deck auswählen',
  '选择练习类型': 'Übungstyp auswählen',
  '动词变位': 'Verbkonjugation',
  '名词变格': 'Nomendeklination',
  '形容词变级': 'Adjektivsteigerung',
  'Adjektiv Steigerung · 比较级 & 最高级':
      'Adjektiv Steigerung · Komparativ & Superlativ',
  '变位数据管理': 'Konjugationsdaten verwalten',
  '管理变位数据': 'Konjugationsdaten verwalten',
  '查看各单词变位数据状态，可多选更新 / 删除':
      'Konjugationsdaten-Status jedes Wortes anzeigen; Aktualisieren/Löschen für mehrere Wörter',
  'AI 批量生成变位数据':
      'Konjugationsdaten per KI im Stapel erzeugen',
  '使用 AI 分析词书中的词汇，生成变位数据并缓存到本地':
      'KI analysiert die Wörter des Decks, erzeugt Konjugationsdaten und speichert sie lokal zwischen',
  '请先在设置中配置 AI API Key':
      'Bitte zuerst den KI-API-Schlüssel in den Einstellungen konfigurieren',
  '今日还没有学习过的单词，请先在学习模式中学习':
      'Heute wurden noch keine Wörter gelernt. Bitte zuerst im Lernmodus lernen',
  '，请先在下方"变位数据管理"中生成变位数据':
      ', bitte zuerst unten in „Konjugationsdaten verwalten" Konjugationsdaten erzeugen',
  '词书中没有可练习的{0}数据{1}':
      'Im Deck sind keine Übungsdaten für {0} verfügbar{1}',
  '错误: {0}': 'Fehler: {0}',

  // ── 自定义词量对话框 ─────────────────────────────
  '自定义单次练习词量': 'Wörter pro Übung anpassen',
  '单词数量': 'Wörteranzahl',
  '请输入正整数': 'Positive Ganzzahl eingeben',
  '请输入有效的正整数': 'Bitte eine gültige positive Ganzzahl eingeben',

  // ── 进度对话框 ───────────────────────────────────
  'AI 生成变位数据（{0} 个单词）':
      'KI erzeugt Konjugationsdaten ({0} Wörter)',
  '无需生成': 'Nichts zu erzeugen',
  '生成完成': 'Erzeugung abgeschlossen',
  'AI 生成变位数据': 'Konjugationsdaten per KI erzeugen',
  '{0} 个单词需要生成': '{0} Wörter müssen erzeugt werden',
  '正在处理: {0}': 'Verarbeite: {0}',
  '关闭窗口可后台运行':
      'Fenster schließen, um im Hintergrund weiterzulaufen',
  '所有单词已有变位数据': 'Alle Wörter besitzen bereits Konjugationsdaten',
  '成功 {0} 个': 'Erfolgreich: {0}',
  '，失败 {0} 个': ', fehlgeschlagen: {0}',

  // ── 练习模式标题 / 题干 ──────────────────────────
  '现在时': 'Präsens',
  '过去时': 'Präteritum',
  '现在完成时': 'Perfekt',
  '被动语态': 'Passiv',
  '定冠词/性属': 'Bestimmter Artikel/Genus',
  '第二格单数': 'Genitiv Singular',
  '复数形式': 'Pluralform',
  '变级练习': 'Steigerungsübung',
  '请填写 "{0}" 的{1}全部人称变位':
      'Bitte alle Personalformen von "{0}" ({1}) ausfüllen',
  '请填写 "{0}" 的定冠词':
      'Bitte den bestimmten Artikel von "{0}" ausfüllen',
  '请填写 "{0}" 的第二格单数形式（Genitiv Singular）':
      'Bitte den Genitiv Singular von "{0}" ausfüllen (Genitiv Singular)',
  '请填写 "{0}" 的复数形式（Plural）':
      'Bitte die Pluralform von "{0}" ausfüllen (Plural)',
  '请填写 "{0}" 的比较级与最高级':
      'Bitte Komparativ und Superlativ von "{0}" ausfüllen',

  // ── 变位练习作答界面 ─────────────────────────────
  '没有题目': 'Keine Fragen',
  '请完整填写 {0} 的 6 个人称变位形态':
      'Bitte alle 6 Personalformen für {0} ausfüllen',
  '提示：被动语态 = werden 的现在时变位 + 动词第二分词（Partizip II）':
      'Hinweis: Passiv = Präsens-Konjugation von werden + Partizip II',
  '提示：比较级一般加 -er，最高级一般用 am ...-sten（注意变音与词尾变化）':
      'Hinweis: Komparativ meist mit -er, Superlativ meist mit am ...-sten (Umlaut und Endungen beachten)',
  '定冠词': 'Bestimmter Artikel',
  '比较级': 'Komparativ',
  '最高级': 'Superlativ',
  '未填写': 'Nicht ausgefüllt',
  '正确: {0}': 'Richtig: {0}',
  '请输入...': 'Eingeben...',
  '请输入 {0}...': '{0} eingeben...',
  '全部正确！': 'Alles richtig!',
  '有 {0} 处错误': '{0} Fehler',
  '正确 {0} / {1}': 'Richtig {0} / {1}',
  '下一题': 'Weiter',
  '检查答案': 'Antwort prüfen',
  '练习完成': 'Übung abgeschlossen',
  '练习完成！': 'Übung abgeschlossen!',
  '完成题目': 'Beantwortete Fragen',
  '{0} 道': '{0}',
  '全部正确': 'Alles richtig',
  '正确率': 'Trefferquote',

  // ── 变位数据管理界面 ─────────────────────────────
  'AI 更新变位数据': 'Konjugationsdaten per KI aktualisieren',
  '确定要使用 AI 重新生成选中的 {0} 个单词的变位数据吗？\n\n将覆盖已有的变位数据，未配置过变位数据的单词将自动补全。':
      'Konjugationsdaten für die {0} ausgewählten Wörter per KI neu erzeugen?\n\nVorhandene Konjugationsdaten werden überschrieben; Wörter ohne Konjugationsdaten werden automatisch ergänzt.',
  '更新完成：成功 {0} 个，失败 {1} 个':
      'Aktualisierung abgeschlossen: {0} erfolgreich, {1} fehlgeschlagen',
  '变位数据更新完成（{0} 个）':
      'Konjugationsdaten aktualisiert ({0})',
  '删除变位数据': 'Konjugationsdaten löschen',
  '确定要删除选中的 {0} 个单词的变位数据吗？\n\n删除后：动词时态练习将不再出现这些单词（可重新生成恢复）；\n名词变格 / 形容词变级将回退使用单词表中的基础字段。':
      'Konjugationsdaten für die {0} ausgewählten Wörter löschen?\n\nNach dem Löschen: Diese Wörter erscheinen nicht mehr in der Verbzeiten-Übung (Wiederherstellung durch Neuerzeugen möglich);\nNomendeklination / Adjektivsteigerung greifen auf die Basisfelder der Wortliste zurück.',
  '已删除 {0} 个单词的变位数据':
      'Konjugationsdaten für {0} Wörter gelöscht',
  '已保存 {0} 的变位数据': 'Konjugationsdaten für {0} gespeichert',
  '已选择 {0} 项': '{0} ausgewählt',
  '退出多选': 'Mehrfachauswahl beenden',
  '全选': 'Alle auswählen',
  '筛选词性': 'Nach Wortart filtern',
  '全部词性': 'Alle Wortarten',
  '动词': 'Verb',
  '名词': 'Substantiv',
  '形容词': 'Adjektiv',
  '多选': 'Mehrfachauswahl',
  '词书中没有可管理的单词':
      'Im Deck sind keine Wörter zum Verwalten vorhanden',
  '删除选中': 'Auswahl löschen',
  'AI 更新选中': 'Auswahl per KI aktualisieren',
  '已缓存 · {0} · 更新于 {1}':
      'Zwischengespeichert · {0} · aktualisiert {1}',
  '无变位数据': 'Keine Konjugationsdaten',
  '编辑变位数据': 'Konjugationsdaten bearbeiten',
  'AI 更新变位数据 {0} 个单词':
      'Konjugationsdaten per KI aktualisieren ({0} Wörter)',
  '更新完成': 'Aktualisierung abgeschlossen',
  'JSON 格式无效，无法格式化':
      'Ungültiges JSON-Format, Formatierung nicht möglich',
  '变位数据不能为空': 'Konjugationsdaten dürfen nicht leer sein',
  'JSON 格式无效：{0}': 'Ungültiges JSON-Format: {0}',
  '变位数据必须是 JSON 对象（{...}）':
      'Konjugationsdaten müssen ein JSON-Objekt sein ({...})',
  '保存失败：{0}': 'Speichern fehlgeschlagen: {0}',
  '编辑变位数据 - {0}': 'Konjugationsdaten bearbeiten - {0}',
  '词性：{0} · 结构参考：{1}': 'Wortart: {0} · Strukturreferenz: {1}',
  '6人称': '6 Personen',
  '该单词暂无变位数据，保存后将新建并标记为手动':
      'Dieses Wort hat noch keine Konjugationsdaten; beim Speichern wird es neu angelegt und als manuell markiert',
};
