import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "package:urban_art_drops_app/app/app.dart";
import "package:urban_art_drops_app/app/router/app_router.dart";
import "package:urban_art_drops_app/features/admin/presentation/pages/admin_configuration_page.dart";
import "package:urban_art_drops_app/features/artist_area/presentation/pages/artist_art_pieces_page.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/features/authentication/presentation/pages/login_page.dart";
import "package:urban_art_drops_app/features/navigation/presentation/bloc/navigation_cubit.dart";
import "package:urban_art_drops_app/features/drop_maker/presentation/pages/drop_maker_page.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

void main() {
  testWidgets("renders app shell", (tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => NavigationCubit()),
          BlocProvider(create: (_) => AuthSessionCubit()),
        ],
        child: const UrbanArtDropsApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });

  testWidgets("redirects unauthenticated admin routes to login", (
    tester,
  ) async {
    final authSessionCubit = AuthSessionCubit();
    final router = createAppRouter(authSessionCubit);

    await tester.pumpWidget(
      BlocProvider.value(
        value: authSessionCubit,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    router.go("/admin/configuration");
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets("allows authenticated admins to open admin routes", (
    tester,
  ) async {
    final authSessionCubit = AuthSessionCubit();
    authSessionCubit.signIn(
      userId: "admin-1",
      email: "admin@example.com",
      userName: "admin",
      role: AppUserRole.admin,
      accessToken: "admin-token",
      accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 17, 18),
    );
    final router = createAppRouter(authSessionCubit);

    await tester.pumpWidget(
      BlocProvider.value(
        value: authSessionCubit,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    router.go("/admin/configuration");
    await tester.pumpAndSettle();

    expect(find.byType(AdminConfigurationPage), findsOneWidget);
  });

  testWidgets("allows authenticated admins to open the art pieces manager", (
    tester,
  ) async {
    final authSessionCubit = AuthSessionCubit();
    authSessionCubit.signIn(
      userId: "admin-1",
      email: "admin@example.com",
      userName: "admin",
      role: AppUserRole.admin,
      accessToken: "admin-token",
      accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 17, 18),
    );
    final router = createAppRouter(authSessionCubit);

    await tester.pumpWidget(
      BlocProvider.value(
        value: authSessionCubit,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    router.go("/artist/art-pieces");
    await tester.pumpAndSettle();

    expect(find.byType(ArtistArtPiecesPage), findsOneWidget);
  });

  testWidgets("allows moderators to open the published artworks page", (
    tester,
  ) async {
    final authSessionCubit = AuthSessionCubit();
    authSessionCubit.signIn(
      userId: "moderator-1",
      email: "moderator@example.com",
      userName: "moderator",
      role: AppUserRole.moderator,
      accessToken: "moderator-token",
      accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 17, 18),
    );
    final router = createAppRouter(authSessionCubit);

    await tester.pumpWidget(
      BlocProvider.value(
        value: authSessionCubit,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    router.go("/drop-maker/art-pieces");
    await tester.pumpAndSettle();

    expect(find.byType(DropMakerPage), findsOneWidget);
  });
}
