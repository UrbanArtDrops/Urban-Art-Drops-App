import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "app/app.dart";
import "features/authentication/application/auth_session_storage.dart";
import "features/authentication/presentation/bloc/auth_session_cubit.dart";
import "features/navigation/presentation/bloc/navigation_cubit.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authSessionCubit = AuthSessionCubit(
    storage: SharedPreferencesAuthSessionStorage(),
  );
  await authSessionCubit.hydrate();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NavigationCubit()),
        BlocProvider.value(value: authSessionCubit),
      ],
      child: const UrbanArtDropsApp(),
    ),
  );
}
