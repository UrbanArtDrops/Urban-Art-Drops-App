import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/widgets/page_shell.dart";

void main() {
  testWidgets("applies a configured drawer width", (tester) async {
    await tester.pumpWidget(
      _TestHarness(
        child: const PageShell(
          title: "Test",
          drawerWidth: 520,
          body: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final drawer = scaffold.drawer as Drawer;
    expect(drawer.width, 520);
  });

  testWidgets("clamps configured drawer width to viewport space", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _TestHarness(
        child: const PageShell(
          title: "Test",
          drawerWidth: 1000,
          body: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final drawer = scaffold.drawer as Drawer;
    expect(drawer.width, 304);
  });

  testWidgets(
    "shows moderation navigation for artist, drop-maker, moderator and admin",
    (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          key: const ValueKey("artist"),
          role: AppUserRole.artist,
          child: const PageShell(title: "Test", body: SizedBox.shrink()),
        ),
      );
      expect(_drawerTitles(tester), contains("Moderation"));

      await tester.pumpWidget(
        _TestHarness(
          key: const ValueKey("dropmaker"),
          role: AppUserRole.dropMaker,
          child: const PageShell(title: "Test", body: SizedBox.shrink()),
        ),
      );
      expect(_drawerTitles(tester), contains("Moderation"));

      await tester.pumpWidget(
        _TestHarness(
          key: const ValueKey("moderator"),
          role: AppUserRole.moderator,
          child: const PageShell(title: "Test", body: SizedBox.shrink()),
        ),
      );
      expect(_drawerTitles(tester), contains("Moderation"));

      await tester.pumpWidget(
        _TestHarness(
          key: const ValueKey("admin"),
          role: AppUserRole.admin,
          child: const PageShell(title: "Test", body: SizedBox.shrink()),
        ),
      );
      expect(_drawerTitles(tester), contains("Moderation"));
    },
  );

  testWidgets("shows artworks navigation for admins", (tester) async {
    await tester.pumpWidget(
      _TestHarness(
        role: AppUserRole.admin,
        child: const PageShell(title: "Test", body: SizedBox.shrink()),
      ),
    );

    expect(_drawerTitles(tester), contains("Artworks"));
  });

  testWidgets("shows my drops navigation for admins", (tester) async {
    await tester.pumpWidget(
      _TestHarness(
        role: AppUserRole.admin,
        child: const PageShell(title: "Test", body: SizedBox.shrink()),
      ),
    );

    expect(_drawerTitles(tester), contains("My drops"));
  });

  testWidgets(
    "shows logout and hides login/register when the user is authenticated",
    (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          role: AppUserRole.hunter,
          child: const PageShell(title: "Test", body: SizedBox.shrink()),
        ),
      );

      final titles = _drawerTitles(tester);
      expect(titles, contains("Logout"));
      expect(titles, isNot(contains("Login")));
      expect(titles, isNot(contains("Register")));
    },
  );

  testWidgets(
    "shows login/register and hides logout when the user is anonymous",
    (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          child: const PageShell(title: "Test", body: SizedBox.shrink()),
        ),
      );

      final titles = _drawerTitles(tester);
      expect(titles, contains("Login"));
      expect(titles, contains("Register"));
      expect(titles, isNot(contains("Logout")));
    },
  );
}

class _TestHarness extends StatelessWidget {
  const _TestHarness({required this.child, this.role, super.key});

  final Widget child;
  final AppUserRole? role;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [GoRoute(path: "/", builder: (context, state) => child)],
    );

    return BlocProvider(
      create: (_) {
        final cubit = AuthSessionCubit();
        if (role != null) {
          cubit.signIn(
            userId: "user-1",
            email: "user@example.com",
            userName: "Test User",
            role: role!,
            accessToken: "token",
            accessTokenExpiresAtUtc: DateTime.utc(2026, 3, 17, 18),
          );
        }
        return cubit;
      },
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}

List<String> _drawerTitles(WidgetTester tester) {
  final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
  final drawer = scaffold.drawer as Drawer;
  final safeArea = drawer.child as SafeArea;
  final listView = safeArea.child as ListView;
  final delegate = listView.childrenDelegate as SliverChildListDelegate;

  return delegate.children
      .whereType<ListTile>()
      .map((tile) => ((tile.title as Text).data ?? "").trim())
      .where((title) => title.isNotEmpty)
      .toList(growable: false);
}
