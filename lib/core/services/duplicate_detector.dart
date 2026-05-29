class DuplicateDetector {
  static String normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-zA-Zа-яА-ЯёЁ0-9]'), '');
  }

  static int levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        final cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = _min3(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
      }

      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v0[t.length];
  }

  static int _min3(int a, int b, int c) {
    int min = a;
    if (b < min) min = b;
    if (c < min) min = c;
    return min;
  }

  static bool isDuplicate(
    String newMsg,
    String oldMsg, {
    double threshold = 0.85,
  }) {
    final normalizedNew = normalize(newMsg);
    final normalizedOld = normalize(oldMsg);

    if (normalizedNew.isEmpty && normalizedOld.isEmpty) {
      return true;
    }

    if (normalizedNew.isEmpty || normalizedOld.isEmpty) {
      return false;
    }

    final distance = levenshtein(normalizedNew, normalizedOld);
    final maxLength = normalizedNew.length > normalizedOld.length
        ? normalizedNew.length
        : normalizedOld.length;

    final similarity = 1.0 - (distance / maxLength);
    return similarity >= threshold;
  }
}
