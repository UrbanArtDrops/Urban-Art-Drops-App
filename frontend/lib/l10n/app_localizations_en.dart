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
