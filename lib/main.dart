import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'screens/home_screen.dart';
import 'services/foreground_task.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Foreground service (monitor)
  ForegroundTaskManager.init();

  // Local notifications
  await NotificationService.init();

  runApp(const WithForegroundTask(child: TibiaToolsApp()));
}

class TibiaToolsApp extends StatelessWidget {
  const TibiaToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tibia Tools (Flutter)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
