import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "app/app.dart";
import "features/navigation/presentation/bloc/navigation_cubit.dart";

void main() {
  runApp(
    BlocProvider(
      create: (_) => NavigationCubit(),
      child: const UrbanArtDropsApp(),
    ),
  );
}
