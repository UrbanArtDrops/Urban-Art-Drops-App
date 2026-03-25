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
  String get profileLoadFailed => 'Dein Profil konnte nicht geladen werden.';

  @override
  String profileRoleLabel(Object role) {
    return 'Rolle: $role';
  }

  @override
  String get profileContactSectionTitle => 'Kontodaten';

  @override
  String get profileDisplayNameLabel => 'Anzeigename';

  @override
  String get profileImageSectionTitle => 'Profilbild';

  @override
  String get profileImageHint =>
      'Lade ein Profilbild hoch, nimm ein Selfie auf oder entferne das aktuelle Bild. Die Aenderung wird mit dem Profilformular gespeichert.';

  @override
  String get profileImageUploadAction => 'Bild hochladen';

  @override
  String get profileImageSelfieAction => 'Selfie aufnehmen';

  @override
  String get profileImageRemoveAction => 'Bild entfernen';

  @override
  String get profileImagePickerFailed =>
      'Das ausgewaehlte Profilbild konnte nicht geladen werden.';

  @override
  String get profileImageSelfieFailed =>
      'Das Selfie konnte nicht aufgenommen werden.';

  @override
  String get profileLocalAccountChip => 'Lokales Konto';

  @override
  String get profileProviderAccountChip => 'Provider-Konto';

  @override
  String get profileSaveSuccess => 'Profil gespeichert.';

  @override
  String get profileMfaSectionTitle => 'Multi-Faktor-Authentifizierung';

  @override
  String get profileMfaEnabled => 'MFA aktiv';

  @override
  String get profileMfaDisabled => 'MFA nicht aktiv';

  @override
  String get profileRoleApplicationSectionTitle => 'Rollenbewerbungen';

  @override
  String get profileRoleApplicationHint =>
      'Hunter-Konten koennen hier Artist- oder Drop-Maker-Zugriff beantragen.';

  @override
  String profileRoleApplicationPending(Object role) {
    return 'Ausstehende Rollenbewerbung: $role';
  }

  @override
  String profileRoleApplicationRequestedAt(Object timestamp) {
    return 'Beantragt am: $timestamp';
  }

  @override
  String get profileRoleApplicationSubmitted =>
      'Die Rollenbewerbung wurde eingereicht.';

  @override
  String get profileRoleApplicationNotAvailableForCurrentRole =>
      'Rollenbewerbungen stehen nur fuer Hunter-Konten zur Verfuegung.';

  @override
  String get profileApplyArtistAction => 'Als Artist bewerben';

  @override
  String get profileApplyDropMakerAction => 'Als Drop-Maker bewerben';

  @override
  String get profileMfaRequiredByPolicy =>
      'Diese Rolle verlangt eine app-basierte MFA.';

  @override
  String get profileMfaOptionalHint =>
      'Du kannst fuer dieses Konto eine app-basierte MFA aktivieren.';

  @override
  String get profileMfaSetupAction => 'MFA einrichten';

  @override
  String get profileMfaReconfigureAction => 'MFA neu einrichten';

  @override
  String get profileMfaDisableAction => 'MFA deaktivieren';

  @override
  String get profileMfaDisableHint =>
      'Gib einen aktuellen MFA-Code ein, um den konfigurierten Authenticator zu deaktivieren.';

  @override
  String get profileMfaCodeRequired => 'Bitte den aktuellen MFA-Code eingeben.';

  @override
  String get profileMfaSetupSuccess => 'MFA wurde eingerichtet.';

  @override
  String get profileMfaDisableSuccess => 'MFA wurde deaktiviert.';

  @override
  String get profileNotificationsSectionTitle => 'Benachrichtigungen';

  @override
  String get profileNotificationsEmpty =>
      'Es liegen noch keine Benachrichtigungen vor.';

  @override
  String get profileNotificationsLoadFailed =>
      'Benachrichtigungen konnten nicht geladen werden.';

  @override
  String get profileNotificationMarkReadAction => 'Als gelesen markieren';

  @override
  String get profileNotificationReadState => 'Gelesen';

  @override
  String get profileNotificationUnreadState => 'Ungelesen';

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
  String get detailsAction => 'Details';

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
  String get artPiecePhotosLabel => 'Fotos';

  @override
  String get artPieceArtistLabel => 'Artist';

  @override
  String get artPieceAssetTypeLabel => 'Asset-Typ';

  @override
  String get artPieceAssetImage => 'Bild';

  @override
  String get artPieceAssetModel3d => '3D-Modell';

  @override
  String get artPieceAssetSectionTitle => 'Produktionsdatei';

  @override
  String get artPieceUploadAssetAction => '3D-Modell hochladen';

  @override
  String get artPieceDownloadAssetAction => 'Datei herunterladen';

  @override
  String get artPieceAssetHelp =>
      'Lade das 3D-Modell als Produktionsdatei fuer dieses Kunstwerk hoch.';

  @override
  String get artPieceAssetEmptyState => 'Noch kein 3D-Modell hochgeladen.';

  @override
  String artPieceAssetContentType(Object value) {
    return 'Dateityp: $value';
  }

  @override
  String artPieceAssetSize(Object value) {
    return 'Dateigroesse: $value';
  }

  @override
  String get artPieceModelAssetRequiredError =>
      'Fuer 3D-Kunstwerke ist ein Modell-Upload erforderlich.';

  @override
  String artPieceAssetDownloadStarted(Object fileName) {
    return 'Download fuer $fileName gestartet.';
  }

  @override
  String get artPieceAssetDownloadFailed =>
      'Die Produktionsdatei konnte nicht heruntergeladen werden.';

  @override
  String get artPieceUploadPhotosAction => 'Fotos hinzufügen';

  @override
  String get artPiecePhotosHelp =>
      'Lokale Bilddateien auswählen. Bereits vorhandene Fotos bleiben erhalten, bis du sie entfernst.';

  @override
  String get artPiecePhotosEmptyState => 'Noch keine Fotos ausgewählt.';

  @override
  String get artPieceArtistRequiredError =>
      'Es muss ein Artist ausgewählt werden.';

  @override
  String get artPieceTitleTooShortError =>
      'Der Titel muss mindestens 3 Zeichen enthalten.';

  @override
  String get artPieceDescriptionTooShortError =>
      'Die Beschreibung muss mindestens 20 Zeichen enthalten.';

  @override
  String get artPieceDescriptionTooLongError =>
      'Die Beschreibung darf höchstens 3000 Zeichen enthalten.';

  @override
  String get artPiecePhotosRequiredError =>
      'Mindestens ein Foto ist erforderlich.';

  @override
  String artPiecePhotoCount(Object count) {
    return '$count Fotos';
  }

  @override
  String get artPieceMetadataSection => 'Metadaten';

  @override
  String get artPieceNoSelectionTitle => 'Kunstwerk auswählen';

  @override
  String get artPieceNoSelectionSubtitle =>
      'Wähle ein Kunstwerk aus der Liste, um es anzusehen und zu verwalten.';

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
      'Artist + Drop-Maker + Mini-Karte + beansprucht durch Hunter';

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
  String get dropDetailItemStatusSection => 'Status der Drop-Gegenstände';

  @override
  String get dropDetailItemStatusAvailable => 'Verfügbar';

  @override
  String dropDetailItemStatusItemLabel(Object index) {
    return 'Gegenstand $index';
  }

  @override
  String dropDetailItemStatusClaimedBy(Object name) {
    return 'Beansprucht von $name';
  }

  @override
  String get dropDetailTechnicalSection => 'Technische Daten';

  @override
  String get dropDetailDescription =>
      'Beschreibung, Galerie, Maker-Kommentar und Claim-Status.';

  @override
  String get claimedHuntersTitle => 'Beansprucht durch Hunter';

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
  String get claimLoadError => 'Claim-Daten konnten nicht geladen werden.';

  @override
  String get claimMissingToken => 'Kein QR-Token vorhanden.';

  @override
  String get claimTokenLabel => 'QR-Token';

  @override
  String claimAuthenticatedAs(Object name) {
    return 'Beansprucht als Konto: $name';
  }

  @override
  String get claimAnonymousHint =>
      'Ohne Anmeldung wird ein eindeutiger Nickname benoetigt.';

  @override
  String get claimPreviewTitle => 'Kunstwerk';

  @override
  String get claimPreviewItemLabel => 'Gegenstand';

  @override
  String get claimAlreadyClaimed =>
      'Dieser Gegenstand wurde bereits beansprucht.';

  @override
  String claimAlreadyClaimedBy(Object name) {
    return 'Bereits beansprucht von: $name';
  }

  @override
  String get claimSuccess => 'Gegenstand erfolgreich beansprucht.';

  @override
  String rankEntry(Object rank, Object name) {
    return '#$rank - $name';
  }

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get authFillCredentialsHint => 'Bitte E-Mail und Passwort eingeben.';

  @override
  String get authFillRegistrationHint =>
      'Bitte Benutzername, E-Mail und Passwort ausfuellen.';

  @override
  String get authRoleManagedAtRegistration =>
      'Der aktuelle Account-Typ ist serverseitig gespeichert. Beim Login wird keine Rolle ausgewaehlt.';

  @override
  String get authProviderLoginComingSoon =>
      'Provider-Anmeldung ist fachlich vorgesehen, aber in diesem lokalen Screen noch nicht verdrahtet.';

  @override
  String get authProviderLoginHint =>
      'Die Provider-Anmeldung oeffnet ein sicheres Browserfenster und kehrt nach der externen Identitaetspruefung in die App zurueck.';

  @override
  String get authProviderRegistrationHint =>
      'Lege ein verknuepftes Provider-Konto mit Provider und gewuenschtem Benutzernamen an. Die externe Identitaet wird in einem sicheren Browserfenster aufgeloest.';

  @override
  String get authProviderLabel => 'Provider';

  @override
  String get authProviderSubjectLabel => 'Provider-Subject';

  @override
  String get authSelectProviderHint => 'Provider auswaehlen';

  @override
  String get authProviderFlowCancelledOrFailed =>
      'Die Provider-Anmeldung wurde abgebrochen oder ist fehlgeschlagen.';

  @override
  String get authProviderMissingCompletionSession =>
      'Der Provider-Callback hat keine Abschluss-Session zurueckgegeben.';

  @override
  String get authNoConfiguredProviders =>
      'Aktuell ist kein Auth-Provider konfiguriert.';

  @override
  String get authMfaTitle => 'Zweiter Faktor';

  @override
  String get authMfaCodeLabel => 'MFA-Code';

  @override
  String get authMfaSetupHint =>
      'Scanne den QR-Code in deiner Authenticator-App oder trage den Schluessel manuell ein.';

  @override
  String get authMfaManualKeyLabel => 'Manueller Schluessel';

  @override
  String get authMfaContinue => 'MFA bestaetigen';

  @override
  String get authMfaRequired => 'MFA ist fuer dieses Konto erforderlich.';

  @override
  String get authHunterRegistrationSuccess =>
      'Hunter-Konto erstellt. Die Verifikation wurde fuer die lokale Entwicklung simuliert. Du kannst dich jetzt anmelden.';

  @override
  String get authApprovalRequestSubmitted =>
      'Konto erstellt. Die Verifikation wurde fuer die lokale Entwicklung simuliert. Die Freigabe ist jetzt ausstehend.';

  @override
  String get authHunterProviderRegistrationSuccess =>
      'Hunter-Provider-Konto erstellt. Du kannst dich jetzt anmelden.';

  @override
  String get authProviderApprovalRequestSubmitted =>
      'Provider-Konto erstellt. Die Freigabe ist jetzt ausstehend.';

  @override
  String get authHunterSelfServiceHint =>
      'Hunter koennen sich selbst registrieren und sich nach der Verifikation direkt anmelden.';

  @override
  String get authRegistrationStartsAsHunter =>
      'Jede Self-Service-Registrierung startet immer als Hunter-Konto.';

  @override
  String get authRoleApplicationsMoveToProfile =>
      'Artist- und Drop-Maker-Zugriff werden spaeter auf der Hauptprofilseite beantragt.';

  @override
  String get authArtistApprovalHint =>
      'Artists koennen eine Freigabe anfordern. Ein Admin muss das Konto vor dem Login freigeben.';

  @override
  String get authDropMakerApprovalHint =>
      'Drop-Maker koennen eine Freigabe anfordern. Ein Admin muss das Konto vor dem Login freigeben.';

  @override
  String get authAdminRegistrationManaged =>
      'Admin-Konten werden hier nie selbst registriert. Sie duerfen nur in der Benutzerverwaltung erstellt oder zugewiesen werden.';

  @override
  String get boolYes => 'Ja';

  @override
  String get boolNo => 'Nein';

  @override
  String get providerLoginTitle => 'Provider-Anmeldung';

  @override
  String get providerRegisterTitle => 'Provider-Registrierung';

  @override
  String get publicAppBaseUrlLabel => 'Oeffentliche App-Basis-URL';

  @override
  String get configLoadError => 'Konfiguration konnte nicht geladen werden.';

  @override
  String get configSaveSuccess => 'Konfiguration gespeichert.';

  @override
  String get authProviderStatusSectionTitle => 'Authentifizierungs-Provider';

  @override
  String get authProviderStatusEmpty =>
      'Es ist kein Provider-Status verfuegbar.';

  @override
  String get authProviderStatusEnabled => 'Aktiv';

  @override
  String get authProviderStatusDisabled => 'Deaktiviert';

  @override
  String get authProviderStatusVisibleOnLogin => 'Im Login sichtbar';

  @override
  String get authProviderStatusHiddenOnLogin => 'Im Login verborgen';

  @override
  String get authProviderStatusClientIdPresent => 'Client-ID gesetzt';

  @override
  String get authProviderStatusClientIdMissing => 'Client-ID fehlt';

  @override
  String get authProviderStatusClientSecretPresent => 'Client-Secret gesetzt';

  @override
  String get authProviderStatusClientSecretMissing => 'Client-Secret fehlt';

  @override
  String get authProviderStatusPkceEnabled => 'PKCE aktiv';

  @override
  String get authProviderStatusPkceDisabled => 'PKCE inaktiv';

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
  String get makeDropWizardTitle => 'Make a Drop Wizard';

  @override
  String get makeDropWizardFabLabel => 'Drop erstellen';

  @override
  String get makeDropStepBrowseTitle => '1. Kunstwerke ansehen';

  @override
  String get makeDropStepBrowseDescription =>
      'Sichte die verfügbaren Kunstwerke für den neuen Drop.';

  @override
  String get makeDropStepSelectTitle => '2. Kunstwerk auswählen';

  @override
  String get makeDropStepSelectDescription =>
      'Klicke ein Kunstwerk an, das für den Drop verwendet werden soll.';

  @override
  String get makeDropStepDownloadTitle => '3. Produktionsdatei herunterladen';

  @override
  String get makeDropStepDownloadDescription =>
      'Lade die hinterlegte Produktionsdatei des Kunstwerks tatsaechlich herunter, bevor du den Drop weiter vorbereitest.';

  @override
  String get makeDropDownloadAction => 'Produktionsdatei herunterladen';

  @override
  String get makeDropDownloadSet => 'Download-Schritt als erledigt markiert.';

  @override
  String get makeDropDownloadDone => 'Download-Schritt erledigt.';

  @override
  String get makeDropDownloadUnavailable =>
      'Fuer dieses Kunstwerk ist keine Produktionsdatei verfuegbar.';

  @override
  String get makeDropDownloadFailed =>
      'Die Produktionsdatei konnte nicht gestartet werden.';

  @override
  String get makeDropSelectArtFirst => 'Bitte zuerst ein Kunstwerk auswählen.';

  @override
  String get makeDropConfirmDownloadFirst =>
      'Bitte zuerst den Download-Schritt abschließen.';

  @override
  String get makeDropStepPrintTitle => '4. Drop drucken + Anzahl eingeben';

  @override
  String get makeDropStepPrintDescription =>
      'Drop drucken ist out of scope. Trage hier die Anzahl der Gegenstände ein.';

  @override
  String get makeDropItemCountLabel => 'Anzahl Gegenstände';

  @override
  String get makeDropItemCountInvalid => 'Die Anzahl muss mindestens 1 sein.';

  @override
  String get makeDropPortableItemCountInvalid =>
      'Die mitnehmbare Anzahl muss zwischen 1 und der Gesamtanzahl liegen.';

  @override
  String get makeDropStepQrTitle => '5. QR-Codes anzeigen';

  @override
  String get makeDropStepQrDescription =>
      'Nach dem Speichern des Drafts werden die echten QR-Tokens aus dem Backend angezeigt.';

  @override
  String get makeDropGenerateQrAction => 'QR-Codes generieren';

  @override
  String get makeDropGenerateQrFirst =>
      'Bitte speichere zuerst den Drop-Draft, damit QR-Codes erzeugt werden.';

  @override
  String get makeDropStepPlaceTitle => '6. Drop anbringen + Standort eintragen';

  @override
  String get makeDropStepPlaceDescription =>
      'Drop anbringen ist out of scope. Erfasse danach Standort und Standortfotos des Drops.';

  @override
  String get makeDropLocationLabel => 'Standort des Drops';

  @override
  String get makeDropLocationRequired => 'Bitte den Standort eintragen.';

  @override
  String get makeDropLocationPhotosRequired =>
      'Bitte mindestens ein Standortfoto hinzufügen.';

  @override
  String get makeDropMissingCurrentUser =>
      'Der angemeldete Benutzer konnte keinem Drop-Maker-Konto zugeordnet werden.';

  @override
  String get makeDropSourceMediaHint =>
      'Nutze die hinterlegte Produktionsdatei oder das Referenzbild dieses Kunstwerks fuer die Herstellung.';

  @override
  String makeDropDraftSaved(Object count) {
    return 'Drop-Draft gespeichert. $count QR-Codes wurden vorbereitet.';
  }

  @override
  String makeDropReadyWithId(Object id) {
    return 'Aktiver Draft: $id';
  }

  @override
  String makeDropQrCodeLabel(Object index) {
    return 'QR-Code $index';
  }

  @override
  String makeDropCoordinatesLabel(Object latitude, Object longitude) {
    return 'Koordinaten: $latitude, $longitude';
  }

  @override
  String get makeDropAddLocationPhotos => 'Standortfotos hinzufügen';

  @override
  String get makeDropPauseAction => 'Pausieren';

  @override
  String get makeDropPaused =>
      'Wizard pausiert. Du kannst ihn spaeter in Meine Drops fortsetzen.';

  @override
  String get makeDropResumeAction => 'Wizard fortsetzen';

  @override
  String makeDropPhotosSelected(Object count) {
    return '$count Standortfotos ausgewählt';
  }

  @override
  String get makeDropNoLocationPhotos => 'Noch keine Standortfotos ausgewählt.';

  @override
  String get makeDropPublishAfterFinish =>
      'Drop nach dem Abschluss direkt veröffentlichen';

  @override
  String get makeDropFinishedPublished =>
      'Drop gespeichert und veröffentlicht.';

  @override
  String get makeDropWizardFinished =>
      'Wizard abgeschlossen. Der Drop-Draft wurde gespeichert.';

  @override
  String get makeDropNextAction => 'Weiter';

  @override
  String get makeDropBackAction => 'Zurück';

  @override
  String get makeDropFinishAction => 'Abschließen';

  @override
  String get moderationTitle => 'Moderations-Queue';

  @override
  String get moderationLoadFailed =>
      'Moderationsmeldungen konnten nicht geladen werden.';

  @override
  String get moderationActionFailed =>
      'Die Moderationsaktion konnte nicht ausgeführt werden.';

  @override
  String get moderationRestricted =>
      'Diese Ansicht ist nur für Artists, Drop-Maker, Moderatoren und Admins verfügbar.';

  @override
  String get moderationEmpty =>
      'Es liegen derzeit keine gemeldeten Inhalte vor.';

  @override
  String get moderationCommentSectionTitle => 'Gemeldete Kommentare';

  @override
  String get moderationArtPieceSectionTitle => 'Gemeldete Kunstwerke';

  @override
  String get moderationOpenDropAction => 'Drop öffnen';

  @override
  String get moderationHideCommentAction => 'Kommentar ausblenden';

  @override
  String get moderationDismissReportAction => 'Meldung verwerfen';

  @override
  String get moderationDepublishArtPieceAction => 'Kunstwerk depublizieren';

  @override
  String get moderationNoReasonProvided => 'Kein Meldungsgrund angegeben.';

  @override
  String moderationReportedBy(Object value) {
    return 'Gemeldet für: $value';
  }

  @override
  String moderationArtistLabel(Object value) {
    return 'Artist: $value';
  }

  @override
  String moderationReportReason(Object value) {
    return 'Meldungsgrund: $value';
  }

  @override
  String moderationReportedAt(Object value) {
    return 'Gemeldet am: $value';
  }

  @override
  String get reportedCommentTitle => 'Gemeldeter Kommentar';

  @override
  String get reportedCommentSubtitle => 'Bis zur Entscheidung sichtbar';

  @override
  String get reportedArtPieceTitle => 'Gemeldetes Art Piece';

  @override
  String get reportedArtPieceSubtitle => 'Mail-Alert wird erzeugt';

  @override
  String get dropDetailCommentsSection => 'Kommentare';

  @override
  String get dropDetailCommentsEmpty =>
      'Für diesen Drop gibt es noch keine Kommentare.';

  @override
  String get dropDetailCommentComposerTitle => 'Kommentar verfassen';

  @override
  String get dropDetailCommentPlaceholder =>
      'Schreibe deinen Kommentar zu diesem Drop.';

  @override
  String get dropDetailCommentSubmit => 'Kommentar senden';

  @override
  String get dropDetailCommentCreated => 'Kommentar gespeichert.';

  @override
  String get dropDetailCommentCreateFailed =>
      'Kommentar konnte nicht gespeichert werden.';

  @override
  String get dropDetailCommentLoginHint =>
      'Nur angemeldete Hunter, Artists, Drop-Maker und Moderatoren können Kommentare verfassen.';

  @override
  String get dropDetailReportCommentAction => 'Kommentar melden';

  @override
  String get dropDetailReportArtPieceAction => 'Kunstwerk melden';

  @override
  String get dropDetailAlreadyReported => 'Bereits gemeldet';

  @override
  String get dropDetailReportDialogDescription =>
      'Optionalen Grund für die Moderationsmeldung eingeben.';

  @override
  String get dropDetailReportReasonLabel => 'Meldungsgrund';

  @override
  String get dropDetailReportReasonHint =>
      'Warum soll dieser Inhalt geprüft werden?';

  @override
  String get dropDetailSubmitReportAction => 'Melden';

  @override
  String get dropDetailReportSubmitted => 'Meldung wurde gespeichert.';

  @override
  String get dropDetailReportFailed =>
      'Meldung konnte nicht gespeichert werden.';

  @override
  String dropDetailReportReason(Object value) {
    return 'Meldungsgrund: $value';
  }

  @override
  String dropDetailReportedAt(Object value) {
    return 'Gemeldet am: $value';
  }

  @override
  String get smtpLabel => 'SMTP-Host';

  @override
  String get smtpPortLabel => 'SMTP-Port';

  @override
  String get smtpUserNameLabel => 'SMTP-Benutzername';

  @override
  String get smtpUserEmailLabel => 'SMTP-Benutzer-E-Mail';

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

  @override
  String get userEditProfileTitle => 'Benutzerprofil bearbeiten';

  @override
  String get userEditProfileAction => 'Profil bearbeiten';

  @override
  String userRoleApplicationPending(Object role) {
    return 'Ausstehende Rollenbewerbung: $role';
  }

  @override
  String get userApproveRoleApplicationAction => 'Rollenbewerbung genehmigen';

  @override
  String get userRejectRoleApplicationAction => 'Rollenbewerbung ablehnen';

  @override
  String get artPieceSubtitleLabel => 'Untertitel';

  @override
  String get artPieceSubtitleTooLongError =>
      'Der Untertitel darf maximal 200 Zeichen lang sein.';

  @override
  String get dropMakerCommentLabel => 'Kommentar des Drop-Makers';

  @override
  String get dropMakerCommentHint =>
      'Optionale Notiz für Produktion, Platzierung oder Kontext.';

  @override
  String get dropSocialChannelsLabel => 'Social-Media-Kanäle';

  @override
  String get bootstrapAdminTitle => 'Admin-Bootstrap';

  @override
  String get bootstrapAdminLoginHint =>
      'Es existiert noch kein Admin-Konto. Erstelle zuerst den initialen Administrator.';

  @override
  String get bootstrapAdminAction => 'Ersten Admin erstellen';

  @override
  String get bootstrapAdminDescription =>
      'Erstelle den initialen Administrator für diese Installation. Das Konto wird sofort freigegeben und kann anschließend das System konfigurieren.';

  @override
  String get bootstrapAdminSuccess =>
      'Der initiale Administrator wurde erstellt. Bitte melde dich jetzt an.';

  @override
  String get bootstrapAdminUnavailable =>
      'Der Admin-Bootstrap ist nicht mehr verfügbar, weil bereits ein Administrator existiert.';

  @override
  String get bootstrapAdminLoadFailed =>
      'Der Bootstrap-Status konnte nicht geladen werden.';
}
