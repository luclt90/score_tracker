import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/models/game.dart';
import 'package:score_tracker/models/game_state_model.dart';
import 'package:score_tracker/models/player.dart';
import 'package:score_tracker/models/player_state_model.dart';
import 'package:score_tracker/screens/game_board.dart';

import '../styles.dart';

class GameCardItem extends StatefulWidget {
  GameCardItem({required this.game, this.index = 0}) : super();

  final Game game;
  final int index;

  @override
  State<GameCardItem> createState() => _GameCardItemState();
}

class _GameCardItemState extends State<GameCardItem> {
  final navigatorKey = GlobalKey<NavigatorState>();
  bool isLoading = true;
  List<Player> players = [];

  Future<List<Player>> getPlayersViaGameId(BuildContext context) async {
    List<Player> players = [];
    final playerModel = Provider.of<PlayerStateModel>(context, listen: false);

    await playerModel
        .getPlayersWithGameId(widget.game.id ?? 0)
        .then((value) => players = value);

    return players;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });

    super.initState();
  }

  Future<void> loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    final loadedPlayers = await getPlayersViaGameId(context);

    if (!mounted) return;

    setState(() {
      players = loadedPlayers;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    log('GameCardItem built');
    return GestureDetector(
      onTap: () {
        if (!isLoading) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GameBoard(
                        game: widget.game,
                        playerIds: players.map((e) => e.id!).toList(),
                      )));
        }
      },
      child: buildListTile(),
    );
  }

  Widget buildListTile() {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    if (isLoading) // Show CircularProgressIndicator when loading
      return Center(child: CircularProgressIndicator());
    else
      return Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: Container(
                  width: MediaQuery.of(context).size.width * 0.1,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    border: Border.all(width: 0),
                    shape: BoxShape.circle,
                    color: backgroundButtonColorBlue,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                          color: foregroundColor,
                          fontFamily: fontFamilySFProText,
                          fontSize: 20.0,
                          fontStyle: FontStyle.normal),
                    ),
                  ),
                ),
                title: Text(
                  players.map((e) => e.name).join(", "),
                  style: TextStyle(
                      color: foregroundColor,
                      fontFamily: fontFamilySFProText,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.0,
                      fontStyle: FontStyle.normal),
                ),
                subtitle: Text(
                  '${widget.game.createAt}',
                  style: TextStyle(
                      color: foregroundHintColor,
                      fontFamily: fontFamilySFProText,
                      fontWeight: FontWeight.normal,
                      fontSize: 13.0,
                      fontStyle: FontStyle.normal),
                ),
                trailing: IconButton(
                  onPressed: () => {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GameBoard(
                                  game: widget.game,
                                  playerIds: players.map((e) => e.id!).toList(),
                                )))
                  },
                  icon: Icon(Icons.navigate_next,
                      color: foregroundColor, size: 30.0),
                )),
            ButtonBar(alignment: MainAxisAlignment.end, children: <Widget>[
              SizedBox(
                width: isPortrait ? width * 0.3 : height * 0.3,
                height: isPortrait ? height * 0.055 : width * 0.055,
                child: TextButton(
                    onPressed: () async {
                      final model =
                          Provider.of<GameStateModel>(context, listen: false);
                      int id = -1;
                      await model
                          .addGame(
                              Game(
                                  numberOfPlayers: players.length,
                                  createAt: DateFormat('yyyy-MM-dd H:m')
                                      .format(DateTime.now())),
                              players.map((e) => e.id!).toList())
                          .then((value) => id = value);

                      await model
                          .getGameWithId(id)
                          .then((value) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GameBoard(
                                        game: value!,
                                        playerIds:
                                            players.map((e) => e.id!).toList(),
                                      ))));
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_in_new,
                          size: isPortrait ? width * 0.03 : height * 0.03,
                          color: const Color(0xffcccccc),
                        ),
                        Text(AppLocalizations.of(context)!.new_play,
                            style: TextStyle(
                                color: foregroundButtonColor,
                                fontFamily: fontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 15.0,
                                fontStyle: FontStyle.normal)),
                      ],
                    )),
              ),
              SizedBox(
                width: isPortrait ? width * 0.3 : height * 0.3,
                height: isPortrait ? height * 0.055 : width * 0.055,
                child: TextButton(
                    onPressed: () async {
                      double delta = 150;

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
                                  AppLocalizations.of(context)!.delete,
                                  style: TextStyle(
                                      color: foregroundColor,
                                      fontFamily: fontFamilySFProText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15.0,
                                      fontStyle: FontStyle.normal),
                                )),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Center(
                                        child: Text(
                                      AppLocalizations.of(context)!
                                          .delete_confirm,
                                      style: TextStyle(
                                          color: foregroundColor,
                                          fontFamily: fontFamilySFProText,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15.0,
                                          fontStyle: FontStyle.normal),
                                    )),
                                  ],
                                ),
                                actionsOverflowDirection:
                                    VerticalDirection.down,
                                actionsOverflowButtonSpacing: 15.0,
                                actions: <Widget>[
                                  SizedBox(
                                    width: isPortrait
                                        ? width - delta
                                        : height - delta,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(false);
                                            },
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .cancel,
                                                style: TextStyle(
                                                    color:
                                                        foregroundButtonColor,
                                                    fontFamily: fontFamily,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13.0,
                                                    fontStyle:
                                                        FontStyle.normal)),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 20.0,
                                        ),
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(true);
                                            },
                                            child: Text(
                                              AppLocalizations.of(context)!
                                                  .delete,
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
                      ).then((value) async {
                        if (value == true) {
                          final model = Provider.of<GameStateModel>(context,
                              listen: false);
                          model.deleteGame(widget.game.id!);
                        }
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_forever,
                          size: MediaQuery.of(context).size.height * 0.03,
                          color: const Color(0xffcccccc),
                        ),
                        Text(AppLocalizations.of(context)!.delete,
                            style: TextStyle(
                                color: foregroundButtonColor,
                                fontFamily: fontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 15.0,
                                fontStyle: FontStyle.normal)),
                      ],
                    )),
              )
            ]),
          ],
        ),
        color: backgroundHeaderColor,
      );
  }
}
