import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (mobile only — web supports any orientation)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Set system UI overlay style (will be overridden by AnnotatedRegion in main_scaffold)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize local notifications and schedule daily 2:05 PM reminder
  // awesome_notifications is Android/iOS only — skip on web
  if (!kIsWeb) {
    try {
      await NotificationService.initialize();
      await NotificationService.requestPermission();
      await NotificationService.scheduleDailyReminder();
    } catch (_) {}
  }

  runApp(
    const ProviderScope(
      child: SchoolFeesApp(),
    ),
  );
}
