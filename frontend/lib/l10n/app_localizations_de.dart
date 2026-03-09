// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Urban Art Drops';

  @override
  String get navMap => 'Karte';

  @override
  String get navDrops => 'Drops';

  @override
  String get navLeaderboard => 'Rangliste';

  @override
  String get navLogin => 'Anmelden';

  @override
  String get navRegister => 'Registrierung';

  @override
  String get navArtistArea => 'Artist-Bereich';

  @override
  String get navDropMakerArea => 'Drop-Maker-Bereich';

  @override
  String get navModeration => 'Moderation';

  @override
  String get navAdminConfig => 'Admin-Konfiguration';

  @override
  String get navAdminUsers => 'Admin-Benutzer';

  @override
  String get navAdminContent => 'Admin-Inhalte';

  @override
  String get menuProfile => 'Mein Profil';

  @override
  String get menuMyArt => 'Meine Kunst';

  @override
  String get menuArtWorks => 'Kunstwerke';

  @override
  String get menuMyDrops => 'Meine Drops';

  @override
  String get menuSettings => 'Einstellungen';

  @override
  String get menuUsers => 'Benutzer';

  @override
  String get profileNotLoggedIn => 'Du bist derzeit nicht angemeldet.';

  @override
  String profileRoleLabel(Object role) {
    return 'Rolle: $role';
  }

  @override
  String get logoutButton => 'Abmelden';

  @override
  String get loadingData => 'Daten werden geladen...';

  @override
  String get retryButton => 'Erneut versuchen';

  @override
  String get backAction => 'Zurück';

  @override
  String get refreshAction => 'Aktualisieren';

  @override
  String get createAction => 'Erstellen';

  @override
  String get editAction => 'Bearbeiten';

  @override
  String get deleteAction => 'Löschen';

  @override
  String get publishAction => 'Veröffentlichen';

  @override
  String get depublishAction => 'Depublizieren';

  @override
  String get cancelAction => 'Abbrechen';

  @override
  String get confirmDelete => 'Löschen bestätigen';

  @override
  String get genericSaveError => 'Speichern fehlgeschlagen.';

  @override
  String get searchDropsHint => 'Drops suchen (Titel oder ID)';

  @override
  String get dropListLocationHint => 'Ort oder PLZ eingeben';

  @override
  String dropListSortingByDistance(Object location) {
    return 'Sortierung nach Distanz aktiv: $location';
  }

  @override
  String get dropListLocationUnavailable =>
      'Kein Standort für diesen Drop hinterlegt.';

  @override
  String get dropListLoadFailed => 'Drops konnten nicht geladen werden.';

  @override
  String get dropListEmpty => 'Keine veröffentlichten Drops gefunden.';

  @override
  String get leaderboardLoadFailed => 'Rangliste konnte nicht geladen werden.';

  @override
  String get leaderboardEmpty => 'Noch keine Einträge in der Rangliste.';

  @override
  String leaderboardClaimCount(Object count) {
    return '$count Claims';
  }

  @override
  String get leaderboardNoClaimedDrops =>
      'Keine beanspruchten Drops vorhanden.';

  @override
  String leaderboardDropClaimCount(Object count) {
    return '$count Claims in diesem Drop';
  }

  @override
  String get leaderboardAnonymousFallback => 'Anonym';

  @override
  String claimedItemsValue(Object claimed, Object total) {
    return '$claimed von $total beansprucht';
  }

  @override
  String dropFallbackTitle(Object id) {
    return 'Drop $id';
  }

  @override
  String get usersLoadFailed => 'Benutzer konnten nicht geladen werden.';

  @override
  String get userCreateTitle => 'Benutzer erstellen';

  @override
  String get userEditUsernameTitle => 'Benutzernamen ändern';

  @override
  String get userApproveAction => 'Freigeben';

  @override
  String get userRevokeApprovalAction => 'Freigabe entziehen';

  @override
  String get userSuspendAction => 'Sperren';

  @override
  String get userUnsuspendAction => 'Entsperren';

  @override
  String get userChangeRoleAction => 'Rolle ändern';

  @override
  String get userEditUsernameAction => 'Benutzernamen bearbeiten';

  @override
  String get userApproved => 'Freigegeben';

  @override
  String get userNotApproved => 'Nicht freigegeben';

  @override
  String get userSuspended => 'Gesperrt';

  @override
  String get userActive => 'Aktiv';

  @override
  String get noUsersAvailable => 'Keine Benutzer vorhanden.';

  @override
  String get artPiecesLoadFailed => 'Art Pieces konnten nicht geladen werden.';

  @override
  String get noArtPiecesAvailable => 'Keine Art Pieces vorhanden.';

  @override
  String get noArtistsAvailable => 'Keine Artist-Accounts verfügbar.';

  @override
  String get artPieceCreateTitle => 'Art Piece erstellen';

  @override
  String get artPieceEditTitle => 'Art Piece bearbeiten';

  @override
  String get artPieceTitleLabel => 'Titel';

  @override
  String get artPieceDescriptionLabel => 'Beschreibung';

  @override
  String get artPiecePhotosLabel => 'Foto-URLs';

  @override
  String get artPieceArtistLabel => 'Artist';

  @override
  String get artPieceAssetTypeLabel => 'Asset-Typ';

  @override
  String get artPieceAssetImage => 'Bild';

  @override
  String get artPieceAssetModel3d => '3D-Modell';

  @override
  String artPieceDeleteConfirm(Object title) {
    return 'Art Piece \"$title\" wirklich löschen?';
  }

  @override
  String get commaSeparatedHint => 'Kommagetrennte Werte';

  @override
  String get dropsLoadFailed => 'Drops konnten nicht geladen werden.';

  @override
  String get noDropsAvailable => 'Keine Drops vorhanden.';

  @override
  String get dropDependenciesMissing =>
      'Für die Erstellung fehlen Art Pieces oder Drop-Maker.';

  @override
  String get dropCreateTitle => 'Drop erstellen';

  @override
  String get dropEditTitle => 'Drop bearbeiten';

  @override
  String dropDeleteConfirm(Object id) {
    return 'Drop $id wirklich löschen?';
  }

  @override
  String get dropArtPieceLabel => 'Art Piece';

  @override
  String get dropMakerUserLabel => 'Drop-Maker';

  @override
  String get dropStationaryLabel => 'Stationär';

  @override
  String get dropPortableItemCountLabel => 'Mitnehmbare Anzahl';

  @override
  String get dropLatitudeLabel => 'Breitengrad';

  @override
  String get dropLongitudeLabel => 'Längengrad';

  @override
  String get dropLocationPhotosLabel => 'Standortfoto-URLs';

  @override
  String get dropItemCountLabel => 'Gegenstände (Anzahl)';

  @override
  String get statusPublished => 'Veröffentlicht';

  @override
  String get statusUnpublished => 'Nicht veröffentlicht';

  @override
  String get mapDataLoadFailed => 'Karten-Daten konnten nicht geladen werden.';

  @override
  String get mapNoDrops => 'Keine Drops verfügbar.';

  @override
  String get topMenuTooltip => 'Top-Navigation';

  @override
  String get defaultMainRadiusKm => '30';

  @override
  String get defaultUnclaimedRadiusKm => '3';

  @override
  String mapRadiusLabel(Object radiusKm) {
    return 'Hauptkartenausschnitt: $radiusKm km';
  }

  @override
  String mapUnclaimedRadiusLabel(Object radiusKm) {
    return 'Umkreis für unvollständig beanspruchte Drops: $radiusKm km';
  }

  @override
  String mapCenteredOnLatestDrop(Object dropTitle) {
    return 'Karte zentriert auf neuesten Drop: $dropTitle';
  }

  @override
  String mapCenterCoordinates(Object latitude, Object longitude) {
    return 'Zentrum: $latitude, $longitude';
  }

  @override
  String get centerOnMyLocation => 'Mein Standort';

  @override
  String get mapCenteredOnUser => 'Karte wurde auf deinen Standort zentriert.';

  @override
  String get locationServiceDisabled => 'Standortdienst ist deaktiviert.';

  @override
  String get locationPermissionDenied =>
      'Standortberechtigung wurde nicht erteilt.';

  @override
  String get locationError => 'Standort konnte nicht ermittelt werden.';

  @override
  String get mapSearchLocationHint => 'Ort manuell suchen';

  @override
  String get mapSearchNoResults => 'Kein passender Ort gefunden.';

  @override
  String get mapSearchError => 'Ortsvorschlaege konnten nicht geladen werden.';

  @override
  String get mapDropDetails => 'Drop-Details';

  @override
  String get mapShowDropDetailsHint =>
      'Tippe auf einen Drop-Pin, um Details zu sehen.';

  @override
  String get mapArtistLabel => 'Artist';

  @override
  String get mapDropMakerLabel => 'Drop-Maker';

  @override
  String get mapDescriptionLabel => 'Beschreibung';

  @override
  String get mapClaimedByLabel => 'Beansprucht von';

  @override
  String get mapUnclaimedLabel => 'Noch nicht beansprucht';

  @override
  String get mapCloseDetails => 'Schließen';

  @override
  String get mapPlaceholder => 'Kartenvorschau (OpenStreetMap-Integration)';

  @override
  String get searchSortTitle => 'Suche und Sortierung';

  @override
  String get manualLocationLabel => 'Manueller Ort oder Gerätestandort';

  @override
  String get distanceColumnVisible => 'Distanzsortierung ist aktiviert.';

  @override
  String get sampleDropTitle => 'Neon Fox - Oststadt';

  @override
  String get sampleDropTitleTwo => 'Steel Bird - Uferzone';

  @override
  String get sampleDropSubtitle =>
      'Artist + Drop-Maker + Mini-Karte + beanspruchte Hunter';

  @override
  String distanceValue(Object value) {
    return '$value km';
  }

  @override
  String get dropDetailTitle => 'Drop-Details';

  @override
  String get dropDetailLoadFailed =>
      'Drop-Details konnten nicht geladen werden.';

  @override
  String get dropDetailDescriptionSection => 'Beschreibung';

  @override
  String get dropDetailLocationSection => 'Standort';

  @override
  String get dropDetailTechnicalSection => 'Technische Daten';

  @override
  String get dropDetailDescription =>
      'Beschreibung, Galerie, Maker-Kommentar und Claim-Status.';

  @override
  String get claimedHuntersTitle => 'Beanspruchte Hunter';

  @override
  String get claimedHuntersValue => 'HunterOne, HunterTwo';

  @override
  String get claimTitle => 'Gegenstand beanspruchen';

  @override
  String get claimInstruction =>
      'QR scannen und mit Nickname oder Konto beanspruchen.';

  @override
  String get nicknameLabel => 'Nickname';

  @override
  String get claimButton => 'Jetzt beanspruchen';

  @override
  String rankEntry(Object rank, Object name) {
    return '#$rank - $name';
  }

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get boolYes => 'Ja';

  @override
  String get boolNo => 'Nein';

  @override
  String get providerLoginTitle => 'Provider-Anmeldung';

  @override
  String get usernameLabel => 'Benutzername';

  @override
  String get roleHunter => 'Hunter';

  @override
  String get roleArtist => 'Artist';

  @override
  String get roleDropMaker => 'Drop-Maker';

  @override
  String get roleLabel => 'Rolle';

  @override
  String get registerButton => 'Konto erstellen';

  @override
  String get artistArtPiecesTitle => 'Artist: Art Pieces';

  @override
  String get sampleArtPieceTitle => 'Art Piece: Crystal Owl';

  @override
  String get sampleArtPieceSubtitle =>
      'Bilder/3D-Modell + Veröffentlichungsstatus';

  @override
  String get artistDropManagerTitle => 'Eigener Drop-Manager';

  @override
  String get artistDropManagerSubtitle =>
      'Eigene Drops bearbeiten, löschen, depublizieren';

  @override
  String get dropMakerTitle => 'Drop-Maker-Workspace';

  @override
  String get dropMakerArtPieceSelection => 'Art Piece auswählen';

  @override
  String get dropMakerCreateDrop =>
      'Drop mit Standort und Item-Anzahl erstellen';

  @override
  String get dropMakerPublishTitle => 'Veröffentlichen und depublizieren';

  @override
  String get dropMakerPublishSubtitle => 'Social-Kanäle und Claim-Override';

  @override
  String get moderationTitle => 'Moderations-Queue';

  @override
  String get reportedCommentTitle => 'Gemeldeter Kommentar';

  @override
  String get reportedCommentSubtitle => 'Bis zur Entscheidung sichtbar';

  @override
  String get reportedArtPieceTitle => 'Gemeldetes Art Piece';

  @override
  String get reportedArtPieceSubtitle => 'Mail-Alert wird erzeugt';

  @override
  String get smtpLabel => 'SMTP-Host';

  @override
  String get mainMapRadiusSetting => 'Hauptkartenausschnitt (km)';

  @override
  String get miniMapRadiusSetting => 'Mini-Kartenausschnitt (km)';

  @override
  String get unclaimedRadiusSetting => 'Unclaimed-Umkreis (km)';

  @override
  String get showExactPositionSetting =>
      'Exakte Position bei vollständig beanspruchtem Drop anzeigen';

  @override
  String get saveButton => 'Speichern';

  @override
  String userRow(Object email, Object role) {
    return '$email ($role)';
  }

  @override
  String get userRowActions =>
      'Freigeben, sperren, Benutzername/E-Mail/Rolle bearbeiten';

  @override
  String get globalArtPieceModerationTitle => 'Globale Art-Piece-Moderation';

  @override
  String get globalArtPieceModerationSubtitle =>
      'Bearbeiten, löschen, veröffentlichen, depublizieren';

  @override
  String get globalDropModerationTitle => 'Globale Drop-Moderation';

  @override
  String get globalDropModerationSubtitle =>
      'Bearbeiten, löschen, veröffentlichen, depublizieren';
}
