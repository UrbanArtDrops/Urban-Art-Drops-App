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

  /// No description provided for @menuProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get menuProfile;

  /// No description provided for @menuMyArt.
  ///
  /// In en, this message translates to:
  /// **'My art'**
  String get menuMyArt;

  /// No description provided for @menuArtWorks.
  ///
  /// In en, this message translates to:
  /// **'Artworks'**
  String get menuArtWorks;

  /// No description provided for @menuMyDrops.
  ///
  /// In en, this message translates to:
  /// **'My drops'**
  String get menuMyDrops;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @menuUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get menuUsers;

  /// No description provided for @profileNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You are currently not signed in.'**
  String get profileNotLoggedIn;

  /// No description provided for @profileRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String profileRoleLabel(Object role);

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @refreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshAction;

  /// No description provided for @createAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAction;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @publishAction.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishAction;

  /// No description provided for @depublishAction.
  ///
  /// In en, this message translates to:
  /// **'Depublish'**
  String get depublishAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDelete;

  /// No description provided for @genericSaveError.
  ///
  /// In en, this message translates to:
  /// **'Save failed.'**
  String get genericSaveError;

  /// No description provided for @searchDropsHint.
  ///
  /// In en, this message translates to:
  /// **'Search drops (title or ID)'**
  String get searchDropsHint;

  /// No description provided for @dropListLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter city or postal code'**
  String get dropListLocationHint;

  /// No description provided for @dropListSortingByDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance sorting active: {location}'**
  String dropListSortingByDistance(Object location);

  /// No description provided for @dropListLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No location is available for this drop.'**
  String get dropListLocationUnavailable;

  /// No description provided for @dropListLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Drops could not be loaded.'**
  String get dropListLoadFailed;

  /// No description provided for @dropListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No published drops found.'**
  String get dropListEmpty;

  /// No description provided for @leaderboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard could not be loaded.'**
  String get leaderboardLoadFailed;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No leaderboard entries yet.'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardClaimCount.
  ///
  /// In en, this message translates to:
  /// **'{count} claims'**
  String leaderboardClaimCount(Object count);

  /// No description provided for @leaderboardNoClaimedDrops.
  ///
  /// In en, this message translates to:
  /// **'No claimed drops available.'**
  String get leaderboardNoClaimedDrops;

  /// No description provided for @leaderboardDropClaimCount.
  ///
  /// In en, this message translates to:
  /// **'{count} claims in this drop'**
  String leaderboardDropClaimCount(Object count);

  /// No description provided for @leaderboardAnonymousFallback.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get leaderboardAnonymousFallback;

  /// No description provided for @claimedItemsValue.
  ///
  /// In en, this message translates to:
  /// **'{claimed} of {total} claimed'**
  String claimedItemsValue(Object claimed, Object total);

  /// No description provided for @dropFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop {id}'**
  String dropFallbackTitle(Object id);

  /// No description provided for @usersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Users could not be loaded.'**
  String get usersLoadFailed;

  /// No description provided for @userCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get userCreateTitle;

  /// No description provided for @userEditUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit username'**
  String get userEditUsernameTitle;

  /// No description provided for @userApproveAction.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get userApproveAction;

  /// No description provided for @userRevokeApprovalAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke approval'**
  String get userRevokeApprovalAction;

  /// No description provided for @userSuspendAction.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get userSuspendAction;

  /// No description provided for @userUnsuspendAction.
  ///
  /// In en, this message translates to:
  /// **'Unsuspend'**
  String get userUnsuspendAction;

  /// No description provided for @userChangeRoleAction.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get userChangeRoleAction;

  /// No description provided for @userEditUsernameAction.
  ///
  /// In en, this message translates to:
  /// **'Edit username'**
  String get userEditUsernameAction;

  /// No description provided for @userApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get userApproved;

  /// No description provided for @userNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get userNotApproved;

  /// No description provided for @userSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get userSuspended;

  /// No description provided for @userActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get userActive;

  /// No description provided for @noUsersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No users available.'**
  String get noUsersAvailable;

  /// No description provided for @artPiecesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Art pieces could not be loaded.'**
  String get artPiecesLoadFailed;

  /// No description provided for @noArtPiecesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No art pieces available.'**
  String get noArtPiecesAvailable;

  /// No description provided for @noArtistsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No artist accounts available.'**
  String get noArtistsAvailable;

  /// No description provided for @artPieceCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create art piece'**
  String get artPieceCreateTitle;

  /// No description provided for @artPieceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit art piece'**
  String get artPieceEditTitle;

  /// No description provided for @artPieceTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get artPieceTitleLabel;

  /// No description provided for @artPieceDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get artPieceDescriptionLabel;

  /// No description provided for @artPiecePhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo URLs'**
  String get artPiecePhotosLabel;

  /// No description provided for @artPieceArtistLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artPieceArtistLabel;

  /// No description provided for @artPieceAssetTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Asset type'**
  String get artPieceAssetTypeLabel;

  /// No description provided for @artPieceAssetImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get artPieceAssetImage;

  /// No description provided for @artPieceAssetModel3d.
  ///
  /// In en, this message translates to:
  /// **'3D model'**
  String get artPieceAssetModel3d;

  /// No description provided for @artPieceDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete art piece \"{title}\"?'**
  String artPieceDeleteConfirm(Object title);

  /// No description provided for @commaSeparatedHint.
  ///
  /// In en, this message translates to:
  /// **'Comma separated values'**
  String get commaSeparatedHint;

  /// No description provided for @dropsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Drops could not be loaded.'**
  String get dropsLoadFailed;

  /// No description provided for @noDropsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No drops available.'**
  String get noDropsAvailable;

  /// No description provided for @dropDependenciesMissing.
  ///
  /// In en, this message translates to:
  /// **'Art pieces or drop-makers are missing.'**
  String get dropDependenciesMissing;

  /// No description provided for @dropCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create drop'**
  String get dropCreateTitle;

  /// No description provided for @dropEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit drop'**
  String get dropEditTitle;

  /// No description provided for @dropDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete drop {id}?'**
  String dropDeleteConfirm(Object id);

  /// No description provided for @dropArtPieceLabel.
  ///
  /// In en, this message translates to:
  /// **'Art piece'**
  String get dropArtPieceLabel;

  /// No description provided for @dropMakerUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Drop-maker'**
  String get dropMakerUserLabel;

  /// No description provided for @dropStationaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Stationary'**
  String get dropStationaryLabel;

  /// No description provided for @dropPortableItemCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Portable item count'**
  String get dropPortableItemCountLabel;

  /// No description provided for @dropLatitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get dropLatitudeLabel;

  /// No description provided for @dropLongitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get dropLongitudeLabel;

  /// No description provided for @dropLocationPhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'Location photo URLs'**
  String get dropLocationPhotosLabel;

  /// No description provided for @dropItemCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Items (count)'**
  String get dropItemCountLabel;

  /// No description provided for @statusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get statusPublished;

  /// No description provided for @statusUnpublished.
  ///
  /// In en, this message translates to:
  /// **'Unpublished'**
  String get statusUnpublished;

  /// No description provided for @mapDataLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Map data could not be loaded.'**
  String get mapDataLoadFailed;

  /// No description provided for @mapNoDrops.
  ///
  /// In en, this message translates to:
  /// **'No drops available.'**
  String get mapNoDrops;

  /// No description provided for @topMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Top navigation'**
  String get topMenuTooltip;

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

  /// No description provided for @mapCenteredOnLatestDrop.
  ///
  /// In en, this message translates to:
  /// **'Map centered on latest drop: {dropTitle}'**
  String mapCenteredOnLatestDrop(Object dropTitle);

  /// No description provided for @mapCenterCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Center: {latitude}, {longitude}'**
  String mapCenterCoordinates(Object latitude, Object longitude);

  /// No description provided for @centerOnMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get centerOnMyLocation;

  /// No description provided for @mapCenteredOnUser.
  ///
  /// In en, this message translates to:
  /// **'Map centered on your location.'**
  String get mapCenteredOnUser;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location service is disabled.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Location could not be resolved.'**
  String get locationError;

  /// No description provided for @mapSearchLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Search location manually'**
  String get mapSearchLocationHint;

  /// No description provided for @mapSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching location found.'**
  String get mapSearchNoResults;

  /// No description provided for @mapSearchError.
  ///
  /// In en, this message translates to:
  /// **'Location suggestions could not be loaded.'**
  String get mapSearchError;

  /// No description provided for @mapDropDetails.
  ///
  /// In en, this message translates to:
  /// **'Drop details'**
  String get mapDropDetails;

  /// No description provided for @mapShowDropDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a drop pin to view details.'**
  String get mapShowDropDetailsHint;

  /// No description provided for @mapArtistLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get mapArtistLabel;

  /// No description provided for @mapDropMakerLabel.
  ///
  /// In en, this message translates to:
  /// **'Drop-Maker'**
  String get mapDropMakerLabel;

  /// No description provided for @mapDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get mapDescriptionLabel;

  /// No description provided for @mapClaimedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Claimed by'**
  String get mapClaimedByLabel;

  /// No description provided for @mapUnclaimedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not claimed yet'**
  String get mapUnclaimedLabel;

  /// No description provided for @mapCloseDetails.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get mapCloseDetails;

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

  /// No description provided for @dropDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Drop details could not be loaded.'**
  String get dropDetailLoadFailed;

  /// No description provided for @dropDetailDescriptionSection.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get dropDetailDescriptionSection;

  /// No description provided for @dropDetailLocationSection.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get dropDetailLocationSection;

  /// No description provided for @dropDetailTechnicalSection.
  ///
  /// In en, this message translates to:
  /// **'Technical data'**
  String get dropDetailTechnicalSection;

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

  /// No description provided for @boolYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get boolYes;

  /// No description provided for @boolNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get boolNo;

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
