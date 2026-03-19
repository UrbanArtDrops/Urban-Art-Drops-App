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

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your profile could not be loaded.'**
  String get profileLoadFailed;

  /// No description provided for @profileRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String profileRoleLabel(Object role);

  /// No description provided for @profileContactSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account data'**
  String get profileContactSectionTitle;

  /// No description provided for @profileDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayNameLabel;

  /// No description provided for @profileImageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile image'**
  String get profileImageSectionTitle;

  /// No description provided for @profileImageHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a profile image or remove the current one. Changes are saved with the profile form.'**
  String get profileImageHint;

  /// No description provided for @profileImageUploadAction.
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get profileImageUploadAction;

  /// No description provided for @profileImageRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get profileImageRemoveAction;

  /// No description provided for @profileImagePickerFailed.
  ///
  /// In en, this message translates to:
  /// **'The selected profile image could not be loaded.'**
  String get profileImagePickerFailed;

  /// No description provided for @profileLocalAccountChip.
  ///
  /// In en, this message translates to:
  /// **'Local account'**
  String get profileLocalAccountChip;

  /// No description provided for @profileProviderAccountChip.
  ///
  /// In en, this message translates to:
  /// **'Provider account'**
  String get profileProviderAccountChip;

  /// No description provided for @profileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaveSuccess;

  /// No description provided for @profileMfaSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Multi-factor authentication'**
  String get profileMfaSectionTitle;

  /// No description provided for @profileMfaEnabled.
  ///
  /// In en, this message translates to:
  /// **'MFA enabled'**
  String get profileMfaEnabled;

  /// No description provided for @profileMfaDisabled.
  ///
  /// In en, this message translates to:
  /// **'MFA not enabled'**
  String get profileMfaDisabled;

  /// No description provided for @profileMfaRequiredByPolicy.
  ///
  /// In en, this message translates to:
  /// **'This role requires app-based MFA.'**
  String get profileMfaRequiredByPolicy;

  /// No description provided for @profileMfaOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'You can enable app-based MFA for this account.'**
  String get profileMfaOptionalHint;

  /// No description provided for @profileMfaSetupAction.
  ///
  /// In en, this message translates to:
  /// **'Set up MFA'**
  String get profileMfaSetupAction;

  /// No description provided for @profileMfaReconfigureAction.
  ///
  /// In en, this message translates to:
  /// **'Reconfigure MFA'**
  String get profileMfaReconfigureAction;

  /// No description provided for @profileMfaDisableAction.
  ///
  /// In en, this message translates to:
  /// **'Disable MFA'**
  String get profileMfaDisableAction;

  /// No description provided for @profileMfaDisableHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a current MFA code to disable the configured authenticator.'**
  String get profileMfaDisableHint;

  /// No description provided for @profileMfaCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the current MFA code.'**
  String get profileMfaCodeRequired;

  /// No description provided for @profileMfaSetupSuccess.
  ///
  /// In en, this message translates to:
  /// **'MFA was configured.'**
  String get profileMfaSetupSuccess;

  /// No description provided for @profileMfaDisableSuccess.
  ///
  /// In en, this message translates to:
  /// **'MFA was disabled.'**
  String get profileMfaDisableSuccess;

  /// No description provided for @profileNotificationsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotificationsSectionTitle;

  /// No description provided for @profileNotificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no notifications yet.'**
  String get profileNotificationsEmpty;

  /// No description provided for @profileNotificationMarkReadAction.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get profileNotificationMarkReadAction;

  /// No description provided for @profileNotificationReadState.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get profileNotificationReadState;

  /// No description provided for @profileNotificationUnreadState.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get profileNotificationUnreadState;

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

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAction;

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

  /// No description provided for @detailsAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsAction;

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
  /// **'Photos'**
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

  /// No description provided for @artPieceAssetSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Production asset'**
  String get artPieceAssetSectionTitle;

  /// No description provided for @artPieceUploadAssetAction.
  ///
  /// In en, this message translates to:
  /// **'Upload 3D model'**
  String get artPieceUploadAssetAction;

  /// No description provided for @artPieceDownloadAssetAction.
  ///
  /// In en, this message translates to:
  /// **'Download file'**
  String get artPieceDownloadAssetAction;

  /// No description provided for @artPieceAssetHelp.
  ///
  /// In en, this message translates to:
  /// **'Upload the 3D model used as the production asset for this artwork.'**
  String get artPieceAssetHelp;

  /// No description provided for @artPieceAssetEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No 3D model uploaded yet.'**
  String get artPieceAssetEmptyState;

  /// No description provided for @artPieceAssetContentType.
  ///
  /// In en, this message translates to:
  /// **'File type: {value}'**
  String artPieceAssetContentType(Object value);

  /// No description provided for @artPieceAssetSize.
  ///
  /// In en, this message translates to:
  /// **'File size: {value}'**
  String artPieceAssetSize(Object value);

  /// No description provided for @artPieceModelAssetRequiredError.
  ///
  /// In en, this message translates to:
  /// **'A model upload is required for 3D artworks.'**
  String get artPieceModelAssetRequiredError;

  /// No description provided for @artPieceAssetDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Started download for {fileName}.'**
  String artPieceAssetDownloadStarted(Object fileName);

  /// No description provided for @artPieceAssetDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The production asset could not be downloaded.'**
  String get artPieceAssetDownloadFailed;

  /// No description provided for @artPieceUploadPhotosAction.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get artPieceUploadPhotosAction;

  /// No description provided for @artPiecePhotosHelp.
  ///
  /// In en, this message translates to:
  /// **'Select local image files. Existing photos stay attached until you remove them.'**
  String get artPiecePhotosHelp;

  /// No description provided for @artPiecePhotosEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No photos selected yet.'**
  String get artPiecePhotosEmptyState;

  /// No description provided for @artPieceArtistRequiredError.
  ///
  /// In en, this message translates to:
  /// **'An artist must be selected.'**
  String get artPieceArtistRequiredError;

  /// No description provided for @artPieceTitleTooShortError.
  ///
  /// In en, this message translates to:
  /// **'The title must contain at least 3 characters.'**
  String get artPieceTitleTooShortError;

  /// No description provided for @artPieceDescriptionTooShortError.
  ///
  /// In en, this message translates to:
  /// **'The description must contain at least 20 characters.'**
  String get artPieceDescriptionTooShortError;

  /// No description provided for @artPieceDescriptionTooLongError.
  ///
  /// In en, this message translates to:
  /// **'The description can contain at most 3000 characters.'**
  String get artPieceDescriptionTooLongError;

  /// No description provided for @artPiecePhotosRequiredError.
  ///
  /// In en, this message translates to:
  /// **'At least one photo is required.'**
  String get artPiecePhotosRequiredError;

  /// No description provided for @artPiecePhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String artPiecePhotoCount(Object count);

  /// No description provided for @artPieceMetadataSection.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get artPieceMetadataSection;

  /// No description provided for @artPieceNoSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Select an artwork'**
  String get artPieceNoSelectionTitle;

  /// No description provided for @artPieceNoSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an artwork from the list to inspect and manage it.'**
  String get artPieceNoSelectionSubtitle;

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

  /// No description provided for @claimLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load claim data.'**
  String get claimLoadError;

  /// No description provided for @claimMissingToken.
  ///
  /// In en, this message translates to:
  /// **'No QR token is available.'**
  String get claimMissingToken;

  /// No description provided for @claimTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'QR token'**
  String get claimTokenLabel;

  /// No description provided for @claimAuthenticatedAs.
  ///
  /// In en, this message translates to:
  /// **'Claiming as account: {name}'**
  String claimAuthenticatedAs(Object name);

  /// No description provided for @claimAnonymousHint.
  ///
  /// In en, this message translates to:
  /// **'Without sign-in, a unique nickname is required.'**
  String get claimAnonymousHint;

  /// No description provided for @claimPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Art piece'**
  String get claimPreviewTitle;

  /// No description provided for @claimPreviewItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get claimPreviewItemLabel;

  /// No description provided for @claimAlreadyClaimed.
  ///
  /// In en, this message translates to:
  /// **'This item has already been claimed.'**
  String get claimAlreadyClaimed;

  /// No description provided for @claimAlreadyClaimedBy.
  ///
  /// In en, this message translates to:
  /// **'Already claimed by: {name}'**
  String claimAlreadyClaimedBy(Object name);

  /// No description provided for @claimSuccess.
  ///
  /// In en, this message translates to:
  /// **'Item claimed successfully.'**
  String get claimSuccess;

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

  /// No description provided for @authFillCredentialsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter email and password.'**
  String get authFillCredentialsHint;

  /// No description provided for @authFillRegistrationHint.
  ///
  /// In en, this message translates to:
  /// **'Fill in username, email, and password.'**
  String get authFillRegistrationHint;

  /// No description provided for @authRoleManagedAtRegistration.
  ///
  /// In en, this message translates to:
  /// **'The account type is stored when the account is created. You do not select it again during login.'**
  String get authRoleManagedAtRegistration;

  /// No description provided for @authProviderLoginComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Provider login is prepared in the product, but not wired into this local screen yet.'**
  String get authProviderLoginComingSoon;

  /// No description provided for @authProviderLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Provider sign-in opens a secure browser window and returns to the app after the external identity has been verified.'**
  String get authProviderLoginHint;

  /// No description provided for @authProviderRegistrationHint.
  ///
  /// In en, this message translates to:
  /// **'Create a linked provider account with the external provider, the target role, and your desired username. The external identity is resolved in a secure browser window.'**
  String get authProviderRegistrationHint;

  /// No description provided for @authProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get authProviderLabel;

  /// No description provided for @authProviderSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider subject'**
  String get authProviderSubjectLabel;

  /// No description provided for @authSelectProviderHint.
  ///
  /// In en, this message translates to:
  /// **'Select a provider'**
  String get authSelectProviderHint;

  /// No description provided for @authProviderFlowCancelledOrFailed.
  ///
  /// In en, this message translates to:
  /// **'Provider authentication was cancelled or failed.'**
  String get authProviderFlowCancelledOrFailed;

  /// No description provided for @authProviderMissingCompletionSession.
  ///
  /// In en, this message translates to:
  /// **'The provider callback did not return a completion session.'**
  String get authProviderMissingCompletionSession;

  /// No description provided for @authNoConfiguredProviders.
  ///
  /// In en, this message translates to:
  /// **'No authentication providers are currently configured.'**
  String get authNoConfiguredProviders;

  /// No description provided for @authMfaTitle.
  ///
  /// In en, this message translates to:
  /// **'Second factor'**
  String get authMfaTitle;

  /// No description provided for @authMfaCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'MFA code'**
  String get authMfaCodeLabel;

  /// No description provided for @authMfaSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code in your authenticator app or enter the key manually.'**
  String get authMfaSetupHint;

  /// No description provided for @authMfaManualKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Manual key'**
  String get authMfaManualKeyLabel;

  /// No description provided for @authMfaContinue.
  ///
  /// In en, this message translates to:
  /// **'Confirm MFA'**
  String get authMfaContinue;

  /// No description provided for @authMfaRequired.
  ///
  /// In en, this message translates to:
  /// **'MFA is required for this account.'**
  String get authMfaRequired;

  /// No description provided for @authHunterRegistrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Hunter account created. The verification step was simulated for local development. You can sign in now.'**
  String get authHunterRegistrationSuccess;

  /// No description provided for @authApprovalRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Account created. Email verification was simulated for local development. Approval is now pending.'**
  String get authApprovalRequestSubmitted;

  /// No description provided for @authHunterProviderRegistrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Hunter provider account created. You can sign in now.'**
  String get authHunterProviderRegistrationSuccess;

  /// No description provided for @authProviderApprovalRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Provider account created. Approval is now pending.'**
  String get authProviderApprovalRequestSubmitted;

  /// No description provided for @authHunterSelfServiceHint.
  ///
  /// In en, this message translates to:
  /// **'Hunters can register directly and start signing in after verification.'**
  String get authHunterSelfServiceHint;

  /// No description provided for @authArtistApprovalHint.
  ///
  /// In en, this message translates to:
  /// **'Artists can request an account. An admin must approve the account before login is allowed.'**
  String get authArtistApprovalHint;

  /// No description provided for @authDropMakerApprovalHint.
  ///
  /// In en, this message translates to:
  /// **'Drop-makers can request an account. An admin must approve the account before login is allowed.'**
  String get authDropMakerApprovalHint;

  /// No description provided for @authAdminRegistrationManaged.
  ///
  /// In en, this message translates to:
  /// **'Admin accounts are never self-registered here. They can only be created or assigned in user management.'**
  String get authAdminRegistrationManaged;

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

  /// No description provided for @providerRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider registration'**
  String get providerRegisterTitle;

  /// No description provided for @publicAppBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Public app base URL'**
  String get publicAppBaseUrlLabel;

  /// No description provided for @configLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load configuration.'**
  String get configLoadError;

  /// No description provided for @configSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved.'**
  String get configSaveSuccess;

  /// No description provided for @authProviderStatusSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication providers'**
  String get authProviderStatusSectionTitle;

  /// No description provided for @authProviderStatusEmpty.
  ///
  /// In en, this message translates to:
  /// **'No provider status is available.'**
  String get authProviderStatusEmpty;

  /// No description provided for @authProviderStatusEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get authProviderStatusEnabled;

  /// No description provided for @authProviderStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get authProviderStatusDisabled;

  /// No description provided for @authProviderStatusVisibleOnLogin.
  ///
  /// In en, this message translates to:
  /// **'Visible on login'**
  String get authProviderStatusVisibleOnLogin;

  /// No description provided for @authProviderStatusHiddenOnLogin.
  ///
  /// In en, this message translates to:
  /// **'Hidden on login'**
  String get authProviderStatusHiddenOnLogin;

  /// No description provided for @authProviderStatusClientIdPresent.
  ///
  /// In en, this message translates to:
  /// **'Client ID set'**
  String get authProviderStatusClientIdPresent;

  /// No description provided for @authProviderStatusClientIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Client ID missing'**
  String get authProviderStatusClientIdMissing;

  /// No description provided for @authProviderStatusClientSecretPresent.
  ///
  /// In en, this message translates to:
  /// **'Client secret set'**
  String get authProviderStatusClientSecretPresent;

  /// No description provided for @authProviderStatusClientSecretMissing.
  ///
  /// In en, this message translates to:
  /// **'Client secret missing'**
  String get authProviderStatusClientSecretMissing;

  /// No description provided for @authProviderStatusPkceEnabled.
  ///
  /// In en, this message translates to:
  /// **'PKCE enabled'**
  String get authProviderStatusPkceEnabled;

  /// No description provided for @authProviderStatusPkceDisabled.
  ///
  /// In en, this message translates to:
  /// **'PKCE disabled'**
  String get authProviderStatusPkceDisabled;

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

  /// No description provided for @makeDropWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Make a Drop Wizard'**
  String get makeDropWizardTitle;

  /// No description provided for @makeDropWizardFabLabel.
  ///
  /// In en, this message translates to:
  /// **'Create drop'**
  String get makeDropWizardFabLabel;

  /// No description provided for @makeDropStepBrowseTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Review artworks'**
  String get makeDropStepBrowseTitle;

  /// No description provided for @makeDropStepBrowseDescription.
  ///
  /// In en, this message translates to:
  /// **'Review the available artworks for the new drop.'**
  String get makeDropStepBrowseDescription;

  /// No description provided for @makeDropStepSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Select artwork'**
  String get makeDropStepSelectTitle;

  /// No description provided for @makeDropStepSelectDescription.
  ///
  /// In en, this message translates to:
  /// **'Click an artwork that should be used for this drop.'**
  String get makeDropStepSelectDescription;

  /// No description provided for @makeDropStepDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Download production asset'**
  String get makeDropStepDownloadTitle;

  /// No description provided for @makeDropStepDownloadDescription.
  ///
  /// In en, this message translates to:
  /// **'Actually download the stored production asset for the artwork before you continue preparing the drop.'**
  String get makeDropStepDownloadDescription;

  /// No description provided for @makeDropDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download production asset'**
  String get makeDropDownloadAction;

  /// No description provided for @makeDropDownloadSet.
  ///
  /// In en, this message translates to:
  /// **'Download step marked as done.'**
  String get makeDropDownloadSet;

  /// No description provided for @makeDropDownloadDone.
  ///
  /// In en, this message translates to:
  /// **'Download step completed.'**
  String get makeDropDownloadDone;

  /// No description provided for @makeDropDownloadUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No production asset is available for this artwork.'**
  String get makeDropDownloadUnavailable;

  /// No description provided for @makeDropDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The production asset download could not be started.'**
  String get makeDropDownloadFailed;

  /// No description provided for @makeDropSelectArtFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select an artwork first.'**
  String get makeDropSelectArtFirst;

  /// No description provided for @makeDropConfirmDownloadFirst.
  ///
  /// In en, this message translates to:
  /// **'Please complete the download step first.'**
  String get makeDropConfirmDownloadFirst;

  /// No description provided for @makeDropStepPrintTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Print drop + enter quantity'**
  String get makeDropStepPrintTitle;

  /// No description provided for @makeDropStepPrintDescription.
  ///
  /// In en, this message translates to:
  /// **'Printing the drop is out of scope. Enter the item quantity here.'**
  String get makeDropStepPrintDescription;

  /// No description provided for @makeDropItemCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Item quantity'**
  String get makeDropItemCountLabel;

  /// No description provided for @makeDropItemCountInvalid.
  ///
  /// In en, this message translates to:
  /// **'The quantity must be at least 1.'**
  String get makeDropItemCountInvalid;

  /// No description provided for @makeDropPortableItemCountInvalid.
  ///
  /// In en, this message translates to:
  /// **'The portable count must be between 1 and the total quantity.'**
  String get makeDropPortableItemCountInvalid;

  /// No description provided for @makeDropStepQrTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Show QR codes'**
  String get makeDropStepQrTitle;

  /// No description provided for @makeDropStepQrDescription.
  ///
  /// In en, this message translates to:
  /// **'Once the draft is saved, the real QR tokens from the backend are shown here.'**
  String get makeDropStepQrDescription;

  /// No description provided for @makeDropGenerateQrAction.
  ///
  /// In en, this message translates to:
  /// **'Generate QR codes'**
  String get makeDropGenerateQrAction;

  /// No description provided for @makeDropGenerateQrFirst.
  ///
  /// In en, this message translates to:
  /// **'Please save the drop draft first so QR codes can be created.'**
  String get makeDropGenerateQrFirst;

  /// No description provided for @makeDropStepPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Place drop + enter location'**
  String get makeDropStepPlaceTitle;

  /// No description provided for @makeDropStepPlaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Placing the drop is out of scope. Then capture the drop location and location photos.'**
  String get makeDropStepPlaceDescription;

  /// No description provided for @makeDropLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Drop location'**
  String get makeDropLocationLabel;

  /// No description provided for @makeDropLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a location.'**
  String get makeDropLocationRequired;

  /// No description provided for @makeDropLocationPhotosRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one location photo.'**
  String get makeDropLocationPhotosRequired;

  /// No description provided for @makeDropMissingCurrentUser.
  ///
  /// In en, this message translates to:
  /// **'The signed-in user could not be matched to a drop-maker account.'**
  String get makeDropMissingCurrentUser;

  /// No description provided for @makeDropSourceMediaHint.
  ///
  /// In en, this message translates to:
  /// **'Use the stored production asset or reference image from this artwork for manufacturing.'**
  String get makeDropSourceMediaHint;

  /// No description provided for @makeDropDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Drop draft saved. {count} QR codes are ready.'**
  String makeDropDraftSaved(Object count);

  /// No description provided for @makeDropReadyWithId.
  ///
  /// In en, this message translates to:
  /// **'Active draft: {id}'**
  String makeDropReadyWithId(Object id);

  /// No description provided for @makeDropQrCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'QR code {index}'**
  String makeDropQrCodeLabel(Object index);

  /// No description provided for @makeDropCoordinatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: {latitude}, {longitude}'**
  String makeDropCoordinatesLabel(Object latitude, Object longitude);

  /// No description provided for @makeDropAddLocationPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add location photos'**
  String get makeDropAddLocationPhotos;

  /// No description provided for @makeDropPauseAction.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get makeDropPauseAction;

  /// No description provided for @makeDropPaused.
  ///
  /// In en, this message translates to:
  /// **'Wizard paused. Continue it later from My Drops.'**
  String get makeDropPaused;

  /// No description provided for @makeDropResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume wizard'**
  String get makeDropResumeAction;

  /// No description provided for @makeDropPhotosSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} location photos selected'**
  String makeDropPhotosSelected(Object count);

  /// No description provided for @makeDropNoLocationPhotos.
  ///
  /// In en, this message translates to:
  /// **'No location photos selected yet.'**
  String get makeDropNoLocationPhotos;

  /// No description provided for @makeDropPublishAfterFinish.
  ///
  /// In en, this message translates to:
  /// **'Publish drop immediately after finishing'**
  String get makeDropPublishAfterFinish;

  /// No description provided for @makeDropFinishedPublished.
  ///
  /// In en, this message translates to:
  /// **'Drop saved and published.'**
  String get makeDropFinishedPublished;

  /// No description provided for @makeDropWizardFinished.
  ///
  /// In en, this message translates to:
  /// **'Wizard completed. The drop draft was saved.'**
  String get makeDropWizardFinished;

  /// No description provided for @makeDropNextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get makeDropNextAction;

  /// No description provided for @makeDropBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get makeDropBackAction;

  /// No description provided for @makeDropFinishAction.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get makeDropFinishAction;

  /// No description provided for @moderationTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation queue'**
  String get moderationTitle;

  /// No description provided for @moderationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Moderation reports could not be loaded.'**
  String get moderationLoadFailed;

  /// No description provided for @moderationActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The moderation action could not be completed.'**
  String get moderationActionFailed;

  /// No description provided for @moderationRestricted.
  ///
  /// In en, this message translates to:
  /// **'This view is only available to artists, drop-makers, moderators, and admins.'**
  String get moderationRestricted;

  /// No description provided for @moderationEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no reported items right now.'**
  String get moderationEmpty;

  /// No description provided for @moderationCommentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reported comments'**
  String get moderationCommentSectionTitle;

  /// No description provided for @moderationArtPieceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reported art pieces'**
  String get moderationArtPieceSectionTitle;

  /// No description provided for @moderationOpenDropAction.
  ///
  /// In en, this message translates to:
  /// **'Open drop'**
  String get moderationOpenDropAction;

  /// No description provided for @moderationHideCommentAction.
  ///
  /// In en, this message translates to:
  /// **'Hide comment'**
  String get moderationHideCommentAction;

  /// No description provided for @moderationDismissReportAction.
  ///
  /// In en, this message translates to:
  /// **'Dismiss report'**
  String get moderationDismissReportAction;

  /// No description provided for @moderationDepublishArtPieceAction.
  ///
  /// In en, this message translates to:
  /// **'Depublish art piece'**
  String get moderationDepublishArtPieceAction;

  /// No description provided for @moderationNoReasonProvided.
  ///
  /// In en, this message translates to:
  /// **'No report reason provided.'**
  String get moderationNoReasonProvided;

  /// No description provided for @moderationReportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported for: {value}'**
  String moderationReportedBy(Object value);

  /// No description provided for @moderationArtistLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist: {value}'**
  String moderationArtistLabel(Object value);

  /// No description provided for @moderationReportReason.
  ///
  /// In en, this message translates to:
  /// **'Report reason: {value}'**
  String moderationReportReason(Object value);

  /// No description provided for @moderationReportedAt.
  ///
  /// In en, this message translates to:
  /// **'Reported at: {value}'**
  String moderationReportedAt(Object value);

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

  /// No description provided for @dropDetailCommentsSection.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get dropDetailCommentsSection;

  /// No description provided for @dropDetailCommentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no comments for this drop yet.'**
  String get dropDetailCommentsEmpty;

  /// No description provided for @dropDetailCommentComposerTitle.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get dropDetailCommentComposerTitle;

  /// No description provided for @dropDetailCommentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write your comment about this drop.'**
  String get dropDetailCommentPlaceholder;

  /// No description provided for @dropDetailCommentSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send comment'**
  String get dropDetailCommentSubmit;

  /// No description provided for @dropDetailCommentCreated.
  ///
  /// In en, this message translates to:
  /// **'Comment saved.'**
  String get dropDetailCommentCreated;

  /// No description provided for @dropDetailCommentCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Comment could not be saved.'**
  String get dropDetailCommentCreateFailed;

  /// No description provided for @dropDetailCommentLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Only signed-in hunters, artists, drop-makers, and moderators can post comments.'**
  String get dropDetailCommentLoginHint;

  /// No description provided for @dropDetailReportCommentAction.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get dropDetailReportCommentAction;

  /// No description provided for @dropDetailReportArtPieceAction.
  ///
  /// In en, this message translates to:
  /// **'Report art piece'**
  String get dropDetailReportArtPieceAction;

  /// No description provided for @dropDetailAlreadyReported.
  ///
  /// In en, this message translates to:
  /// **'Already reported'**
  String get dropDetailAlreadyReported;

  /// No description provided for @dropDetailReportDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter an optional reason for the moderation report.'**
  String get dropDetailReportDialogDescription;

  /// No description provided for @dropDetailReportReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Report reason'**
  String get dropDetailReportReasonLabel;

  /// No description provided for @dropDetailReportReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Why should this content be reviewed?'**
  String get dropDetailReportReasonHint;

  /// No description provided for @dropDetailSubmitReportAction.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get dropDetailSubmitReportAction;

  /// No description provided for @dropDetailReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report saved.'**
  String get dropDetailReportSubmitted;

  /// No description provided for @dropDetailReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Report could not be saved.'**
  String get dropDetailReportFailed;

  /// No description provided for @dropDetailReportReason.
  ///
  /// In en, this message translates to:
  /// **'Report reason: {value}'**
  String dropDetailReportReason(Object value);

  /// No description provided for @dropDetailReportedAt.
  ///
  /// In en, this message translates to:
  /// **'Reported at: {value}'**
  String dropDetailReportedAt(Object value);

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

  /// No description provided for @userEditProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit user profile'**
  String get userEditProfileTitle;

  /// No description provided for @userEditProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get userEditProfileAction;

  /// No description provided for @artPieceSubtitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get artPieceSubtitleLabel;

  /// No description provided for @artPieceSubtitleTooLongError.
  ///
  /// In en, this message translates to:
  /// **'Subtitle must not exceed 200 characters.'**
  String get artPieceSubtitleTooLongError;

  /// No description provided for @dropMakerCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Drop-maker comment'**
  String get dropMakerCommentLabel;

  /// No description provided for @dropMakerCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note for production, placement, or context.'**
  String get dropMakerCommentHint;

  /// No description provided for @dropSocialChannelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Social channels'**
  String get dropSocialChannelsLabel;

  /// No description provided for @bootstrapAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Bootstrap admin'**
  String get bootstrapAdminTitle;

  /// No description provided for @bootstrapAdminLoginHint.
  ///
  /// In en, this message translates to:
  /// **'No admin account exists yet. Create the first administrator before continuing.'**
  String get bootstrapAdminLoginHint;

  /// No description provided for @bootstrapAdminAction.
  ///
  /// In en, this message translates to:
  /// **'Create first admin'**
  String get bootstrapAdminAction;

  /// No description provided for @bootstrapAdminDescription.
  ///
  /// In en, this message translates to:
  /// **'Create the initial administrator for this installation. The account is approved immediately and can configure the system afterwards.'**
  String get bootstrapAdminDescription;

  /// No description provided for @bootstrapAdminSuccess.
  ///
  /// In en, this message translates to:
  /// **'Initial administrator created. Please sign in to continue.'**
  String get bootstrapAdminSuccess;

  /// No description provided for @bootstrapAdminUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Admin bootstrap is no longer available because an administrator already exists.'**
  String get bootstrapAdminUnavailable;

  /// No description provided for @bootstrapAdminLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Bootstrap status could not be loaded.'**
  String get bootstrapAdminLoadFailed;
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
