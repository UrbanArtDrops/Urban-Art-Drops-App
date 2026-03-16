import "package:flutter_test/flutter_test.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";

void main() {
  test("signIn stores backend identity instead of UI-selected role", () {
    final cubit = AuthSessionCubit();

    cubit.signIn(
      userId: "user-1",
      email: "hunter@example.com",
      userName: "hunter.one",
      role: AppUserRole.hunter,
    );

    expect(cubit.state.isAuthenticated, isTrue);
    expect(cubit.state.userId, "user-1");
    expect(cubit.state.email, "hunter@example.com");
    expect(cubit.state.userName, "hunter.one");
    expect(cubit.state.role, AppUserRole.hunter);
    expect(cubit.state.displayName, "hunter.one");
  });
}
