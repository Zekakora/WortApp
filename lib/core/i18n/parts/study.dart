/// 学习模式相关文案——由本地化任务填充。
const Map<String, String> studyEn = <String, String>{
  // 学习模式选择 / 参数
  '选择学习模式': 'Choose study mode',
  '请先选择一个词书': 'Please select a wordbook first',
  '在主页切换词书，或在词书管理中创建':
      'Switch wordbook on the home page, or create one in wordbook management',
  '当前词书': 'Current wordbook',
  '练习参数': 'Practice settings',
  '每轮单词数': 'Words per round',
  '{0} 个': '{0}',
  '自定义': 'Custom',
  '当前: {0} 个': 'Current: {0}',
  '新词与复习受每日上限约束；每次学习发放一批（每轮单词数），分批覆盖今天全部单词，覆盖完毕后自动开启下一大轮，轮数无上限':
      'New words and reviews are limited by the daily caps. Once the caps are used up, loop review begins: each session hands out a batch (words per round), covering all of today\'s words in batches, and after full coverage the next big round starts automatically with no limit on the number of rounds.',
  '抓词模式': 'Word selection mode',
  '正常抓词': 'Normal',
  '收藏优先': 'Favorites first',
  '只抓收藏': 'Favorites only',
  '今日错词': 'Today\'s mistakes',
  '今天该学的单词中，收藏词汇优先出现、被抓中概率更高':
      'Among today\'s study words, favorites appear first and are more likely to be selected',
  '只练习今天该学单词中已收藏的词汇':
      'Practice only favorited words among today\'s study words',
  '只练习今天答错过（忘记/模糊）的词；答错会重新复习，连续 3 轮答对才移出':
      'Practice only words answered incorrectly today (Forgot/Hard); wrong answers are reviewed again and only removed after 3 correct rounds in a row',
  '按每日新词/复习上限正常抓取':
      'Select normally according to the daily new-word/review caps',
  '只复习': 'Review only',
  '开启：不抽新词，只复习到期词与今日已学单词':
      'On: no new words, review only due words and words learned today',
  '关闭：按每日上限正常抽取新词与复习词':
      'Off: select new words and review words normally according to the daily caps',
  '随机背词': 'Shuffle words',
  '开启：抽词打乱顺序，不按单词本顺序抽取':
      'On: words are drawn in shuffled order, not in wordbook order',
  '关闭：按单词本顺序依次抽取':
      'Off: words are drawn in wordbook order',
  // 学习模式卡片
  '快闪卡模式': 'Flash card mode',
  '全屏卡片，限时回忆，滑动评分':
      'Full-screen cards, timed recall, swipe to rate',
  '经典翻牌模式': 'Classic flip mode',
  '正面德语，背面释义，手动评分':
      'German on the front, meaning on the back, manual rating',
  '看德语选中文': 'German to Chinese',
  '显示德语单词，选择正确中文释义':
      'Show a German word and choose the correct Chinese meaning',
  '看中文选德语': 'Chinese to German',
  '显示中文释义，选择正确德语单词':
      'Show a Chinese meaning and choose the correct German word',
  '听德语选单词': 'Listen and choose',
  '播放 TTS 发音，选择对应单词': 'Play TTS audio and choose the matching word',
  '德语拼写模式': 'German spelling',
  '输入德语单词拼写，支持特殊字符':
      'Type the German spelling, special characters supported',
  // 自定义每轮单词数对话框
  '自定义每轮单词数': 'Custom words per round',
  '单词数量': 'Word count',
  '请输入正整数': 'Enter a positive integer',
  '取消': 'Cancel',
  '确定': 'OK',
  '请输入有效的正整数': 'Please enter a valid positive integer',
  '错误: {0}': 'Error: {0}',
  '没有待学习的单词，请先导入词书':
      'No words to study. Please import a wordbook first',
  // 错误统计排行榜
  '错误统计排行榜': 'Error statistics ranking',
  '今日/历史的错误次数与错误率':
      'Error counts and error rates for today/history',
  '错误统计': 'Error statistics',
  '今天': 'Today',
  '历史': 'History',
  '错误次数': 'Errors',
  '错误率': 'Error rate',
  '每次练习记录出现与错误次数，忘记/模糊计为错误':
      'Each practice logs occurrences and errors; Forgot/Hard count as errors',
  '今天还没有练习记录': 'No practice records today yet',
  '暂无历史统计记录': 'No history statistics yet',
  '错误 {0} 次': '{0} errors',
  '错误率 {0}%': '{0}% error rate',
  '出现 {0} 次': '{0} occurrences',
  '收藏': 'Favorite',
  '取消收藏': 'Unfavorite',
  // 选择/听/拼写模式通用提示
  '词性选择错误，请重试': 'Wrong part of speech, please try again',
  '请先选择正确的词性': 'Please select the correct part of speech first',
  '看德语选中文 ({0})': 'German to Chinese ({0})',
  '看中文选德语 ({0})': 'Chinese to German ({0})',
  '听德语选单词 ({0})': 'Listen and choose ({0})',
  '没有单词': 'No words',
  '确认答案': 'Confirm answer',
  '查看单词详情': 'View word details',
  '忘记': 'Forgot',
  '模糊': 'Hard',
  '熟悉': 'Good',
  '简单': 'Easy',
  // 学习完成
  '学习完成': 'Study complete',
  '恭喜完成！': 'Congratulations!',
  '本次学习 {0} 个单词': 'Studied {0} words this session',
  '正确率: {0}%': 'Accuracy: {0}%',
  '返回': 'Back',
  // 翻牌模式
  '翻牌模式': 'Flip mode',
  '没有待学习的单词': 'No words to study',
  '翻牌模式 ({0})': 'Flip mode ({0})',
  '请选择定冠词': 'Select the article',
  '点击显示答案': 'Tap to show the answer',
  '中文释义': 'Chinese meaning',
  '例句': 'Example sentence',
  '复数: {0}': 'Plural: {0}',
  '请先选择正确的定冠词': 'Please select the correct article first',
  '冠词选择错误，请重试': 'Wrong article, please try again',
  // 快闪卡模式
  '快闪卡模式 ({0})': 'Flash card mode ({0})',
  '右划 = 模糊 · 左划 = 忘记 · 上滑 = 详情':
      'Swipe right = Hard · Swipe left = Forgot · Swipe up = Details',
  '右划 = 熟练 · 左划 = 忘记 · 上滑 = 详情':
      'Swipe right = Easy · Swipe left = Forgot · Swipe up = Details',
  // 听德语选单词
  '点击播放发音': 'Tap to play audio',
  // 拼写模式
  '拼写模式': 'Spelling mode',
  '拼写模式 ({0})': 'Spelling mode ({0})',
  '输入德语单词...': 'Type the German word...',
  '正确答案: {0}': 'Correct answer: {0}',
  '支持宽容拼写: ae→ä, oe→ö, ue→ü, ss→ß':
      'Lenient spelling: ae→ä, oe→ö, ue→ü, ss→ß',
  '检查拼写': 'Check spelling',
  '名词首字母需要大写': 'Nouns must be capitalized',
  // 评分说明
  '评分说明': 'Rating guide',
  '评分决定这个词下次什么时候再出现。如实评分最有利于长期记忆——为了心软给高分，词会很快消失、又很快忘。':
      'Your rating decides when this word appears again. Rating honestly is best for long-term memory—giving high scores out of pity makes words disappear quickly and be forgotten just as fast.',
  '四个按钮': 'The four buttons',
  '完全想不起来 / 答错 → 明天再复习，重复进度清零':
      'Cannot recall at all / answered wrong → review again tomorrow, repetition progress resets',
  '有印象但没答对或答不全 → 明天再复习，进度保留、难度略升':
      'Some impression but answered wrong or incompletely → review again tomorrow, progress kept, difficulty slightly raised',
  '答对了，稍有停顿 → 按正常节奏延长复习间隔':
      'Answered correctly with slight hesitation → extend the review interval at the normal pace',
  '秒答、毫不费力 → 间隔延长更多（要少用）':
      'Instant, effortless answer → interval extended more (use sparingly)',
  '常见情况怎么选': 'How to choose',
  '靠排除法或运气猜对 → 选「模糊」，不要给熟悉/简单':
      'Guessed right by elimination or luck → choose “Hard”, not Good/Easy',
  '拼写错但能认出、听音听不出 → 选「模糊」':
      'Misspelled but recognizable, or cannot recognize by sound → choose “Hard”',
  '知道词义，但忘了冠词/词性（der·die·das）/复数/变位 → 选「模糊」':
      'Know the meaning but forgot the article/part of speech (der·die·das)/plural/conjugation → choose “Hard”',
  '基本都答对，只是略慢 → 选「熟悉」':
      'Mostly correct, just a bit slow → choose “Good”',
  '一眼就会、毫不费力 → 选「简单」':
      'Obvious at a glance, effortless → choose “Easy”',
  '小贴士：德语名词建议把冠词一起记牢再给「熟悉」；答错（忘记/模糊）会进入错词重考并计入错误统计。':
      'Tip: for German nouns, memorize the article together before rating “Good”; wrong answers (Forgot/Hard) enter wrong-word re-testing and count toward error statistics.',
  '知道了': 'Got it',
  // 变格卡片
  '助动词: {0}': 'Auxiliary verb: {0}',
};

