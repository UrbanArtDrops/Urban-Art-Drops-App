import "package:flutter_test/flutter_test.dart";
import "package:urban_art_drops_app/features/drop_maker/domain/make_drop_wizard_draft.dart";
import "package:urban_art_drops_app/shared/models/app_models.dart";

void main() {
  test("validateCreationStep rejects incomplete non-stationary drafts", () {
    final draft = MakeDropWizardDraft.initial().copyWith(
      isStationary: false,
      itemCount: 0,
      portableItemCount: 4,
    );

    final errors = draft.validateCreationStep();

    expect(
      errors,
      contains(MakeDropWizardDraftValidationError.missingArtPiece),
    );
    expect(
      errors,
      contains(MakeDropWizardDraftValidationError.missingDropMaker),
    );
    expect(
      errors,
      contains(MakeDropWizardDraftValidationError.invalidItemCount),
    );
    expect(
      errors,
      contains(MakeDropWizardDraftValidationError.invalidPortableItemCount),
    );
  });

  test("toCreateInput clears portable count for stationary drops", () {
    final draft = MakeDropWizardDraft.initial(
      artPieceId: "art-1",
      dropMakerId: "maker-1",
    ).copyWith(itemCount: 3, isStationary: true, portableItemCount: 2);

    final input = draft.toCreateInput();

    expect(input.artPieceId, "art-1");
    expect(input.dropMakerId, "maker-1");
    expect(input.isStationary, isTrue);
    expect(input.portableItemCount, isNull);
    expect(input.itemCount, 3);
  });

  test("validatePlacementStep requires coordinates and location photos", () {
    final draft = MakeDropWizardDraft.initial(
      artPieceId: "art-1",
      dropMakerId: "maker-1",
    );

    final errors = draft.validatePlacementStep();

    expect(
      errors,
      contains(MakeDropWizardDraftValidationError.missingLocation),
    );
    expect(
      errors,
      contains(MakeDropWizardDraftValidationError.missingLocationPhotos),
    );
  });

  test("withPersistedDrop exposes backend-generated qr tokens", () {
    const drop = DropModel(
      id: "drop-1",
      artPieceId: "art-1",
      dropMakerId: "maker-1",
      isStationary: true,
      portableItemCount: null,
      latitude: null,
      longitude: null,
      isPublished: false,
      locationPhotoUrls: [],
      itemCount: 2,
      claimedItemCount: 0,
      items: [
        DropItemModel(
          id: "item-1",
          qrToken: "token-1",
          isClaimed: false,
          claimedByUserId: null,
          claimedByAnonymousNickname: null,
          claimedAtUtc: null,
        ),
        DropItemModel(
          id: "item-2",
          qrToken: "token-2",
          isClaimed: false,
          claimedByUserId: null,
          claimedByAnonymousNickname: null,
          claimedAtUtc: null,
        ),
      ],
    );

    final draft = MakeDropWizardDraft.initial(
      artPieceId: "art-1",
      dropMakerId: "maker-1",
    ).withPersistedDrop(drop);

    expect(draft.hasPersistedDrop, isTrue);
    expect(draft.qrTokens, ["token-1", "token-2"]);
  });
}
