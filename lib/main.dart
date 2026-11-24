import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/user_service.dart';
import 'services/audio_service.dart';
import 'services/ad_service.dart';

// Uygulamanın her yerinden (oyun içi dahil) ekranı kontrol edebilmek için GlobalKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase zaten başlatılmış: $e");
  }

  // --- FIREBASE APP CHECK (Bot ve Modlu APK Koruması) ---
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );
  } catch (e) {
    debugPrint("App Check başlatma uyarısı: $e");
  }

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  AudioService.instance.init();
  unawaited(AdService.instance.init());

  runApp(const SayiSozlukApp());
}

class SayiSozlukApp extends StatefulWidget {
  const SayiSozlukApp({super.key});

  @override
  State<SayiSozlukApp> createState() => _SayiSozlukAppState();
}

class _SayiSozlukAppState extends State<SayiSozlukApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      UserService.instance.updateUserStatus('çevrimiçi');
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      UserService.instance.updateUserStatus('çevrimdışı');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SayıSözlük',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Cihaz çakışması anında ana menüye atmak için bağlandı
      theme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}