import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('vi')
  ];

  /// No description provided for @home_page_list_title.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get home_page_list_title;

  /// No description provided for @empty_list.
  ///
  /// In en, this message translates to:
  /// **'Empty list'**
  String get empty_list;

  /// No description provided for @alway_beside.
  ///
  /// In en, this message translates to:
  /// **'Always be brothers'**
  String get alway_beside;

  /// No description provided for @create_new.
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get create_new;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Score Keeper'**
  String get app_name;

  /// No description provided for @select_player_title.
  ///
  /// In en, this message translates to:
  /// **'SELECT PLAYER'**
  String get select_player_title;

  /// No description provided for @select_2to6player.
  ///
  /// In en, this message translates to:
  /// **'Select from 2 to 6 players to start'**
  String get select_2to6player;

  /// No description provided for @let_start.
  ///
  /// In en, this message translates to:
  /// **' LET\'S START'**
  String get let_start;

  /// No description provided for @add_player.
  ///
  /// In en, this message translates to:
  /// **'ADD NEW PLAYER'**
  String get add_player;

  /// No description provided for @score_board.
  ///
  /// In en, this message translates to:
  /// **'SCORE BOARD'**
  String get score_board;

  /// No description provided for @add_score.
  ///
  /// In en, this message translates to:
  /// **'ADD SCORE'**
  String get add_score;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete;

  /// No description provided for @new_play.
  ///
  /// In en, this message translates to:
  /// **' New'**
  String get new_play;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get save;

  /// No description provided for @player_number.
  ///
  /// In en, this message translates to:
  /// **'No. of player'**
  String get player_number;

  /// No description provided for @player_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get player_name_hint;

  /// No description provided for @delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete?'**
  String get delete_confirm;

  /// No description provided for @share_application.
  ///
  /// In en, this message translates to:
  /// **'  Share application'**
  String get share_application;

  /// No description provided for @vote_application.
  ///
  /// In en, this message translates to:
  /// **'  Feedback application'**
  String get vote_application;

  /// No description provided for @privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'  Privacy policy'**
  String get privacy_policy;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download the latest Score Keeper App on Google Play Store'**
  String get download;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
