/// 查词界面相关文案——由本地化任务填充。
const Map<String, String> searchEn = <String, String>{
  // 标题 / 搜索栏
  '联网查词': 'Online Lookup',
  '输入德语单词...': 'Enter a German word...',
  '输入德语单词开始查词': 'Enter a German word to start searching',
  '加入词书': 'Add to Wordbook',

  // 释义区
  '释义': 'Definitions',
  '复数: {0}': 'Plural: {0}',
  '复数': 'Plural',
  '词性: {0}': 'Part of speech: {0}',
  '可分前缀: {0}': 'Separable prefix: {0}',
  '基础动词: {0}': 'Base verb: {0}',
  '例句': 'Examples',

  // 动词搭配
  '动词搭配': 'Verb Collocations',
  '三格': 'Dative',
  '四格': 'Accusative',
  '三格 (Dativ)': 'Dative (Dativ)',
  '四格 (Akkusativ)': 'Accusative (Akkusativ)',

  // 变格 / 变位
  '动词变位': 'Verb Conjugation',
  '名词变格': 'Noun Declension',
  '形容词变级': 'Adjective Comparison',
  '现在时': 'Present',
  '过去时': 'Past',
  '完成时': 'Perfect',
  '被动态': 'Passive',
  '第二格': 'Genitive',
  '比较级': 'Comparative',
  '最高级': 'Superlative',

  // AI 解析
  'AI 深度解析': 'AI In-depth Analysis',

  // 查词后自动加入词书
  '查词后自动加入词书': 'Auto-add to wordbook after lookup',
  '自动加入：{0}': 'Auto-add: {0}',
  '自动加入：请选择词书': 'Auto-add: select a wordbook',
  '可点击右上角任务按钮查看进度，任务完成后自动加入词书':
      'Tap the task button in the top-right to view progress; the word will be added to the wordbook when done',
  '请先设置自动加入的词书': 'Please set a wordbook for auto-add first',
  '目标词书不存在，请重新选择':
      'Target wordbook no longer exists, please choose again',
  'AI 引擎未就绪，请检查设置': 'AI engine not ready, please check settings',
  '查词入库: {0}': 'Lookup & add: {0}',
  '「{0}」已加入后台查询队列，完成后自动加入词书':
      '"{0}" was added to the background lookup queue and will be added to the wordbook when done',
  '开启后查词不再等待，自动挂到后台任务，完成后加入所选词书，可继续查下一个单词':
      'When enabled, lookups no longer wait: they run as background tasks and are added to the selected wordbook when done, so you can keep looking up the next word',

  // 词书选择 / 新建
  '选择词书': 'Select Wordbook',
  '当前目标': 'Current target',
  '新建词书': 'New Wordbook',
  '词书名称': 'Wordbook name',
  '例如：生词本': 'e.g. Vocabulary',
  '还没有词书，请先创建一个': 'No wordbooks yet. Please create one first',
  '创建并添加': 'Create & Add',
  '创建中...': 'Creating...',
  '把「{0}」加入词书': 'Add "{0}" to a wordbook',
  '请填写词书名称': 'Please enter a wordbook name',
  '创建词书失败: {0}': 'Failed to create wordbook: {0}',
  '创建': 'Create',
  '取消': 'Cancel',

  // 提示 / 错误
  '已添加到词书': 'Added to wordbook',
  '数据库未就绪': 'Database not ready',
  '该单词已存在，未重复添加':
      'This word already exists; not added again',
  '该单词已存在于词书「{0}」，未重复添加':
      'This word already exists in wordbook "{0}"; not added again',
  '错误: {0}': 'Error: {0}',
};

