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
  String get navLogin => 'Anmeldung';

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
