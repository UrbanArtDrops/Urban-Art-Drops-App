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
}

class _TestHarness extends StatelessWidget {
  const _TestHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [GoRoute(path: "/", builder: (context, state) => child)],
    );

    return BlocProvider(
      create: (_) => AuthSessionCubit(),
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