const Map<String, String> searchDe = <String, String>{
  // 标题 / 搜索栏
  '联网查词': 'Online-Suche',
  '输入德语单词...': 'Deutsches Wort eingeben...',
  '输入德语单词开始查词':
      'Deutsches Wort eingeben, um die Suche zu starten',
  '加入词书': 'Zur Wortliste hinzufügen',

  // 释义区
  '释义': 'Bedeutungen',
  '复数: {0}': 'Plural: {0}',
  '复数': 'Plural',
  '词性: {0}': 'Wortart: {0}',
  '可分前缀: {0}': 'Trennbares Präfix: {0}',
  '基础动词: {0}': 'Grundverb: {0}',
  '例句': 'Beispiele',

  // 动词搭配
  '动词搭配': 'Verb-Kollokationen',
  '三格': 'Dativ',
  '四格': 'Akkusativ',
  '三格 (Dativ)': 'Dativ',
  '四格 (Akkusativ)': 'Akkusativ',

  // 变格 / 变位
  '动词变位': 'Verbkonjugation',
  '名词变格': 'Substantivdeklination',
  '形容词变级': 'Adjektivsteigerung',
  '现在时': 'Präsens',
  '过去时': 'Präteritum',
  '完成时': 'Perfekt',
  '被动态': 'Passiv',
  '第二格': 'Genitiv',
  '比较级': 'Komparativ',
  '最高级': 'Superlativ',

  // AI 解析
  'AI 深度解析': 'KI-Tiefenanalyse',

  // 查词后自动加入词书
  '查词后自动加入词书': 'Nach der Suche automatisch zur Wortliste hinzufügen',
  '自动加入：{0}': 'Auto-Hinzufügen: {0}',
  '自动加入：请选择词书': 'Auto-Hinzufügen: Wortliste auswählen',
  '可点击右上角任务按钮查看进度，任务完成后自动加入词书':
      'Tippe oben rechts auf den Aufgaben-Button, um den Fortschritt zu sehen; nach Abschluss wird das Wort automatisch zur Wortliste hinzugefügt',
  '请先设置自动加入的词书':
      'Bitte zuerst eine Wortliste für das automatische Hinzufügen festlegen',
  '目标词书不存在，请重新选择':
      'Ziel-Wortliste existiert nicht mehr, bitte erneut auswählen',
  'AI 引擎未就绪，请检查设置': 'KI-Engine nicht bereit, bitte Einstellungen prüfen',
  '查词入库: {0}': 'Suche & Hinzufügen: {0}',
  '「{0}」已加入后台查询队列，完成后自动加入词书':
      '„{0}“ wurde zur Hintergrund-Suchwarteschlange hinzugefügt und nach Abschluss automatisch zur Wortliste hinzugefügt',
  '开启后查词不再等待，自动挂到后台任务，完成后加入所选词书，可继续查下一个单词':
      'Wenn aktiviert, wartet die Suche nicht mehr: Sie läuft als Hintergrundaufgabe und wird nach Abschluss zur ausgewählten Wortliste hinzugefügt, sodass du sofort das nächste Wort suchen kannst',

  // 词书选择 / 新建
  '选择词书': 'Wortliste auswählen',
  '当前目标': 'Aktuelles Ziel',
  '新建词书': 'Neue Wortliste',
  '词书名称': 'Name der Wortliste',
  '例如：生词本': 'z. B. Vokabelliste',
  '还没有词书，请先创建一个':
      'Noch keine Wortlisten vorhanden. Bitte zuerst eine erstellen',
  '创建并添加': 'Erstellen & Hinzufügen',
  '创建中...': 'Wird erstellt...',
  '把「{0}」加入词书': '„{0}“ zu einer Wortliste hinzufügen',
  '请填写词书名称': 'Bitte einen Namen für die Wortliste eingeben',
  '创建词书失败: {0}': 'Wortliste konnte nicht erstellt werden: {0}',
  '创建': 'Erstellen',
  '取消': 'Abbrechen',

  // 提示 / 错误
  '已添加到词书': 'Zur Wortliste hinzugefügt',
  '数据库未就绪': 'Datenbank nicht bereit',
  '该单词已存在，未重复添加':
      'Dieses Wort ist bereits vorhanden; nicht erneut hinzugefügt',
  '该单词已存在于词书「{0}」，未重复添加':
      'Dieses Wort ist bereits in der Wortliste „{0}“ vorhanden; nicht erneut hinzugefügt',
  '错误: {0}': 'Fehler: {0}',
};