const Map<String, String> studyDe = <String, String>{
  // 学习模式选择 / 参数
  '选择学习模式': 'Lernmodus wählen',
  '请先选择一个词书': 'Bitte zuerst eine Wortliste wählen',
  '在主页切换词书，或在词书管理中创建':
      'Wortliste auf der Startseite wechseln oder in der Wortlistenverwaltung erstellen',
  '当前词书': 'Aktuelle Wortliste',
  '练习参数': 'Übungseinstellungen',
  '每轮单词数': 'Wörter pro Runde',
  '{0} 个': '{0}',
  '自定义': 'Benutzerdefiniert',
  '当前: {0} 个': 'Aktuell: {0}',
  '新词与复习受每日上限约束；每次学习发放一批（每轮单词数），分批覆盖今天全部单词，覆盖完毕后自动开启下一大轮，轮数无上限':
      'Neue Wörter und Wiederholungen sind durch die Tageslimits begrenzt. Sind die Limits aufgebraucht, beginnt die Schleifenwiederholung: Jede Lerneinheit gibt einen Stapel aus (Wörter pro Runde), die alle heutigen Wörter in Stapeln abdeckt, und nach vollständiger Abdeckung startet automatisch die nächste große Runde – die Rundenzahl ist unbegrenzt.',
  '抓词模式': 'Wortauswahlmodus',
  '正常抓词': 'Normal',
  '收藏优先': 'Favoriten zuerst',
  '只抓收藏': 'Nur Favoriten',
  '今日错词': 'Heutige Fehler',
  '今天该学的单词中，收藏词汇优先出现、被抓中概率更高':
      'Unter den heutigen Lernwörtern erscheinen Favoriten zuerst und werden wahrscheinlicher ausgewählt',
  '只练习今天该学单词中已收藏的词汇':
      'Nur favorisierte Wörter unter den heutigen Lernwörtern üben',
  '只练习今天答错过（忘记/模糊）的词；答错会重新复习，连续 3 轮答对才移出':
      'Nur heute falsch beantwortete Wörter üben (Vergessen/Schwierig); falsche Antworten werden erneut wiederholt und erst nach 3 richtigen Runden in Folge entfernt',
  '按每日新词/复习上限正常抓取':
      'Normal gemäß den Tageslimits für neue Wörter/Wiederholungen auswählen',
  '只复习': 'Nur wiederholen',
  '开启：不抽新词，只复习到期词与今日已学单词':
      'An: keine neuen Wörter, nur fällige und heute gelernte Wörter wiederholen',
  '关闭：按每日上限正常抽取新词与复习词':
      'Aus: neue Wörter und Wiederholungswörter normal gemäß den Tageslimits auswählen',
  '随机背词': 'Wörter mischen',
  '开启：抽词打乱顺序，不按单词本顺序抽取':
      'An: Wörter werden in gemischter Reihenfolge gezogen, nicht in Wortlistenreihenfolge',
  '关闭：按单词本顺序依次抽取':
      'Aus: Wörter werden in Wortlistenreihenfolge gezogen',
  // 学习模式卡片
  '快闪卡模式': 'Karteikartenmodus',
  '全屏卡片，限时回忆，滑动评分':
      'Vollbildkarten, zeitlich begrenztes Erinnern, Bewertung per Wischen',
  '经典翻牌模式': 'Klassischer Umdrehmodus',
  '正面德语，背面释义，手动评分':
      'Deutsch auf der Vorderseite, Bedeutung auf der Rückseite, manuelle Bewertung',
  '看德语选中文': 'Deutsch zu Chinesisch',
  '显示德语单词，选择正确中文释义':
      'Deutsches Wort anzeigen und die richtige chinesische Bedeutung wählen',
  '看中文选德语': 'Chinesisch zu Deutsch',
  '显示中文释义，选择正确德语单词':
      'Chinesische Bedeutung anzeigen und das richtige deutsche Wort wählen',
  '听德语选单词': 'Hören und wählen',
  '播放 TTS 发音，选择对应单词':
      'TTS-Audio abspielen und das passende Wort wählen',
  '德语拼写模式': 'Deutsche Rechtschreibung',
  '输入德语单词拼写，支持特殊字符':
      'Deutsche Schreibweise eingeben, Sonderzeichen unterstützt',
  // 自定义每轮单词数对话框
  '自定义每轮单词数': 'Benutzerdefinierte Wörter pro Runde',
  '单词数量': 'Wortanzahl',
  '请输入正整数': 'Bitte eine positive ganze Zahl eingeben',
  '取消': 'Abbrechen',
  '确定': 'OK',
  '请输入有效的正整数': 'Bitte eine gültige positive ganze Zahl eingeben',
  '错误: {0}': 'Fehler: {0}',
  '没有待学习的单词，请先导入词书':
      'Keine Wörter zum Lernen. Bitte zuerst eine Wortliste importieren',
  // 错误统计排行榜
  '错误统计排行榜': 'Fehlerstatistik-Rangliste',
  '今日/历史的错误次数与错误率':
      'Fehleranzahl und Fehlerquote für heute/Verlauf',
  '错误统计': 'Fehlerstatistik',
  '今天': 'Heute',
  '历史': 'Verlauf',
  '错误次数': 'Fehler',
  '错误率': 'Fehlerquote',
  '每次练习记录出现与错误次数，忘记/模糊计为错误':
      'Jede Übung erfasst Vorkommen und Fehler; Vergessen/Schwierig zählen als Fehler',
  '今天还没有练习记录': 'Heute noch keine Übungsaufzeichnungen',
  '暂无历史统计记录': 'Noch keine Verlaufsstatistik',
  '错误 {0} 次': '{0} Fehler',
  '错误率 {0}%': '{0} % Fehlerquote',
  '出现 {0} 次': '{0} Vorkommen',
  '收藏': 'Favorit',
  '取消收藏': 'Aus Favoriten entfernen',
  // 选择/听/拼写模式通用提示
  '词性选择错误，请重试': 'Falsche Wortart, bitte erneut versuchen',
  '请先选择正确的词性': 'Bitte zuerst die richtige Wortart wählen',
  '看德语选中文 ({0})': 'Deutsch zu Chinesisch ({0})',
  '看中文选德语 ({0})': 'Chinesisch zu Deutsch ({0})',
  '听德语选单词 ({0})': 'Hören und wählen ({0})',
  '没有单词': 'Keine Wörter',
  '确认答案': 'Antwort bestätigen',
  '查看单词详情': 'Wortdetails anzeigen',
  '忘记': 'Vergessen',
  '模糊': 'Schwierig',
  '熟悉': 'Gut',
  '简单': 'Einfach',
  // 学习完成
  '学习完成': 'Lernen abgeschlossen',
  '恭喜完成！': 'Herzlichen Glückwunsch!',
  '本次学习 {0} 个单词': 'In dieser Einheit {0} Wörter gelernt',
  '正确率: {0}%': 'Trefferquote: {0} %',
  '返回': 'Zurück',
  // 翻牌模式
  '翻牌模式': 'Umdrehmodus',
  '没有待学习的单词': 'Keine Wörter zum Lernen',
  '翻牌模式 ({0})': 'Umdrehmodus ({0})',
  '请选择定冠词': 'Artikel wählen',
  '点击显示答案': 'Zum Anzeigen der Antwort tippen',
  '中文释义': 'Chinesische Bedeutung',
  '例句': 'Beispielsatz',
  '复数: {0}': 'Plural: {0}',
  '请先选择正确的定冠词': 'Bitte zuerst den richtigen Artikel wählen',
  '冠词选择错误，请重试': 'Falscher Artikel, bitte erneut versuchen',
  // 快闪卡模式
  '快闪卡模式 ({0})': 'Karteikartenmodus ({0})',
  '右划 = 模糊 · 左划 = 忘记 · 上滑 = 详情':
      'Rechts wischen = Schwierig · Links wischen = Vergessen · Nach oben wischen = Details',
  '右划 = 熟练 · 左划 = 忘记 · 上滑 = 详情':
      'Rechts wischen = Einfach · Links wischen = Vergessen · Nach oben wischen = Details',
  // 听德语选单词
  '点击播放发音': 'Zum Abspielen tippen',
  // 拼写模式
  '拼写模式': 'Rechtschreibmodus',
  '拼写模式 ({0})': 'Rechtschreibmodus ({0})',
  '输入德语单词...': 'Deutsches Wort eingeben...',
  '正确答案: {0}': 'Richtige Antwort: {0}',
  '支持宽容拼写: ae→ä, oe→ö, ue→ü, ss→ß':
      'Tolerante Schreibweise: ae→ä, oe→ö, ue→ü, ss→ß',
  '检查拼写': 'Rechtschreibung prüfen',
  '名词首字母需要大写': 'Substantive müssen großgeschrieben werden',
  // 评分说明
  '评分说明': 'Bewertungshilfe',
  '评分决定这个词下次什么时候再出现。如实评分最有利于长期记忆——为了心软给高分，词会很快消失、又很快忘。':
      'Ihre Bewertung entscheidet, wann dieses Wort wieder erscheint. Ehrliches Bewerten ist am besten für das Langzeitgedächtnis – aus Mitleid hohe Bewertungen zu vergeben, lässt Wörter schnell verschwinden und ebenso schnell wieder vergessen werden.',
  '四个按钮': 'Die vier Schaltflächen',
  '完全想不起来 / 答错 → 明天再复习，重复进度清零':
      'Überhaupt keine Erinnerung / falsch beantwortet → morgen erneut wiederholen, Wiederholungsfortschritt wird zurückgesetzt',
  '有印象但没答对或答不全 → 明天再复习，进度保留、难度略升':
      'Eine Ahnung, aber falsch oder unvollständig beantwortet → morgen erneut wiederholen, Fortschritt bleibt erhalten, Schwierigkeit leicht erhöht',
  '答对了，稍有停顿 → 按正常节奏延长复习间隔':
      'Richtig beantwortet mit kurzem Zögern → das Wiederholungsintervall im normalen Tempo verlängern',
  '秒答、毫不费力 → 间隔延长更多（要少用）':
      'Sofortige, mühelose Antwort → Intervall wird stärker verlängert (selten verwenden)',
  '常见情况怎么选': 'So wählen Sie',
  '靠排除法或运气猜对 → 选「模糊」，不要给熟悉/简单':
      'Durch Ausschluss oder Glück richtig geraten → „Schwierig“ wählen, nicht Gut/Einfach',
  '拼写错但能认出、听音听不出 → 选「模糊」':
      'Falsch geschrieben, aber erkennbar, oder akustisch nicht erkennbar → „Schwierig“ wählen',
  '知道词义，但忘了冠词/词性（der·die·das）/复数/变位 → 选「模糊」':
      'Bedeutung bekannt, aber Artikel/Wortart (der·die·das)/Plural/Konjugation vergessen → „Schwierig“ wählen',
  '基本都答对，只是略慢 → 选「熟悉」':
      'Meistens richtig, nur etwas langsam → „Gut“ wählen',
  '一眼就会、毫不费力 → 选「简单」':
      'Auf Anhieb klar, mühelos → „Einfach“ wählen',
  '小贴士：德语名词建议把冠词一起记牢再给「熟悉」；答错（忘记/模糊）会进入错词重考并计入错误统计。':
      'Tipp: Bei deutschen Substantiven den Artikel mitlernen, bevor Sie „Gut“ bewerten; falsche Antworten (Vergessen/Schwierig) kommen in die Fehlerwort-Nachprüfung und zählen zur Fehlerstatistik.',
  '知道了': 'Verstanden',
  // 变格卡片
  '助动词: {0}': 'Hilfsverb: {0}',
};
