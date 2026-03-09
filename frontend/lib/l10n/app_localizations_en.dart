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
  String profileRoleLabel(Object role) {
    return 'Role: $role';
  }

  @override
  String get logoutButton => 'Logout';

  @override
  String get loadingData => 'Loading data...';

  @override
  String get retryButton => 'Retry';

  @override
  String get refreshAction => 'Refresh';

  @override
  String get createAction => 'Create';

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
  String get artPiecePhotosLabel => 'Photo URLs';

  @override
  String get artPieceArtistLabel => 'Artist';

  @override
  String get artPieceAssetTypeLabel => 'Asset type';

  @override
  String get artPieceAssetImage => 'Image';

  @override
  String get artPieceAssetModel3d => '3D model';

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
      'Artist + Drop-Maker + mini map + claimed hunters';

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
  String get dropDetailTechnicalSection => 'Technical data';

  @override
  String get dropDetailDescription =>
      'Description, gallery, maker comment and claim state.';

  @override
  String get claimedHuntersTitle => 'Claimed hunters';

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
  String rankEntry(Object rank, Object name) {
    return '#$rank - $name';
  }

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get boolYes => 'Yes';

  @override
  String get boolNo => 'No';

  @override
  String get providerLoginTitle => 'Provider login';

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
  String get moderationTitle => 'Moderation queue';

  @override
  String get reportedCommentTitle => 'Reported comment';

  @override
  String get reportedCommentSubtitle => 'Visible until moderation decision';

  @override
  String get reportedArtPieceTitle => 'Reported art piece';

  @override
  String get reportedArtPieceSubtitle => 'Mail alert is generated';

  @override
  String get smtpLabel => 'SMTP host';

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
}
