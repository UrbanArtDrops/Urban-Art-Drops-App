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
    expect(
      errors,
      contains(MakeDropWizardDraftValidationError.missingPrintConfirmation),
    );
  });

  test("toCreateInput clears portable count for stationary drops", () {
    final draft =
        MakeDropWizardDraft.initial(
          artPieceId: "art-1",
          dropMakerId: "maker-1",
        ).copyWith(
          itemCount: 3,
          isStationary: true,
          portableItemCount: 2,
          productionPrinted: true,
        );

    final input = draft.toCreateInput();

    expect(input.artPieceId, "art-1");
    expect(input.dropMakerId, "maker-1");
    expect(input.isStationary, isTrue);
    expect(input.portableItemCount, isNull);
    expect(input.itemCount, 3);
    expect(input.productionPrinted, isTrue);
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
    expect(
      errors,
      contains(MakeDropWizardDraftValidationError.missingPlacementConfirmation),
    );
  });

  test("withPersistedDrop exposes backend-generated qr tokens", () {
    const drop = DropModel(
      id: "drop-1",
      artPieceId: "art-1",
      dropMakerId: "maker-1",
      isStationary: true,
      portableItemCount: null,
      dropMakerComment: "Hide near the east entrance.",
      socialChannels: ["Instagram"],
      productionPrinted: true,
      placementConfirmed: false,
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
          claimUrl: "https://example.com/hunter/claim?token=token-1",
          isClaimed: false,
          claimedByUserId: null,
          claimedByAnonymousNickname: null,
          claimedAtUtc: null,
        ),
        DropItemModel(
          id: "item-2",
          qrToken: "token-2",
          claimUrl: "https://example.com/hunter/claim?token=token-2",
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
    expect(draft.dropMakerComment, "Hide near the east entrance.");
    expect(draft.socialChannels, ["Instagram"]);
    expect(draft.productionPrinted, isTrue);
    expect(draft.placementConfirmed, isFalse);
    expect(draft.qrTokens, ["token-1", "token-2"]);
  });

  test("fromPersistedDrop restores paused qr stage drafts", () {
    const drop = DropModel(
      id: "drop-2",
      artPieceId: "art-9",
      dropMakerId: "maker-9",
      isStationary: false,
      portableItemCount: 2,
      dropMakerComment: "Place after sunset.",
      socialChannels: ["Facebook", "TikTok"],
      productionPrinted: true,
      placementConfirmed: false,
      latitude: null,
      longitude: null,
      isPublished: false,
      locationPhotoUrls: [],
      itemCount: 3,
      claimedItemCount: 0,
      items: [
        DropItemModel(
          id: "item-1",
          qrToken: "token-1",
          claimUrl: "https://example.com/hunter/claim?token=token-1",
          isClaimed: false,
          claimedByUserId: null,
          claimedByAnonymousNickname: null,
          claimedAtUtc: null,
        ),
      ],
    );

    final draft = MakeDropWizardDraft.fromPersistedDrop(drop);

    expect(draft.dropId, "drop-2");
    expect(draft.artPieceId, "art-9");
    expect(draft.dropMakerId, "maker-9");
    expect(draft.isStationary, isFalse);
    expect(draft.portableItemCount, 2);
    expect(draft.dropMakerComment, "Place after sunset.");
    expect(draft.socialChannels, ["Facebook", "TikTok"]);
    expect(draft.productionPrinted, isTrue);
    expect(draft.placementConfirmed, isFalse);
    expect(draft.itemCount, 3);
    expect(draft.qrTokens, ["token-1"]);
    expect(draft.resumeStepIndex, 4);
  });

  test("resumeStepIndex advances to placement for partially placed drops", () {
    const drop = DropModel(
      id: "drop-3",
      artPieceId: "art-9",
      dropMakerId: "maker-9",
      isStationary: true,
      portableItemCount: null,
      dropMakerComment: null,
      socialChannels: [],
      productionPrinted: true,
      placementConfirmed: true,
      latitude: 50.1,
      longitude: 8.6,
      isPublished: false,
      locationPhotoUrls: ["https://example.com/location.png"],
      itemCount: 1,
      claimedItemCount: 0,
      items: [
        DropItemModel(
          id: "item-1",
          qrToken: "token-1",
          claimUrl: "https://example.com/hunter/claim?token=token-1",
          isClaimed: false,
          claimedByUserId: null,
          claimedByAnonymousNickname: null,
          claimedAtUtc: null,
        ),
      ],
    );

    expect(MakeDropWizardDraft.fromPersistedDrop(drop).resumeStepIndex, 5);
  });
}
