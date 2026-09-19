import 'package:flutter/foundation.dart';
import 'package:score_tracker/models/game_detail.dart';
import 'package:score_tracker/models/player_in_game.dart';
import 'package:score_tracker/models/player_score.dart';

import 'game_repository.dart';

class GameDetailStateModel extends ChangeNotifier {
  List<GameDetail> _availableGameDetails = <GameDetail>[];
  List<PlayerInGame> _playersInGame = <PlayerInGame>[];

  List<GameDetail> get availableGameDetails {
    return List.from(_availableGameDetails);
  }

  List<PlayerInGame> get playersInGame {
    return List.from(_playersInGame);
  }

  int calculateTotalScore(int playerId) {
    int totalScore = 0;

    for (var gameDetail in _availableGameDetails) {
      if (gameDetail.playerId == playerId) {
        totalScore += gameDetail.score;
      }
    }

    return totalScore;
  }

  Future<void> loadGameDetails(int gameId) async {
    _availableGameDetails = await GameRepository.loadGameDetails(gameId);
    _availableGameDetails.sort((a, b) {
      int gameIndexComparison = b.gameIndex.compareTo(a.gameIndex);
      if (gameIndexComparison == 0) {
        return a.playerId.compareTo(b.playerId);
      }

      return gameIndexComparison;
    });

    var players = await GameRepository.getPlayersWithGameId(gameId);

    _playersInGame.clear();
    for (var i = 0; i < players.length; i++) {
      PlayerInGame playerInGame = PlayerInGame();
      playerInGame.playerId = players[i].id!;
      playerInGame.playerName = players[i].name;
      playerInGame.totalScore = calculateTotalScore(players[i].id!);
      playerInGame.score = 0;

      _playersInGame.add(playerInGame);
    }

    notifyListeners();
  }

  addScoresToGame(int index, int gameId, List<PlayerScore> playerScores) {
    GameRepository.addScoresToGame(index, gameId, playerScores).then((value) {
      loadGameDetails(gameId);
    });
  }
}
