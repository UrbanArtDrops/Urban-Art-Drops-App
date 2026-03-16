import "package:flutter_bloc/flutter_bloc.dart";

enum AppUserRole { hunter, artist, dropMaker, moderator, admin }

class AuthSessionState {
  const AuthSessionState({
    required this.isAuthenticated,
    this.userId,
    this.email,
    this.userName,
    this.role,
  });

  const AuthSessionState.anonymous()
    : isAuthenticated = false,
      userId = null,
      email = null,
      userName = null,
      role = null;

  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? userName;
  final AppUserRole? role;

  String? get displayName {
    final trimmedUserName = userName?.trim();
    if (trimmedUserName != null && trimmedUserName.isNotEmpty) {
      return trimmedUserName;
    }

    final trimmedEmail = email?.trim();
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
      return trimmedEmail;
    }

    return null;
  }

  AuthSessionState authenticated({
    required String userId,
    required String email,
    required String userName,
    required AppUserRole role,
  }) => AuthSessionState(
    isAuthenticated: true,
    userId: userId.trim(),
    email: email.trim(),
    userName: userName.trim(),
    role: role,
  );
}

class AuthSessionCubit extends Cubit<AuthSessionState> {
  AuthSessionCubit() : super(const AuthSessionState.anonymous());

  void signIn({
    required String userId,
    required String email,
    required String userName,
    required AppUserRole role,
  }) {
    emit(
      state.authenticated(
        userId: userId,
        email: email,
        userName: userName.trim().isEmpty ? email : userName,
        role: role,
      ),
    );
  }

  void signOut() => emit(const AuthSessionState.anonymous());
}

AppUserRole? appUserRoleFromApiValue(int? value) {
  switch (value) {
    case 0:
      return AppUserRole.hunter;
    case 1:
      return AppUserRole.artist;
    case 2:
      return AppUserRole.dropMaker;
    case 3:
      return AppUserRole.moderator;
    case 4:
      return AppUserRole.admin;
    default:
      return null;
  }
}
