import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/models/game_detail_state_model.dart';
import 'package:score_tracker/models/game.dart';
import 'package:score_tracker/models/game_state_model.dart';
import 'package:score_tracker/models/player.dart';
import 'package:score_tracker/models/player_state_model.dart';
import 'package:score_tracker/screens/add_player.dart';
import 'package:score_tracker/screens/game_board.dart';

import '../ad_manager.dart';
import '../styles.dart';
import '../widgets/add_players_widget.dart';

class SelectPlayer extends StatefulWidget {
  @override
  _SelectPlayerState createState() => _SelectPlayerState();
}

class _SelectPlayerState extends State<SelectPlayer> {
  // COMPLETE: Add _bannerAd
  BannerAd? _bannerAd;
  bool _isLoading = false;

  @override
  void initState() {
    setState(() {
      _isLoading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final model = Provider.of<PlayerStateModel>(context, listen: false);
      model.loadPlayers().then((value) => {
            setState(() {
              _isLoading = false;
            })
          });
    });

    // COMPLETE: Load a banner ad
    BannerAd(
      adUnitId: kReleaseMode
          ? AdManager.bannerAdUnitSelectPlayerId
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
    // COMPLETE: Dispose a BannerAd object
    _bannerAd?.dispose();
    super.dispose();
  }

  List<Player> playersSelected = [];

  String getPlayers() {
    List<String> result = [];
    for (var i = 0; i < playersSelected.length; i++) {
      result.add(playersSelected[i].name);
    }

    return result.length > 0
        ? result.join(', ')
        : AppLocalizations.of(context)!.select_2to6player;
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<PlayerStateModel>(context);
    final players = model.players;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.select_player_title,
          style: TextStyle(color: foregroundColor),
        ),
        backgroundColor: backgroundHeaderColor,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.add, color: foregroundButtonColor),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AddPlayer()));
              })
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : model.countPlayer() > 0
              ? Container(
                  child: Column(
                    children: [
                      Expanded(
                        child: Consumer<GameDetailStateModel>(
                            builder: (context, value, child) {
                          return ListView.builder(
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              var currentPlayer = players[index];
                              return Dismissible(
                                background: Container(
                                  color: Colors.red,
                                  child: Icon(Icons.cancel),
                                ),
                                secondaryBackground: Container(
                                  color: Colors.red,
                                  child: Icon(Icons.cancel),
                                ),
                                onDismissed: (direction) async {
                                  model.deletePlayer(currentPlayer.id!);
                                },
                                key: ValueKey(currentPlayer.name),
                                child: Card(
                                  color: backgroundHeaderColor,
                                  child: Theme(
                                    data: ThemeData(
                                        unselectedWidgetColor: foregroundColor),
                                    child: CheckboxListTile(
                                      value: playersSelected
                                          .contains(currentPlayer),
                                      onChanged: (bool? value) {
                                        if (value!) {
                                          setState(() {
                                            if (playersSelected.length < 6) {
                                              playersSelected
                                                  .add(currentPlayer);
                                            }
                                          });
                                        } else {
                                          setState(() {
                                            playersSelected
                                                .remove(currentPlayer);
                                          });
                                        }
                                      },
                                      title: Text(
                                        currentPlayer.name,
                                        style:
                                            TextStyle(color: foregroundColor),
                                      ),
                                      checkColor: foregroundColor,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height:
                                    MediaQuery.of(context).size.height * 0.15,
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            backgroundButtonColorBlue),
                                    onPressed: () async {
                                      if (playersSelected.length >= 2 &&
                                          playersSelected.length <= 6) {
                                        final model =
                                            Provider.of<GameStateModel>(context,
                                                listen: false);
                                        int id = -1;
                                        var now = DateFormat('yyyy-MM-dd H:m')
                                            .format(DateTime.now());
                                        await model
                                            .addGame(
                                                Game(
                                                    numberOfPlayers:
                                                        playersSelected.length,
                                                    createAt: now),
                                                playersSelected
                                                    .map((e) => e.id!)
                                                    .toList())
                                            .then((value) => id = value);

                                        model.getGameWithId(id).then((value) =>
                                            Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        GameBoard(
                                                          game: value!,
                                                          playerIds:
                                                              playersSelected
                                                                  .map((e) =>
                                                                      e.id!)
                                                                  .toList(),
                                                        ))));
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                            child: Column(
                                          children: [
                                            Text(getPlayers(),
                                                style: TextStyle(
                                                    color: foregroundColor,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            Divider(
                                              color: Colors.grey,
                                              thickness: 2.0,
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.play_arrow,
                                                  size: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.06,
                                                  color:
                                                      const Color(0xffcccccc),
                                                ),
                                                Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .let_start,
                                                    style: TextStyle(
                                                        color:
                                                            foregroundColor)),
                                              ],
                                            )
                                          ],
                                        ))
                                      ],
                                    )),
                              ),
                              SizedBox(
                                height: 5.0,
                              ),
                              _bannerAd != null
                                  ? Align(
                                      alignment: Alignment.bottomCenter,
                                      child: SizedBox(
                                        width: _bannerAd!.size.width.toDouble(),
                                        height:
                                            _bannerAd!.size.height.toDouble(),
                                        child: AdWidget(ad: _bannerAd!),
                                      ),
                                    )
                                  : SizedBox.shrink(),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(child: AddPlayersWidget()),
    );
  }
}
