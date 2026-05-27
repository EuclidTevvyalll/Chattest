import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/services/duplicate_detector.dart';

void main() {
  group('DuplicateDetector Tests', () {
    test('Normalizes strings correctly by converting to lowercase and stripping punctuation/whitespaces', () {
      expect(DuplicateDetector.normalize('Привет!'), 'привет');
      expect(DuplicateDetector.normalize('Как дела?   '), 'какдела');
      expect(DuplicateDetector.normalize('Hello, world... 123!'), 'helloworld123');
    });

    test('Computes Levenshtein distance correctly', () {
      expect(DuplicateDetector.levenshtein('привет', 'привет'), 0);
      expect(DuplicateDetector.levenshtein('привет', 'приве'), 1);
      expect(DuplicateDetector.levenshtein('привет', 'превет'), 1);
      expect(DuplicateDetector.levenshtein('привет', 'привет!'), 1);
      expect(DuplicateDetector.levenshtein('kitten', 'sitting'), 3);
    });

    test('Correctly identifies exact duplicates', () {
      expect(DuplicateDetector.isDuplicate('Привет', 'Привет'), true);
      expect(DuplicateDetector.isDuplicate('Как дела', 'Как дела'), true);
    });

    test('Correctly identifies similar duplicates (punctuation/casing variations)', () {
      expect(DuplicateDetector.isDuplicate('Привет', 'Привет!'), true);
      expect(DuplicateDetector.isDuplicate('Привет', 'привет...   '), true);
      expect(DuplicateDetector.isDuplicate('Купи крипту', 'Купи крипту!'), true);
      expect(DuplicateDetector.isDuplicate('Как твои дела?', 'как твои дела'), true);
    });

    test('Does not flag different messages as duplicates', () {
      expect(DuplicateDetector.isDuplicate('Привет', 'Как дела'), false);
      expect(DuplicateDetector.isDuplicate('Купи крипту', 'Продай крипту'), false);
      expect(DuplicateDetector.isDuplicate('Давай 3', 'Давай 2'), false);
    });

    test('Handles empty and edge cases', () {
      expect(DuplicateDetector.isDuplicate('!!!', '???'), true); // both normalize to empty
      expect(DuplicateDetector.isDuplicate('Привет', '!!!'), false);
    });
  });
}
