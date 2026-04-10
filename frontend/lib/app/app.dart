import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:go_router/go_router.dart";

import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../features/authentication/presentation/bloc/auth_session_cubit.dart";
import "router/app_router.dart";
import "theme/app_theme.dart";

class UrbanArtDropsApp extends StatefulWidget {
  const UrbanArtDropsApp({super.key});

  @override
  State<UrbanArtDropsApp> createState() => _UrbanArtDropsAppState();
}

class _UrbanArtDropsAppState extends State<UrbanArtDropsApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(context.read<AuthSessionCubit>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Urban Art Drops",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
