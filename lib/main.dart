import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:editiz/controllers/creations_controller.dart';
import 'package:editiz/controllers/tips_controller.dart';
import 'package:editiz/data/creations_local_source.dart';
import 'package:editiz/data/file_service.dart';
import 'package:editiz/data/permission_service.dart';
import 'package:editiz/data/tips_remote_source.dart';
import 'package:editiz/data/video_service.dart';
import 'package:editiz/repositories/creations_repository.dart';
import 'package:editiz/repositories/tips_repository.dart';
import 'package:editiz/screens/splash_screen.dart';
import 'package:editiz/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EditizApp());
}

/// Root widget configuring Providers, services, repositories, and theme.
class EditizApp extends StatelessWidget {
  const EditizApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Data services
    final fileService = FileService();
    final permissionService = PermissionService();
    final videoService = VideoService();
    final creationsLocalSource = CreationsLocalSource();
    final tipsRemoteSource = TipsRemoteSource();

    // 2. Repositories
    final creationsRepository = CreationsRepository(
      localSource: creationsLocalSource,
      fileService: fileService,
    );
    final tipsRepository = TipsRepository(
      remoteSource: tipsRemoteSource,
    );

    return MultiProvider(
      providers: [
        // Services
        Provider<FileService>.value(value: fileService),
        Provider<PermissionService>.value(value: permissionService),
        Provider<VideoService>.value(value: videoService),

        // Repositories
        Provider<CreationsRepository>.value(value: creationsRepository),
        Provider<TipsRepository>.value(value: tipsRepository),

        // Global Controllers
        ChangeNotifierProvider<CreationsController>(
          create: (_) => CreationsController(repository: creationsRepository),
        ),
        ChangeNotifierProvider<TipsController>(
          create: (_) => TipsController(repository: tipsRepository),
        ),
      ],
      child: MaterialApp(
        title: 'editiz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
