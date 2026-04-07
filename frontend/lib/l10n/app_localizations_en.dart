// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Urban Art Drops';

  @override
  String get navMap => 'Map';

  @override
  String get navDrops => 'Drops';

  @override
  String get navLeaderboard => 'Leaderboard';

  @override
  String get navLogin => 'Login';

  @override
  String get navRegister => 'Register';

  @override
  String get navArtistArea => 'Artist Area';

  @override
  String get navDropMakerArea => 'Drop-Maker Area';

  @override
  String get navModeration => 'Moderation';

  @override
  String get navAdminConfig => 'Admin Configuration';

  @override
  String get navAdminUsers => 'Admin Users';

  @override
  String get navAdminContent => 'Admin Content';

  @override
  String get menuProfile => 'My profile';

  @override
  String get menuMyArt => 'My art';

  @override
  String get menuArtWorks => 'Artworks';

  @override
  String get menuMyDrops => 'My drops';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuUsers => 'Users';

  @override
  String get profileNotLoggedIn => 'You are currently not signed in.';

  @override
  String get profileLoadFailed => 'Your profile could not be loaded.';

  @override
  String profileRoleLabel(Object role) {
    return 'Role: $role';
  }

  @override
  String get profileContactSectionTitle => 'Account data';

  @override
  String get profileDisplayNameLabel => 'Display name';

  @override
  String get profileImageSectionTitle => 'Profile image';

  @override
  String get profileImageHint =>
      'Upload a profile image, capture a selfie, or remove the current one. Changes are saved with the profile form.';

  @override
  String get profileImageUploadAction => 'Upload image';

  @override
  String get profileImageSelfieAction => 'Capture selfie';

  @override
  String get profileImageRemoveAction => 'Remove image';

  @override
  String get profileImagePickerFailed =>
      'The selected profile image could not be loaded.';

  @override
  String get profileImageSelfieFailed => 'The selfie could not be captured.';

  @override
  String get profileLocalAccountChip => 'Local account';

  @override
  String get profileProviderAccountChip => 'Provider account';

  @override
  String get profileSaveSuccess => 'Profile saved.';

  @override
  String get profileMfaSectionTitle => 'Multi-factor authentication';

  @override
  String get profileMfaEnabled => 'MFA enabled';

  @override
  String get profileMfaDisabled => 'MFA not enabled';

  @override
  String get profileRoleApplicationSectionTitle => 'Role applications';

  @override
  String get profileRoleApplicationHint =>
      'Hunter accounts can request artist or drop-maker access here.';

  @override
  String profileRoleApplicationPending(Object role) {
    return 'Pending role application: $role';
  }

  @override
  String profileRoleApplicationRequestedAt(Object timestamp) {
    return 'Requested at: $timestamp';
  }

  @override
  String get profileRoleApplicationSubmitted =>
      'Your role application has been submitted.';

  @override
  String get profileRoleApplicationNotAvailableForCurrentRole =>
      'Role applications are only available for hunter accounts.';

  @override
  String get profileApplyArtistAction => 'Apply as artist';

  @override
  String get profileApplyDropMakerAction => 'Apply as drop-maker';

  @override
  String get profileMfaRequiredByPolicy => 'This role requires app-based MFA.';

  @override
  String get profileMfaOptionalHint =>
      'You can enable app-based MFA for this account.';

  @override
  String get profileMfaSetupAction => 'Set up MFA';

  @override
  String get profileMfaReconfigureAction => 'Reconfigure MFA';

  @override
  String get profileMfaDisableAction => 'Disable MFA';

  @override
  String get profileMfaDisableHint =>
      'Enter a current MFA code to disable the configured authenticator.';

  @override
  String get profileMfaCodeRequired => 'Enter the current MFA code.';

  @override
  String get profileMfaSetupSuccess => 'MFA was configured.';

  @override
  String get profileMfaDisableSuccess => 'MFA was disabled.';

  @override
  String get profileNotificationsSectionTitle => 'Notifications';

  @override
  String get profileNotificationsEmpty => 'There are no notifications yet.';

  @override
  String get profileNotificationsLoadFailed =>
      'Notifications could not be loaded.';

  @override
  String get profileNotificationMarkReadAction => 'Mark as read';

  @override
  String get profileNotificationReadState => 'Read';

  @override
  String get profileNotificationUnreadState => 'Unread';

  @override
  String get logoutButton => 'Logout';

  @override
  String get loadingData => 'Loading data...';

  @override
  String get retryButton => 'Retry';

  @override
  String get backAction => 'Back';

  @override
  String get refreshAction => 'Refresh';

  @override
  String get createAction => 'Create';

  @override
  String get detailsAction => 'Details';

  @override
  String get editAction => 'Edit';

  @override
  String get deleteAction => 'Delete';

  @override
  String get publishAction => 'Publish';

  @override
  String get depublishAction => 'Depublish';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get confirmDelete => 'Confirm deletion';

  @override
  String get genericSaveError => 'Save failed.';

  @override
  String get searchDropsHint => 'Search drops (title or ID)';

  @override
  String get dropListLocationHint => 'Enter city or postal code';

  @override
  String dropListSortingByDistance(Object location) {
    return 'Distance sorting active: $location';
  }

  @override
  String get dropListLocationUnavailable =>
      'No location is available for this drop.';

  @override
  String get dropListLoadFailed => 'Drops could not be loaded.';

  @override
  String get dropListEmpty => 'No published drops found.';

  @override
  String get leaderboardLoadFailed => 'Leaderboard could not be loaded.';

  @override
  String get leaderboardEmpty => 'No leaderboard entries yet.';

  @override
  String leaderboardClaimCount(Object count) {
    return '$count claims';
  }

  @override
  String get leaderboardNoClaimedDrops => 'No claimed drops available.';

  @override
  String leaderboardDropClaimCount(Object count) {
    return '$count claims in this drop';
  }

  @override
  String get leaderboardAnonymousFallback => 'Anonymous';

  @override
  String claimedItemsValue(Object claimed, Object total) {
    return '$claimed of $total claimed';
  }

  @override
  String dropFallbackTitle(Object id) {
    return 'Drop $id';
  }

  @override
  String get usersLoadFailed => 'Users could not be loaded.';

  @override
  String get userCreateTitle => 'Create user';

  @override
  String get userEditUsernameTitle => 'Edit username';

  @override
  String get userApproveAction => 'Approve';

  @override
  String get userRevokeApprovalAction => 'Revoke approval';

  @override
  String get userSuspendAction => 'Suspend';

  @override
  String get userUnsuspendAction => 'Unsuspend';

  @override
  String get userChangeRoleAction => 'Change role';

  @override
  String get userEditUsernameAction => 'Edit username';

  @override
  String get userApproved => 'Approved';

  @override
  String get userNotApproved => 'Not approved';

  @override
  String get userSuspended => 'Suspended';

  @override
  String get userActive => 'Active';

  @override
  String get noUsersAvailable => 'No users available.';

  @override
  String get artPiecesLoadFailed => 'Art pieces could not be loaded.';

  @override
  String get noArtPiecesAvailable => 'No art pieces available.';

  @override
  String get noArtistsAvailable => 'No artist accounts available.';

  @override
  String get artPieceCreateTitle => 'Create art piece';

  @override
  String get artPieceEditTitle => 'Edit art piece';

  @override
  String get artPieceTitleLabel => 'Title';

  @override
  String get artPieceDescriptionLabel => 'Description';

  @override
  String get artPiecePhotosLabel => 'Photos';

  @override
  String get artPieceArtistLabel => 'Artist';

  @override
  String get artPieceAssetTypeLabel => 'Asset type';

  @override
  String get artPieceAssetImage => 'Image';

  @override
  String get artPieceAssetModel3d => '3D model';

  @override
  String get artPieceAssetSectionTitle => 'Production asset';

  @override
  String get artPieceUploadAssetAction => 'Upload 3D model';

  @override
  String get artPieceDownloadAssetAction => 'Download file';

  @override
  String get artPieceAssetHelp =>
      'Upload the 3D model used as the production asset for this artwork.';

  @override
  String get artPieceAssetEmptyState => 'No 3D model uploaded yet.';

  @override
  String artPieceAssetContentType(Object value) {
    return 'File type: $value';
  }

  @override
  String artPieceAssetSize(Object value) {
    return 'File size: $value';
  }

  @override
  String get artPieceModelAssetRequiredError =>
      'A model upload is required for 3D artworks.';

  @override
  String artPieceAssetDownloadStarted(Object fileName) {
    return 'Started download for $fileName.';
  }

  @override
  String get artPieceAssetDownloadFailed =>
      'The production asset could not be downloaded.';

  @override
  String get artPieceUploadPhotosAction => 'Add photos';

  @override
  String get artPiecePhotosHelp =>
      'Select local image files. Existing photos stay attached until you remove them.';

  @override
  String get artPiecePhotosEmptyState => 'No photos selected yet.';

  @override
  String get artPieceArtistRequiredError => 'An artist must be selected.';

  @override
  String get artPieceTitleTooShortError =>
      'The title must contain at least 3 characters.';

  @override
  String get artPieceDescriptionTooShortError =>
      'The description must contain at least 20 characters.';

  @override
  String get artPieceDescriptionTooLongError =>
      'The description can contain at most 3000 characters.';

  @override
  String get artPiecePhotosRequiredError => 'At least one photo is required.';

  @override
  String artPiecePhotoCount(Object count) {
    return '$count photos';
  }

  @override
  String get artPieceMetadataSection => 'Metadata';

  @override
  String get artPieceNoSelectionTitle => 'Select an artwork';

  @override
  String get artPieceNoSelectionSubtitle =>
      'Choose an artwork from the list to inspect and manage it.';

  @override
  String artPieceDeleteConfirm(Object title) {
    return 'Delete art piece \"$title\"?';
  }

  @override
  String get commaSeparatedHint => 'Comma separated values';

  @override
  String get dropsLoadFailed => 'Drops could not be loaded.';

  @override
  String get noDropsAvailable => 'No drops available.';

  @override
  String get dropDependenciesMissing =>
      'Art pieces or drop-makers are missing.';

  @override
  String get dropCreateTitle => 'Create drop';

  @override
  String get dropEditTitle => 'Edit drop';

  @override
  String dropDeleteConfirm(Object id) {
    return 'Delete drop $id?';
  }

  @override
  String get dropArtPieceLabel => 'Art piece';

  @override
  String get dropMakerUserLabel => 'Drop-maker';

  @override
  String get dropStationaryLabel => 'Stationary';

  @override
  String get dropPortableItemCountLabel => 'Portable item count';

  @override
  String get dropLatitudeLabel => 'Latitude';

  @override
  String get dropLongitudeLabel => 'Longitude';

  @override
  String get dropLocationPhotosLabel => 'Location photo URLs';

  @override
  String get dropItemCountLabel => 'Items (count)';

  @override
  String get statusPublished => 'Published';

  @override
  String get statusUnpublished => 'Unpublished';

  @override
  String get mapDataLoadFailed => 'Map data could not be loaded.';

  @override
  String get mapNoDrops => 'No drops available.';

  @override
  String get topMenuTooltip => 'Top navigation';

  @override
  String get defaultMainRadiusKm => '30';

  @override
  String get defaultUnclaimedRadiusKm => '3';

  @override
  String mapRadiusLabel(Object radiusKm) {
    return 'Main map radius: $radiusKm km';
  }

  @override
  String mapUnclaimedRadiusLabel(Object radiusKm) {
    return 'Unclaimed drop radius: $radiusKm km';
  }

  @override
  String mapCenteredOnLatestDrop(Object dropTitle) {
    return 'Map centered on latest drop: $dropTitle';
  }

  @override
  String mapCenterCoordinates(Object latitude, Object longitude) {
    return 'Center: $latitude, $longitude';
  }

  @override
  String get centerOnMyLocation => 'My location';

  @override
  String get mapCenteredOnUser => 'Map centered on your location.';

  @override
  String get locationServiceDisabled => 'Location service is disabled.';

  @override
  String get locationPermissionDenied => 'Location permission was denied.';

  @override
  String get locationError => 'Location could not be resolved.';

  @override
  String get mapSearchLocationHint => 'Search location manually';

  @override
  String get mapSearchNoResults => 'No matching location found.';

  @override
  String get mapSearchError => 'Location suggestions could not be loaded.';

  @override
  String get mapDropDetails => 'Drop details';

  @override
  String get mapShowDropDetailsHint => 'Tap a drop pin to view details.';

  @override
  String get mapArtistLabel => 'Artist';

  @override
  String get mapDropMakerLabel => 'Drop-Maker';

  @override
  String get mapDescriptionLabel => 'Description';

  @override
  String get mapClaimedByLabel => 'Claimed by';

  @override
  String get mapUnclaimedLabel => 'Not claimed yet';

  @override
  String get mapCloseDetails => 'Close';

  @override
  String get mapPlaceholder =>
      'Map preview (OpenStreetMap integration endpoint)';

  @override
  String get searchSortTitle => 'Search and sorting';

  @override
  String get manualLocationLabel => 'Manual location or device location';

  @override
  String get distanceColumnVisible => 'Distance sorting is enabled.';

  @override
  String get sampleDropTitle => 'Neon Fox - East City';

  @override
  String get sampleDropTitleTwo => 'Steel Bird - Riverside';

  @override
  String get sampleDropSubtitle =>
      'Artist + Drop-Maker + mini map + claimed by hunters';

  @override
  String distanceValue(Object value) {
    return '$value km';
  }

  @override
  String get dropDetailTitle => 'Drop details';

  @override
  String get dropDetailLoadFailed => 'Drop details could not be loaded.';

  @override
  String get dropDetailDescriptionSection => 'Description';

  @override
  String get dropDetailLocationSection => 'Location';

  @override
  String get dropDetailItemStatusSection => 'Drop item status';

  @override
  String get dropDetailItemStatusAvailable => 'Available';

  @override
  String dropDetailItemStatusItemLabel(Object index) {
    return 'Item $index';
  }

  @override
  String dropDetailItemStatusClaimedBy(Object name) {
    return 'Claimed by $name';
  }

  @override
  String get dropDetailTechnicalSection => 'Technical data';

  @override
  String get dropDetailDescription =>
      'Description, gallery, maker comment and claim state.';

  @override
  String get claimedHuntersTitle => 'Claimed by hunters';

  @override
  String get claimedHuntersValue => 'HunterOne, HunterTwo';

  @override
  String get claimTitle => 'Claim item';

  @override
  String get claimInstruction =>
      'Scan QR and submit nickname or account claim.';

  @override
  String get nicknameLabel => 'Nickname';

  @override
  String get claimButton => 'Claim now';

  @override
  String get claimLoadError => 'Failed to load claim data.';

  @override
  String get claimMissingToken => 'No QR token is available.';

  @override
  String get claimTokenLabel => 'QR token';

  @override
  String claimAuthenticatedAs(Object name) {
    return 'Claiming as account: $name';
  }

  @override
  String get claimAnonymousHint =>
      'Without sign-in, a unique nickname is required.';

  @override
  String get claimPreviewTitle => 'Art piece';

  @override
  String get claimPreviewItemLabel => 'Item';

  @override
  String get claimAlreadyClaimed => 'This item has already been claimed.';

  @override
  String claimAlreadyClaimedBy(Object name) {
    return 'Already claimed by: $name';
  }

  @override
  String get claimSuccess => 'Item claimed successfully.';

  @override
  String rankEntry(Object rank, Object name) {
    return '#$rank - $name';
  }

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPasswordAction => 'Show password';

  @override
  String get hidePasswordAction => 'Hide password';

  @override
  String get authFillCredentialsHint => 'Enter email and password.';

  @override
  String get authFillRegistrationHint =>
      'Fill in username, email, and password.';

  @override
  String get authRoleManagedAtRegistration =>
      'The current account type is stored on the server. Login never asks for a role selection.';

  @override
  String get authProviderLoginComingSoon =>
      'Provider login is prepared in the product, but not wired into this local screen yet.';

  @override
  String get authProviderLoginHint =>
      'Provider sign-in opens a secure browser window and returns to the app after the external identity has been verified.';

  @override
  String get authProviderRegistrationHint =>
      'Create a linked provider account with the external provider and your desired username. The external identity is resolved in a secure browser window.';

  @override
  String get authProviderLabel => 'Provider';

  @override
  String get authProviderSubjectLabel => 'Provider subject';

  @override
  String get authSelectProviderHint => 'Select a provider';

  @override
  String get authProviderFlowCancelledOrFailed =>
      'Provider authentication was cancelled or failed.';

  @override
  String get authProviderMissingCompletionSession =>
      'The provider callback did not return a completion session.';

  @override
  String get authNoConfiguredProviders =>
      'No authentication providers are currently configured.';

  @override
  String get authMfaTitle => 'Second factor';

  @override
  String get authMfaCodeLabel => 'MFA code';

  @override
  String get authMfaSetupHint =>
      'Scan the QR code in your authenticator app or enter the key manually.';

  @override
  String get authMfaManualKeyLabel => 'Manual key';

  @override
  String get authMfaContinue => 'Confirm MFA';

  @override
  String get authMfaRequired => 'MFA is required for this account.';

  @override
  String get authForgotPasswordAction => 'Forgot password?';

  @override
  String get authForgotPasswordTitle => 'Reset password';

  @override
  String get authForgotPasswordHint =>
      'Enter the email address of your local account. If a matching account exists, we will send a reset link.';

  @override
  String get authForgotPasswordEmailRequired => 'Enter an email address.';

  @override
  String get authForgotPasswordSubmit => 'Request reset link';

  @override
  String get authForgotPasswordSubmitted =>
      'If a matching local account exists, a reset link has been sent.';

  @override
  String get authResetPasswordTitle => 'Set new password';

  @override
  String get authResetPasswordHint =>
      'Enter a new password. The link is only valid for a limited time.';

  @override
  String get authResetPasswordMissingParameters =>
      'The password reset link is incomplete or invalid.';

  @override
  String get authResetPasswordPasswordRequired => 'Enter a new password.';

  @override
  String get authResetPasswordSubmit => 'Set password';

  @override
  String get authResetPasswordSuccess => 'Password has been reset.';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authVerifyEmailTitle => 'Verify email address';

  @override
  String get authVerifyEmailInProgress => 'Verifying email address...';

  @override
  String get authVerifyEmailSuccess =>
      'Email address verified. You can sign in now.';

  @override
  String get authVerifyEmailFailure => 'Email address could not be verified.';

  @override
  String get authVerifyEmailMissingParameters =>
      'The verification link is incomplete or invalid.';

  @override
  String get authHunterRegistrationSuccess =>
      'Hunter account created. Verify your email address with the link we sent before signing in.';

  @override
  String get authApprovalRequestSubmitted =>
      'Account created. Email verification was simulated for local development. Approval is now pending.';

  @override
  String get authHunterProviderRegistrationSuccess =>
      'Hunter provider account created. You can sign in now.';

  @override
  String get authProviderApprovalRequestSubmitted =>
      'Provider account created. Approval is now pending.';

  @override
  String get authHunterSelfServiceHint =>
      'Hunters can register directly and start signing in after verification.';

  @override
  String get authRegistrationStartsAsHunter =>
      'Every self-service registration starts as a hunter account.';

  @override
  String get authRoleApplicationsMoveToProfile =>
      'Artist and drop-maker access can be requested later on the main profile page.';

  @override
  String get authArtistApprovalHint =>
      'Artists can request an account. An admin must approve the account before login is allowed.';

  @override
  String get authDropMakerApprovalHint =>
      'Drop-makers can request an account. An admin must approve the account before login is allowed.';

  @override
  String get authAdminRegistrationManaged =>
      'Admin accounts are never self-registered here. They can only be created or assigned in user management.';

  @override
  String get boolYes => 'Yes';

  @override
  String get boolNo => 'No';

  @override
  String get providerLoginTitle => 'Provider login';

  @override
  String get providerRegisterTitle => 'Provider registration';

  @override
  String get publicAppBaseUrlLabel => 'Public app base URL';

  @override
  String get configLoadError => 'Failed to load configuration.';

  @override
  String get configSaveSuccess => 'Configuration saved.';

  @override
  String get authProviderStatusSectionTitle => 'Authentication providers';

  @override
  String get authProviderStatusEmpty => 'No provider status is available.';

  @override
  String get authProviderStatusEnabled => 'Enabled';

  @override
  String get authProviderStatusDisabled => 'Disabled';

  @override
  String get authProviderStatusVisibleOnLogin => 'Visible on login';

  @override
  String get authProviderStatusHiddenOnLogin => 'Hidden on login';

  @override
  String get authProviderStatusClientIdPresent => 'Client ID set';

  @override
  String get authProviderStatusClientIdMissing => 'Client ID missing';

  @override
  String get authProviderStatusClientSecretPresent => 'Client secret set';

  @override
  String get authProviderStatusClientSecretMissing => 'Client secret missing';

  @override
  String get authProviderStatusPkceEnabled => 'PKCE enabled';

  @override
  String get authProviderStatusPkceDisabled => 'PKCE disabled';

  @override
  String get usernameLabel => 'Username';

  @override
  String get roleHunter => 'Hunter';

  @override
  String get roleArtist => 'Artist';

  @override
  String get roleDropMaker => 'Drop-Maker';

  @override
  String get roleLabel => 'Role';

  @override
  String get registerButton => 'Create account';

  @override
  String get artistArtPiecesTitle => 'Artist: Art Pieces';

  @override
  String get sampleArtPieceTitle => 'Art Piece: Crystal Owl';

  @override
  String get sampleArtPieceSubtitle => 'Images/3D model + publish status';

  @override
  String get artistDropManagerTitle => 'Own drop manager';

  @override
  String get artistDropManagerSubtitle => 'Edit, delete or depublish own drops';

  @override
  String get dropMakerTitle => 'Drop-Maker workspace';

  @override
  String get dropMakerArtPieceSelection => 'Select art piece';

  @override
  String get dropMakerCreateDrop => 'Create drop with location and item amount';

  @override
  String get dropMakerPublishTitle => 'Publish and depublish';

  @override
  String get dropMakerPublishSubtitle => 'Social channels and claim override';

  @override
  String get makeDropWizardTitle => 'Make a Drop Wizard';

  @override
  String get makeDropWizardFabLabel => 'Create drop';

  @override
  String get makeDropStepBrowseTitle => '1. Review artworks';

  @override
  String get makeDropStepBrowseDescription =>
      'Review the available artworks for the new drop.';

  @override
  String get makeDropStepSelectTitle => '2. Select artwork';

  @override
  String get makeDropStepSelectDescription =>
      'Click an artwork that should be used for this drop.';

  @override
  String get makeDropStepDownloadTitle => '3. Download production asset';

  @override
  String get makeDropStepDownloadDescription =>
      'Actually download the stored production asset for the artwork before you continue preparing the drop.';

  @override
  String get makeDropDownloadAction => 'Download production asset';

  @override
  String get makeDropDownloadSet => 'Download step marked as done.';

  @override
  String get makeDropDownloadDone => 'Download step completed.';

  @override
  String get makeDropDownloadUnavailable =>
      'No production asset is available for this artwork.';

  @override
  String get makeDropDownloadFailed =>
      'The production asset download could not be started.';

  @override
  String get makeDropSelectArtFirst => 'Please select an artwork first.';

  @override
  String get makeDropConfirmDownloadFirst =>
      'Please complete the download step first.';

  @override
  String get makeDropStepPrintTitle => '4. Print drop + enter quantity';

  @override
  String get makeDropStepPrintDescription =>
      'Print the production asset, inspect the produced items and confirm production before QR codes are generated.';

  @override
  String get makeDropProductionPrintedLabel =>
      'Drop has been printed and inspected';

  @override
  String get makeDropProductionPrintedDescription =>
      'Confirm this step only after the physical production is complete.';

  @override
  String get makeDropPrintConfirmationRequired =>
      'Please confirm that the drop has been printed and inspected first.';

  @override
  String get makeDropItemCountLabel => 'Item quantity';

  @override
  String get makeDropItemCountInvalid => 'The quantity must be at least 1.';

  @override
  String get makeDropPortableItemCountInvalid =>
      'The portable count must be between 1 and the total quantity.';

  @override
  String get makeDropStepQrTitle => '5. Show QR codes';

  @override
  String get makeDropStepQrDescription =>
      'Once the draft is saved, the real QR tokens from the backend are shown here.';

  @override
  String get makeDropGenerateQrAction => 'Generate QR codes';

  @override
  String get makeDropGenerateQrFirst =>
      'Please save the drop draft first so QR codes can be created.';

  @override
  String get makeDropStepPlaceTitle => '6. Place drop + enter location';

  @override
  String get makeDropStepPlaceDescription =>
      'Place the drop at the captured location, document the spot with photos and confirm placement.';

  @override
  String get makeDropPlacementConfirmedLabel => 'Drop has been placed';

  @override
  String get makeDropPlacementConfirmedDescription =>
      'Confirm this step only after the drop has been physically placed.';

  @override
  String get makeDropPlacementConfirmationRequired =>
      'Please confirm that the drop has been placed first.';

  @override
  String get makeDropLocationLabel => 'Drop location';

  @override
  String get makeDropLocationRequired => 'Please enter a location.';

  @override
  String get makeDropLocationPhotosRequired =>
      'Please add at least one location photo.';

  @override
  String get makeDropMissingCurrentUser =>
      'The signed-in user could not be matched to a drop-maker account.';

  @override
  String get makeDropSourceMediaHint =>
      'Use the stored production asset or reference image from this artwork for manufacturing.';

  @override
  String makeDropDraftSaved(Object count) {
    return 'Drop draft saved. $count QR codes are ready.';
  }

  @override
  String makeDropReadyWithId(Object id) {
    return 'Active draft: $id';
  }

  @override
  String makeDropQrCodeLabel(Object index) {
    return 'QR code $index';
  }

  @override
  String makeDropCoordinatesLabel(Object latitude, Object longitude) {
    return 'Coordinates: $latitude, $longitude';
  }

  @override
  String get makeDropAddLocationPhotos => 'Add location photos';

  @override
  String get makeDropPauseAction => 'Pause';

  @override
  String get makeDropPaused =>
      'Wizard paused. Continue it later from My Drops.';

  @override
  String get makeDropResumeAction => 'Resume wizard';

  @override
  String makeDropPhotosSelected(Object count) {
    return '$count location photos selected';
  }

  @override
  String get makeDropNoLocationPhotos => 'No location photos selected yet.';

  @override
  String get makeDropPublishAfterFinish =>
      'Publish drop immediately after finishing';

  @override
  String get makeDropFinishedPublished => 'Drop saved and published.';

  @override
  String get makeDropWizardFinished =>
      'Wizard completed. The drop draft was saved.';

  @override
  String get makeDropNextAction => 'Next';

  @override
  String get makeDropBackAction => 'Back';

  @override
  String get makeDropFinishAction => 'Finish';

  @override
  String get moderationTitle => 'Moderation queue';

  @override
  String get moderationLoadFailed => 'Moderation reports could not be loaded.';

  @override
  String get moderationActionFailed =>
      'The moderation action could not be completed.';

  @override
  String get moderationRestricted =>
      'This view is only available to artists, drop-makers, moderators, and admins.';

  @override
  String get moderationEmpty => 'There are no reported items right now.';

  @override
  String get moderationCommentSectionTitle => 'Reported comments';

  @override
  String get moderationArtPieceSectionTitle => 'Reported art pieces';

  @override
  String get moderationOpenDropAction => 'Open drop';

  @override
  String get moderationHideCommentAction => 'Hide comment';

  @override
  String get moderationDismissReportAction => 'Dismiss report';

  @override
  String get moderationDepublishArtPieceAction => 'Depublish art piece';

  @override
  String get moderationNoReasonProvided => 'No report reason provided.';

  @override
  String moderationReportedBy(Object value) {
    return 'Reported for: $value';
  }

  @override
  String moderationArtistLabel(Object value) {
    return 'Artist: $value';
  }

  @override
  String moderationReportReason(Object value) {
    return 'Report reason: $value';
  }

  @override
  String moderationReportedAt(Object value) {
    return 'Reported at: $value';
  }

  @override
  String get reportedCommentTitle => 'Reported comment';

  @override
  String get reportedCommentSubtitle => 'Visible until moderation decision';

  @override
  String get reportedArtPieceTitle => 'Reported art piece';

  @override
  String get reportedArtPieceSubtitle => 'Mail alert is generated';

  @override
  String get dropDetailCommentsSection => 'Comments';

  @override
  String get dropDetailCommentsEmpty =>
      'There are no comments for this drop yet.';

  @override
  String get dropDetailCommentComposerTitle => 'Write a comment';

  @override
  String get dropDetailCommentPlaceholder =>
      'Write your comment about this drop.';

  @override
  String get dropDetailCommentSubmit => 'Send comment';

  @override
  String get dropDetailCommentCreated => 'Comment saved.';

  @override
  String get dropDetailCommentCreateFailed => 'Comment could not be saved.';

  @override
  String get dropDetailCommentLoginHint =>
      'Only signed-in hunters, artists, drop-makers, and moderators can post comments.';

  @override
  String get dropDetailReportCommentAction => 'Report comment';

  @override
  String get dropDetailReportArtPieceAction => 'Report art piece';

  @override
  String get dropDetailAlreadyReported => 'Already reported';

  @override
  String get dropDetailReportDialogDescription =>
      'Enter an optional reason for the moderation report.';

  @override
  String get dropDetailReportReasonLabel => 'Report reason';

  @override
  String get dropDetailReportReasonHint =>
      'Why should this content be reviewed?';

  @override
  String get dropDetailSubmitReportAction => 'Report';

  @override
  String get dropDetailReportSubmitted => 'Report saved.';

  @override
  String get dropDetailReportFailed => 'Report could not be saved.';

  @override
  String dropDetailReportReason(Object value) {
    return 'Report reason: $value';
  }

  @override
  String dropDetailReportedAt(Object value) {
    return 'Reported at: $value';
  }

  @override
  String get smtpLabel => 'SMTP host';

  @override
  String get smtpPortLabel => 'SMTP port';

  @override
  String get smtpSecurityModeLabel => 'SMTP security';

  @override
  String get smtpSecurityModeStartTls => 'StartTLS';

  @override
  String get smtpSecurityModeTls => 'TLS';

  @override
  String get smtpUserNameLabel => 'SMTP user name';

  @override
  String get smtpUserEmailLabel => 'SMTP user email';

  @override
  String get smtpPasswordLabel => 'SMTP password';

  @override
  String get smtpPasswordSecretNameLabel => 'SMTP password secret';

  @override
  String get smtpPasswordConfiguredHint =>
      'Production mail sending uses this configured secret.';

  @override
  String get smtpPasswordMissingHint =>
      'Enter a secret reference such as Smtp:Password for production mail sending.';

  @override
  String get smtpPasswordTransientHint =>
      'Used only for the connection test. The password is not stored in the application configuration.';

  @override
  String get smtpTestConnectionButton => 'Test connection';

  @override
  String get smtpTestConnectionHostRequired =>
      'Enter an SMTP host before running the connection test.';

  @override
  String get smtpTestConnectionPortInvalid =>
      'Enter a valid SMTP port between 1 and 65535.';

  @override
  String get smtpTestConnectionCredentialsRequired =>
      'Provide both SMTP user name and SMTP password for authenticated connection tests.';

  @override
  String get mainMapRadiusSetting => 'Main map radius (km)';

  @override
  String get miniMapRadiusSetting => 'Mini-map radius (km)';

  @override
  String get unclaimedRadiusSetting => 'Unclaimed radius (km)';

  @override
  String get showExactPositionSetting =>
      'Show exact position when fully claimed';

  @override
  String get saveButton => 'Save';

  @override
  String userRow(Object email, Object role) {
    return '$email ($role)';
  }

  @override
  String get userRowActions => 'Approve, suspend, edit username/email/role';

  @override
  String get globalArtPieceModerationTitle => 'Global art piece moderation';

  @override
  String get globalArtPieceModerationSubtitle =>
      'Edit, delete, publish and depublish';

  @override
  String get globalDropModerationTitle => 'Global drop moderation';

  @override
  String get globalDropModerationSubtitle =>
      'Edit, delete, publish and depublish';

  @override
  String get userEditProfileTitle => 'Edit user profile';

  @override
  String get userEditProfileAction => 'Edit profile';

  @override
  String userRoleApplicationPending(Object role) {
    return 'Pending role application: $role';
  }

  @override
  String get userApproveRoleApplicationAction => 'Approve role application';

  @override
  String get userRejectRoleApplicationAction => 'Reject role application';

  @override
  String get artPieceSubtitleLabel => 'Subtitle';

  @override
  String get artPieceSubtitleTooLongError =>
      'Subtitle must not exceed 200 characters.';

  @override
  String get dropMakerCommentLabel => 'Drop-maker comment';

  @override
  String get dropMakerCommentHint =>
      'Optional note for production, placement, or context.';

  @override
  String get dropSocialChannelsLabel => 'Social channels';

  @override
  String get dropSocialPublishStatusLabel => 'Social publishing';

  @override
  String get bootstrapAdminTitle => 'Bootstrap admin';

  @override
  String get bootstrapAdminLoginHint =>
      'No admin account exists yet. Create the first administrator before continuing.';

  @override
  String get bootstrapAdminAction => 'Create first admin';

  @override
  String get bootstrapAdminDescription =>
      'Create the initial administrator for this installation. The account is approved immediately and can configure the system afterwards.';

  @override
  String get bootstrapAdminSuccess =>
      'Initial administrator created. Please sign in to continue.';

  @override
  String get bootstrapAdminUnavailable =>
      'Admin bootstrap is no longer available because an administrator already exists.';

  @override
  String get bootstrapAdminLoadFailed =>
      'Bootstrap status could not be loaded.';
}
