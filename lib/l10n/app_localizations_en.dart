// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get home => 'Home';

  @override
  String get favorite => 'Favorite';

  @override
  String get app_title => 'Rick and Morty';

  @override
  String get favorites_title => 'Favorites';

  @override
  String get no_favorites => 'No favorites yet';

  @override
  String get last_location => 'Last location:';

  @override
  String get status => 'Status';

  @override
  String get species => 'Species';

  @override
  String get gender => 'Gender';

  @override
  String get origin => 'Origin';

  @override
  String get created_at => 'Created at';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get error_oops => 'Oops!';
}
