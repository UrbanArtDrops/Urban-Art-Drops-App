import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Urban Art Drops'**
  String get appTitle;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navDrops.
  ///
  /// In en, this message translates to:
  /// **'Drops'**
  String get navDrops;

  /// No description provided for @navLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get navLeaderboard;

  /// No description provided for @navLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get navLogin;

  /// No description provided for @navRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get navRegister;

  /// No description provided for @navArtistArea.
  ///
  /// In en, this message translates to:
  /// **'Artist Area'**
  String get navArtistArea;

  /// No description provided for @navDropMakerArea.
  ///
  /// In en, this message translates to:
  /// **'Drop-Maker Area'**
  String get navDropMakerArea;

  /// No description provided for @navModeration.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get navModeration;

  /// No description provided for @navAdminConfig.
  ///
  /// In en, this message translates to:
  /// **'Admin Configuration'**
  String get navAdminConfig;

  /// No description provided for @navAdminUsers.
  ///
  /// In en, this message translates to:
  /// **'Admin Users'**
  String get navAdminUsers;

  /// No description provided for @navAdminContent.
  ///
  /// In en, this message translates to:
  /// **'Admin Content'**
  String get navAdminContent;

  /// No description provided for @defaultMainRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'30'**
  String get defaultMainRadiusKm;

  /// No description provided for @defaultUnclaimedRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'3'**
  String get defaultUnclaimedRadiusKm;

  /// No description provided for @mapRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Main map radius: {radiusKm} km'**
  String mapRadiusLabel(Object radiusKm);

  /// No description provided for @mapUnclaimedRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Unclaimed drop radius: {radiusKm} km'**
  String mapUnclaimedRadiusLabel(Object radiusKm);

  /// No description provided for @mapPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Map preview (OpenStreetMap integration endpoint)'**
  String get mapPlaceholder;

  /// No description provided for @searchSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Search and sorting'**
  String get searchSortTitle;

  /// No description provided for @manualLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Manual location or device location'**
  String get manualLocationLabel;

  /// No description provided for @distanceColumnVisible.
  ///
  /// In en, this message translates to:
  /// **'Distance sorting is enabled.'**
  String get distanceColumnVisible;

  /// No description provided for @sampleDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Neon Fox - East City'**
  String get sampleDropTitle;

  /// No description provided for @sampleDropTitleTwo.
  ///
  /// In en, this message translates to:
  /// **'Steel Bird - Riverside'**
  String get sampleDropTitleTwo;

  /// No description provided for @sampleDropSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Artist + Drop-Maker + mini map + claimed hunters'**
  String get sampleDropSubtitle;

  /// No description provided for @distanceValue.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String distanceValue(Object value);

  /// No description provided for @dropDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop details'**
  String get dropDetailTitle;

  /// No description provided for @dropDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description, gallery, maker comment and claim state.'**
  String get dropDetailDescription;

  /// No description provided for @claimedHuntersTitle.
  ///
  /// In en, this message translates to:
  /// **'Claimed hunters'**
  String get claimedHuntersTitle;

  /// No description provided for @claimedHuntersValue.
  ///
  /// In en, this message translates to:
  /// **'HunterOne, HunterTwo'**
  String get claimedHuntersValue;

  /// No description provided for @claimTitle.
  ///
  /// In en, this message translates to:
  /// **'Claim item'**
  String get claimTitle;

  /// No description provided for @claimInstruction.
  ///
  /// In en, this message translates to:
  /// **'Scan QR and submit nickname or account claim.'**
  String get claimInstruction;

  /// No description provided for @nicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nicknameLabel;

  /// No description provided for @claimButton.
  ///
  /// In en, this message translates to:
  /// **'Claim now'**
  String get claimButton;

  /// No description provided for @rankEntry.
  ///
  /// In en, this message translates to:
  /// **'#{rank} - {name}'**
  String rankEntry(Object rank, Object name);

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @providerLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider login'**
  String get providerLoginTitle;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @roleHunter.
  ///
  /// In en, this message translates to:
  /// **'Hunter'**
  String get roleHunter;

  /// No description provided for @roleArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get roleArtist;

  /// No description provided for @roleDropMaker.
  ///
  /// In en, this message translates to:
  /// **'Drop-Maker'**
  String get roleDropMaker;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerButton;

  /// No description provided for @artistArtPiecesTitle.
  ///
  /// In en, this message translates to:
  /// **'Artist: Art Pieces'**
  String get artistArtPiecesTitle;

  /// No description provided for @sampleArtPieceTitle.
  ///
  /// In en, this message translates to:
  /// **'Art Piece: Crystal Owl'**
  String get sampleArtPieceTitle;

  /// No description provided for @sampleArtPieceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Images/3D model + publish status'**
  String get sampleArtPieceSubtitle;

  /// No description provided for @artistDropManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Own drop manager'**
  String get artistDropManagerTitle;

  /// No description provided for @artistDropManagerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit, delete or depublish own drops'**
  String get artistDropManagerSubtitle;

  /// No description provided for @dropMakerTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop-Maker workspace'**
  String get dropMakerTitle;

  /// No description provided for @dropMakerArtPieceSelection.
  ///
  /// In en, this message translates to:
  /// **'Select art piece'**
  String get dropMakerArtPieceSelection;

  /// No description provided for @dropMakerCreateDrop.
  ///
  /// In en, this message translates to:
  /// **'Create drop with location and item amount'**
  String get dropMakerCreateDrop;

  /// No description provided for @dropMakerPublishTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish and depublish'**
  String get dropMakerPublishTitle;

  /// No description provided for @dropMakerPublishSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Social channels and claim override'**
  String get dropMakerPublishSubtitle;

  /// No description provided for @moderationTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation queue'**
  String get moderationTitle;

  /// No description provided for @reportedCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Reported comment'**
  String get reportedCommentTitle;

  /// No description provided for @reportedCommentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visible until moderation decision'**
  String get reportedCommentSubtitle;

  /// No description provided for @reportedArtPieceTitle.
  ///
  /// In en, this message translates to:
  /// **'Reported art piece'**
  String get reportedArtPieceTitle;

  /// No description provided for @reportedArtPieceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mail alert is generated'**
  String get reportedArtPieceSubtitle;

  /// No description provided for @smtpLabel.
  ///
  /// In en, this message translates to:
  /// **'SMTP host'**
  String get smtpLabel;

  /// No description provided for @mainMapRadiusSetting.
  ///
  /// In en, this message translates to:
  /// **'Main map radius (km)'**
  String get mainMapRadiusSetting;

  /// No description provided for @miniMapRadiusSetting.
  ///
  /// In en, this message translates to:
  /// **'Mini-map radius (km)'**
  String get miniMapRadiusSetting;

  /// No description provided for @unclaimedRadiusSetting.
  ///
  /// In en, this message translates to:
  /// **'Unclaimed radius (km)'**
  String get unclaimedRadiusSetting;

  /// No description provided for @showExactPositionSetting.
  ///
  /// In en, this message translates to:
  /// **'Show exact position when fully claimed'**
  String get showExactPositionSetting;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @userRow.
  ///
  /// In en, this message translates to:
  /// **'{email} ({role})'**
  String userRow(Object email, Object role);

  /// No description provided for @userRowActions.
  ///
  /// In en, this message translates to:
  /// **'Approve, suspend, edit username/email/role'**
  String get userRowActions;

  /// No description provided for @globalArtPieceModerationTitle.
  ///
  /// In en, this message translates to:
  /// **'Global art piece moderation'**
  String get globalArtPieceModerationTitle;

  /// No description provided for @globalArtPieceModerationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit, delete, publish and depublish'**
  String get globalArtPieceModerationSubtitle;

  /// No description provided for @globalDropModerationTitle.
  ///
  /// In en, this message translates to:
  /// **'Global drop moderation'**
  String get globalDropModerationTitle;

  /// No description provided for @globalDropModerationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit, delete, publish and depublish'**
  String get globalDropModerationSubtitle;
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
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
