import "package:flutter_bloc/flutter_bloc.dart";

enum AppUserRole { hunter, artist, dropMaker, moderator, admin }

class AuthSessionState {
  const AuthSessionState({
    required this.isAuthenticated,
    this.role,
    this.displayName,
  });

  const AuthSessionState.anonymous()
    : isAuthenticated = false,
      role = null,
      displayName = null;

  final bool isAuthenticated;
  final AppUserRole? role;
  final String? displayName;

  AuthSessionState authenticated({
    required AppUserRole role,
    required String displayName,
  }) => AuthSessionState(
    isAuthenticated: true,
    role: role,
    displayName: displayName,
  );
}

class AuthSessionCubit extends Cubit<AuthSessionState> {
  AuthSessionCubit() : super(const AuthSessionState.anonymous());

  void signIn({required AppUserRole role, required String displayName}) {
    emit(
      state.authenticated(
        role: role,
        displayName: displayName.trim().isEmpty ? "User" : displayName.trim(),
      ),
    );
  }

  void signOut() => emit(const AuthSessionState.anonymous());
}
