import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/models/game_state_model.dart';
import 'package:score_tracker/models/player_state_model.dart';
import 'package:score_tracker/screens/home_page.dart';
import 'models/game_detail_state_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ScoreChecker(),
  );
}

class ScoreChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (ctx) => GameStateModel(),
          ),
          ChangeNotifierProvider(
            create: (ctx) => PlayerStateModel(),
          ),
          ChangeNotifierProvider(
            create: (ctx) => GameDetailStateModel(),
          ),
        ],
        child: MaterialApp(
            title: 'Score Keeper',
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              useMaterial3: false,
            ),
            home: HomePage()));
  }
}
