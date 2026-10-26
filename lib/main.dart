import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:editiz/data/creations_local_source.dart';
import 'package:editiz/data/file_service.dart';
import 'package:editiz/data/permission_service.dart';
import 'package:editiz/data/tips_remote_source.dart';
import 'package:editiz/data/video_service.dart';
import 'package:editiz/repositories/creations_repository.dart';
import 'package:editiz/repositories/tips_repository.dart';
import 'package:editiz/cubits/creations_cubit.dart';
import 'package:editiz/cubits/tips_cubit.dart';
import 'package:editiz/screens/splash_screen.dart';
import 'package:editiz/theme.dart';

// Function: main app entry point.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EditizApp());
}

// Class: root widget providing repositories, app-level Cubits, themes, and SplashScreen.
class EditizApp extends StatelessWidget {
  // Constructor: const key constructor.
  const EditizApp({super.key});

  // Override: sets up RepositoryProviders and BlocProviders for the app hierarchy.
  @override
  Widget build(BuildContext context) {
    final fileService = FileService();
    final permissionService = PermissionService();
    final videoService = VideoService();
    final creationsLocalSource = CreationsLocalSource();
    final tipsRemoteSource = TipsRemoteSource();

    final creationsRepository = CreationsRepository(
      localSource: creationsLocalSource,
      fileService: fileService,
    );
    final tipsRepository = TipsRepository(
      remoteSource: tipsRemoteSource,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FileService>.value(value: fileService),
        RepositoryProvider<PermissionService>.value(value: permissionService),
        RepositoryProvider<VideoService>.value(value: videoService),
        RepositoryProvider<CreationsRepository>.value(value: creationsRepository),
        RepositoryProvider<TipsRepository>.value(value: tipsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CreationsCubit>(
            create: (context) => CreationsCubit(repository: creationsRepository),
          ),
          BlocProvider<TipsCubit>(
            create: (context) => TipsCubit(repository: tipsRepository),
          ),
        ],
        child: MaterialApp(
          title: 'editiz',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
