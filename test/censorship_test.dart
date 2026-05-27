import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/services/censorship_service.dart';

void main() {
  group('CensorshipService Tests', () {
    test('Censors English swear words correctly', () {
      expect(CensorshipService.censor('fuck'), 'f**k');
      expect(CensorshipService.censor('shitty'), 's****y');
      expect(CensorshipService.censor('What a bitch!'), 'What a b***h!');
      expect(CensorshipService.censor('ass'), 'a*s');
      expect(CensorshipService.censor('asshole'), 'a*****e');
    });

    test('Censors Russian swear words correctly', () {
      expect(CensorshipService.censor('хуй'), 'х*й');
      expect(CensorshipService.censor('пизда'), 'п***а');
      expect(CensorshipService.censor('пиздец'), 'п****ц');
      expect(CensorshipService.censor('блять'), 'б***ь');
      expect(CensorshipService.censor('блядь'), 'б***ь');
      expect(CensorshipService.censor('ебать'), 'е***ь');
      expect(CensorshipService.censor('заебись'), 'з*****ь');
      expect(CensorshipService.censor('охуеть'), 'о****ь');
      expect(CensorshipService.censor('сука'), 'с**а');
      expect(CensorshipService.censor('говно'), 'г***о');
      expect(CensorshipService.censor('дрочить'), 'д*****ь');
      expect(CensorshipService.censor('пидор'), 'п***р');
    });

    test('Does not censor clean words containing substrings', () {
      expect(CensorshipService.censor('хлеб'), 'хлеб');
      expect(CensorshipService.censor('стебель'), 'стебель');
      expect(CensorshipService.censor('потреблять'), 'потреблять');
      expect(CensorshipService.censor('колебания'), 'колебания');
      expect(CensorshipService.censor('class'), 'class');
      expect(CensorshipService.censor('passion'), 'passion');
      expect(CensorshipService.censor('рисунок'), 'рисунок');
      expect(CensorshipService.censor('сукно'), 'сукно');
      expect(CensorshipService.censor('барсук'), 'барсук');
    });

    test('Handles mixed text and casing correctly', () {
      expect(
        CensorshipService.censor("Эй, ты, СУКА! Какого ХУЯ? C'mon, fuck off!"),
        "Эй, ты, С**А! Какого Х*Я? C'mon, f**k off!",
      );
    });

    test('Handles empty and basic string gracefully', () {
      expect(CensorshipService.censor(''), '');
      expect(CensorshipService.censor('Hello world'), 'Hello world');
    });
  });
}
