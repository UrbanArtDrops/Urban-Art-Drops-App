import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";

import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "router/app_router.dart";
import "theme/app_theme.dart";

class UrbanArtDropsApp extends StatelessWidget {
  const UrbanArtDropsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Urban Art Drops",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
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
