import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "package:urban_art_drops_app/app/app.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/features/navigation/presentation/bloc/navigation_cubit.dart";

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
}
