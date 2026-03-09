import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "app/app.dart";
import "features/authentication/presentation/bloc/auth_session_cubit.dart";
import "features/navigation/presentation/bloc/navigation_cubit.dart";

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NavigationCubit()),
        BlocProvider(create: (_) => AuthSessionCubit()),
      ],
      child: const UrbanArtDropsApp(),
    ),
  );
}
