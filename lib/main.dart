import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/models/game_state_model.dart';
import 'package:score_tracker/models/player_state_model.dart';
import 'package:score_tracker/screens/home_page.dart';

import 'models/game_detail_state_model.dart';

bool _firebaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    _firebaseInitialized = true;
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        ),
      );
      return true;
    };
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error\n$stackTrace');
  }
  runApp(const ScoreChecker());
}

class ScoreChecker extends StatelessWidget {
  const ScoreChecker({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => GameStateModel()),
        ChangeNotifierProvider(create: (ctx) => PlayerStateModel()),
        ChangeNotifierProvider(create: (ctx) => GameDetailStateModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Score Keeper',
        navigatorObservers: _firebaseInitialized
            ? [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)]
            : const <NavigatorObserver>[],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: false,
        ),
        home: HomePage(),
      ),
    );
  }
}
