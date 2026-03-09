import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "package:urban_art_drops_app/app/app.dart";
import "package:urban_art_drops_app/features/navigation/presentation/bloc/navigation_cubit.dart";

void main() {
  testWidgets("app boots", (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => NavigationCubit(),
        child: const UrbanArtDropsApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
