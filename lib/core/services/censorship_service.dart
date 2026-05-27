class CensorshipService {
  // Russian swearing regex patterns (matching a full word)
  static final List<RegExp> _russianSwearRegexes = [
    // хуй / хуя / хуе... with prefixes like нахуй, похуй, охуеть, схуяли
    RegExp(
      r'^(?:на|по|за|при|о|а|с|ни|до|в|про|от)?[хx][уyу][ййяеиёюу]\w*',
      caseSensitive: false,
    ),
    // пизд... with prefixes like спиздить, распиздеться
    RegExp(
      r'^(?:с|рас|вы|за|об|при|под|о)?[пp][ииееооаа][зз][дд]\w*',
      caseSensitive: false,
    ),
    // бля... / блять / блядь / выблядок
    RegExp(
      r'^(?:вы)?[бб][лл][яя][ддттьь]\w*',
      caseSensitive: false,
    ),
    // еб... / ёб...
    RegExp(r'^[её][бб]\w*', caseSensitive: false),
    // еб... / ёб... with prefixes (avoiding колебать, потреблять, стебель)
    RegExp(
      r'^(?:за|на|вы|пере|у|раз[ъь]?|под[ъь]?|при|от[ъь]?|о|об[ъь]?|до|по|со|долбо|мозго|руко|хуе)[её][бб]\w*',
      caseSensitive: false,
    ),
    // муд... (matches мудак, мудила, мудохаться, but not мудрый/мудрость)
    RegExp(r'^муд[аиеё]\w*', caseSensitive: false),
    // гандон / гондон
    RegExp(r'^г[оа]нд[оа]н\w*', caseSensitive: false),
    // пидор / педрила
    RegExp(r'^(?:с|о)?п[ие]д[оа]р\w*', caseSensitive: false),
    // шлюх...
    RegExp(r'^шлюх\w*', caseSensitive: false),
    // сука / сучка
    RegExp(r'^сук[аиоуе]\w*', caseSensitive: false),
    // говно / гавно
    RegExp(r'^(?:за|об|раз)?г[оа]вн[оауе]\w*', caseSensitive: false),
    // дроч...
    RegExp(r'^дроч\w*', caseSensitive: false),
  ];

  // English swearing regex patterns (matching a full word)
  static final List<RegExp> _englishSwearRegexes = [
    RegExp(
      r'^(?:fuck|shit|bitch|cunt|bastard|dick|pussy|whore|cocksucker|motherfucker|dumbass|wanker|prick|slut|asshole)\w*',
      caseSensitive: false,
    ),
    RegExp(r'^ass$', caseSensitive: false),
  ];

  /// Censors all profane words in the given text by replacing their intermediate
  /// characters with asterisks (e.g. "fuck" -> "f**k", "сука" -> "с**а").
  static String censor(String text) {
    if (text.isEmpty) return text;

    // Word token pattern matching sequences of Cyrillic/Latin letters and numbers.
    // This allows us to inspect and replace words individually, avoiding the limitation
    // of ASCII-only word boundaries (\b) in Dart.
    final wordRegex = RegExp(r'([a-zA-Zа-яА-ЯёЁ0-9_]+)');

    return text.replaceAllMapped(wordRegex, (match) {
      final word = match.group(1) ?? '';
      if (_isSwearWord(word)) {
        return _maskWord(word);
      }
      return word;
    });
  }

  static bool _isSwearWord(String word) {
    final lowerWord = word.toLowerCase();
    for (final regex in _russianSwearRegexes) {
      if (regex.hasMatch(lowerWord)) {
        return true;
      }
    }
    for (final regex in _englishSwearRegexes) {
      if (regex.hasMatch(lowerWord)) {
        return true;
      }
    }
    return false;
  }

  static String _maskWord(String word) {
    if (word.length <= 2) {
      return '*' * word.length;
    }
    if (word.length == 3) {
      return '${word[0]}*${word[2]}';
    }
    final middleLength = word.length - 2;
    return '${word[0]}${'*' * middleLength}${word[word.length - 1]}';
  }
}
