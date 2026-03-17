import "package:flutter_test/flutter_test.dart";
import "package:urban_art_drops_app/features/authentication/application/auth_session_storage.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";

void main() {
  test("signIn stores backend identity instead of UI-selected role", () {
    final cubit = AuthSessionCubit(storage: InMemoryAuthSessionStorage());

    cubit.signIn(
      userId: "user-1",
      email: "hunter@example.com",
      userName: "hunter.one",
      role: AppUserRole.hunter,
      accessToken: "token-1",
      accessTokenExpiresAtUtc: DateTime.utc(2026, 3, 17, 18),
    );

    expect(cubit.state.isAuthenticated, isTrue);
    expect(cubit.state.userId, "user-1");
    expect(cubit.state.email, "hunter@example.com");
    expect(cubit.state.userName, "hunter.one");
    expect(cubit.state.role, AppUserRole.hunter);
    expect(cubit.state.displayName, "hunter.one");
    expect(cubit.state.accessToken, "token-1");
    expect(cubit.state.hasValidAccessToken, isTrue);
  });

  test("hydrate restores a valid persisted session", () async {
    final storage = InMemoryAuthSessionStorage();
    final writer = AuthSessionCubit(storage: storage);
    writer.signIn(
      userId: "user-2",
      email: "artist@example.com",
      userName: "artist.one",
      role: AppUserRole.artist,
      accessToken: "token-2",
      accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 17, 18),
    );

    final reader = AuthSessionCubit(storage: storage);
    await reader.hydrate();

    expect(reader.state.isAuthenticated, isTrue);
    expect(reader.state.userId, "user-2");
    expect(reader.state.role, AppUserRole.artist);
    expect(reader.state.accessToken, "token-2");
  });
}
