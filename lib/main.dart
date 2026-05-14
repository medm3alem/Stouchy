import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stouchy/l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/lifecycle_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Timezone et Notifications (Mobile et Bureau)
  if (!kIsWeb) {
    try {
      tz.initializeTimeZones();
      // On n'initialise les notifications que sur les plateformes supportées
      if (defaultTargetPlatform == TargetPlatform.android || 
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await NotificationService.init();
      }
    } catch (e) {
      debugPrint("Service initialization failed: $e");
    }
  }

  // Initialisation Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
    // Sur le Web, cette erreur est souvent due à une configuration manquante
  }

  runApp(
    const ProviderScope(
      child: StouchyApp(),
    ),
  );
}

class StouchyApp extends ConsumerStatefulWidget {
  const StouchyApp({super.key});

  @override
  ConsumerState<StouchyApp> createState() => _StouchyAppState();
}

class _StouchyAppState extends ConsumerState<StouchyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(ref.read(appLifecycleProvider));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(ref.read(appLifecycleProvider));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final isDark = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Stouchy',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
