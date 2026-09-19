import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/models/game_state_model.dart';
import 'package:score_tracker/models/player_state_model.dart';
import 'package:score_tracker/widgets/input_player.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_manager.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../screens/game_board.dart';
import '../styles.dart';

class AddPlayersWidget extends StatefulWidget {
  const AddPlayersWidget({Key? key}) : super(key: key);

  @override
  State<AddPlayersWidget> createState() => _AddPlayersWidgetState();
}

class _AddPlayersWidgetState extends State<AddPlayersWidget> {
  int selectedPlayers = 4; // Default value
  List<TextEditingController> controllers = [];

  // COMPLETE: Add _bannerAd
  BannerAd? _bannerAd;

  @override
  void initState() {
    // Initialize controllers with empty text.
    for (int i = 0; i < selectedPlayers; i++) {
      controllers.add(TextEditingController());
    }

    // COMPLETE: Load a banner ad
    BannerAd(
      adUnitId: kReleaseMode
          ? AdManager.bannerAdUnitAddPlayerId
          : AdManager.bannerAdUnitIdTest,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          log('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();

    super.initState();
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is disposed.
    for (var controller in controllers) {
      controller.dispose();
    }

    // COMPLETE: Dispose a BannerAd object
    _bannerAd?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 10.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                AppLocalizations.of(context)!.player_number,
                style: TextStyle(
                    color: foregroundColor,
                    fontFamily: fontFamily,
                    fontWeight: FontWeight.w300,
                    fontSize: 15.0,
                    fontStyle: FontStyle.normal),
              ),
              DropdownButton<int>(
                value: selectedPlayers,
                dropdownColor: backgroundColor,
                onChanged: (newValue) {
                  setState(() {
                    selectedPlayers = newValue!;
                    // Initialize or reset controllers when the value changes.
                    controllers.clear();
                    for (int i = 0; i < selectedPlayers; i++) {
                      controllers.add(TextEditingController());
                    }
                  });
                },
                items: [2, 3, 4, 5, 6].map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(
                      '$value',
                      style: TextStyle(
                          color: foregroundColor,
                          fontFamily: fontFamily,
                          fontWeight: FontWeight.w300,
                          fontSize: 15.0,
                          fontStyle: FontStyle.normal),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          SizedBox(
            height: 10.0,
          ),
          Column(
            children: List.generate(
              selectedPlayers,
              (index) => InputPlayer(
                playerController: controllers[index], // Assign controller
                hint:
                    "${AppLocalizations.of(context)!.player_name_hint} ${++index}",
              ),
            ),
          ),
          const SizedBox(
            height: 10.0,
          ),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                  width: MediaQuery.of(context).size.width * 1,
                  height: MediaQuery.of(context).size.height * 0.08,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: backgroundButtonColorBlue),
                    onPressed: () async {
                      final model =
                          Provider.of<GameStateModel>(context, listen: false);
                      final playerModel =
                          Provider.of<PlayerStateModel>(context, listen: false);
                      int id = -1;
                      var now =
                          DateFormat('yyyy-MM-dd H:m').format(DateTime.now());
                      List<Player> players = [];
                      for (int i = 0; i < selectedPlayers; i++) {
                        if (controllers[i].text.isNotEmpty) {
                          players.add(
                            new Player(
                                name: controllers[i].text,
                                memo: "",
                                createAt: now),
                          );
                        }
                      }

                      List<int> playerIds = [];
                      try {
                        playerIds = await playerModel.insertPlayers(players,
                            isNotify: false);
                      } catch (e) {}

                      await model
                          .addGame(
                              Game(
                                  numberOfPlayers: players.length,
                                  createAt: now),
                              playerIds)
                          .then((value) => id = value);

                      model
                          .getGameWithId(id)
                          .then((value) => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GameBoard(
                                        game: value!,
                                        playerIds: playerIds,
                                      ))));
                    },
                    child: Text(
                      AppLocalizations.of(context)!.let_start,
                      style: TextStyle(
                          color: foregroundButtonColor,
                          fontFamily: fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 22.0,
                          fontStyle: FontStyle.normal),
                    ),
                  ))),
          const SizedBox(
            height: 10.0,
          ),
          _bannerAd != null
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
