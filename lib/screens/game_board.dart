import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/ad_manager.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/models/game.dart';
import 'package:score_tracker/models/game_detail.dart';
import 'package:score_tracker/models/game_detail_state_model.dart';
import 'package:score_tracker/models/player_score.dart';
import 'package:score_tracker/widgets/column_header.dart';
import 'package:score_tracker/widgets/input_score.dart';

import '../models/player_in_game.dart';
import '../styles.dart';

class GameBoard extends StatefulWidget {
  final Game game;
  final List<int> playerIds;

  GameBoard({required this.game, required this.playerIds});

  @override
  _GameDetailState createState() => _GameDetailState();
}

class _GameDetailState extends State<GameBoard> {
  // COMPLETE: Add _bannerAd
  BannerAd? _bannerAd;

  List<PlayerInGame> playerInGames = [];
  List<InputScore> inputScores = [];
  int _index = 0;
  bool _isLoading = false;

  @override
  void initState() {
    setState(() {
      _isLoading = true;
    });

    final model = Provider.of<GameDetailStateModel>(context, listen: false);
    model.loadGameDetails(widget.game.id!).then((value) => {
          setState(() {
            _isLoading = false;
          })
        });

    // COMPLETE: Load a banner ad
    BannerAd(
      adUnitId: kReleaseMode
          ? AdManager.bannerAdUnitId
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

  List<DataColumn> _buildColumns({required bool isEmptyColumn}) {
    List<DataColumn> columns = [];
    columns.add(DataColumn(
      label: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              "#",
              style: TextStyle(
                  color: foregroundHintColor,
                  fontFamily: fontFamilySFProText,
                  fontSize: 10.0,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    ));

    if (isEmptyColumn) {
      columns.addAll(playerInGames
          .map(
            (player) => DataColumn(
              label: ColumnHeader(score: 0, header: ""),
            ),
          )
          .toList());
    } else {
      columns.addAll(playerInGames
          .map(
            (player) => DataColumn(
              label: Center(
                child: ColumnHeader(
                    score: player.totalScore, header: player.playerName),
              ),
            ),
          )
          .toList());
    }

    return columns;
  }

  List<DataCell> _buildCells(int index, List<GameDetail> gameDetails) {
    List<DataCell> dataCells = [];

    dataCells.add(DataCell(Center(
        child: Text(index.toString(),
            style: TextStyle(
                color: foregroundHintColor,
                fontFamily: fontFamilySFProText,
                fontSize: 12.0,
                fontStyle: FontStyle.italic)))));

    for (final player in playerInGames) {
      final detail = gameDetails.firstWhereOrNull(
        (element) => element.playerId == player.playerId,
      );

      dataCells.add(DataCell(Center(
        child: Text(detail?.score.toString() ?? '', style: rowTextStyle),
      )));
    }

    return dataCells;
  }

  List<Widget> _buildInputScores() {
    inputScores = [];

    for (var i = 0; i < playerInGames.length; i++) {
      var ctrl = InputScore(
        playerName: playerInGames[i].playerName,
        playerId: playerInGames[i].playerId,
        autoFocus: false,
      );

      inputScores.add(ctrl);
    }

    return inputScores;
  }

  @override
  Widget build(BuildContext context) {
    log('GameDetailWidget: rebuild');
    var _isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    double _delta = _isPortrait ? 55.0 : 80.0;
    var _width = MediaQuery.of(context).size.width;
    var _height = MediaQuery.of(context).size.height;

    final model = Provider.of<GameDetailStateModel>(context);
    //final playerModel = Provider.of<PlayerStateModel>(context, listen: false);
    final gameDetails = model.availableGameDetails;
    _index = gameDetails.length > 0 ? gameDetails.first.gameIndex : 0;

    playerInGames = model.playersInGame;

    Map<int, List<GameDetail>> groupedGameDetailByIndex =
        groupBy(gameDetails, (obj) => obj.gameIndex);

    // return FutureBuilder<void>(builder: (context, snapshot) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.score_board,
          style: TextStyle(color: foregroundColor), //Color: Silver
        ),
        leading: IconButton(
            color: foregroundColor,
            icon: Icon(Icons.arrow_back),
            onPressed: () =>
                {Navigator.of(context).popUntil((route) => route.isFirst)}),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.add, color: foregroundButtonColor),
              onPressed: () {
                _showDialog().then((value) {
                  if (value == true) {
                    final model = Provider.of<GameDetailStateModel>(context,
                        listen: false);
                    List<PlayerScore> playerScores = [];
                    for (var i = 0; i < inputScores.length; i++) {
                      playerScores.add(PlayerScore(
                          playerId: inputScores[i].playerId,
                          score: inputScores[i].score));
                    }

                    model.addScoresToGame(
                        _index, widget.game.id!, playerScores);
                  }
                });
              })
        ],
        backgroundColor: backgroundHeaderColor,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Flexible(
                  child: Container(
                    color: backgroundHeaderColor,
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: DataTable(
                            headingRowHeight:
                                _isPortrait ? _height * 0.14 : _width * 0.14,
                            columnSpacing: _isPortrait
                                ? (_width / (widget.playerIds.length + 1)) -
                                    _delta
                                : (_height / (widget.playerIds.length + 1)) -
                                    _delta,
                            columns: _buildColumns(isEmptyColumn: true),
                            rows: groupedGameDetailByIndex.keys.map((e) {
                              return DataRow(
                                  cells: _buildCells(
                                      e, groupedGameDetailByIndex[e]!));
                            }).toList(),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            color: backgroundHeaderColor,
                            child: DataTable(
                                headingRowHeight: _isPortrait
                                    ? _height * 0.14
                                    : _width * 0.14,
                                columnSpacing: _isPortrait
                                    ? (_width / (widget.playerIds.length + 1)) -
                                        _delta
                                    : (_height /
                                            (widget.playerIds.length + 1)) -
                                        _delta,
                                columns: _buildColumns(isEmptyColumn: false),
                                rows: []),
                          ),
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
                  ),
                ),
              ],
            ),
    );
    // });
  }

  Future<bool> _showDialog() {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    double delta = 150;
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: AlertDialog(
              backgroundColor: backgroundHeaderColor,
              title: Center(
                  child: Text(
                AppLocalizations.of(context)!.add_score,
                style: TextStyle(
                    color: foregroundColor,
                    fontFamily: fontFamilySFProText,
                    fontWeight: FontWeight.w600,
                    fontSize: 15.0,
                    fontStyle: FontStyle.normal),
              )),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildInputScores(),
              ),
              actionsOverflowDirection: VerticalDirection.down,
              actionsOverflowButtonSpacing: 15.0,
              actions: <Widget>[
                SizedBox(
                  width: isPortrait ? width - delta : height - delta,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: backgroundHeaderColor),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text(AppLocalizations.of(context)!.cancel,
                              style: TextStyle(
                                  color: foregroundButtonColor,
                                  fontFamily: fontFamily,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.0,
                                  fontStyle: FontStyle.normal)),
                        ),
                      ),
                      SizedBox(
                        width: 20.0,
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: backgroundButtonColorBlue),
                          onPressed: () {
                            _index++;
                            Navigator.of(context).pop(true);
                          },
                          child: Text(
                            AppLocalizations.of(context)!.save,
                            style: TextStyle(
                                color: foregroundButtonColor,
                                fontFamily: fontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.0,
                                fontStyle: FontStyle.normal),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    ).then((value) => value ?? false);
  }
}
