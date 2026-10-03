import 'package:flutter/foundation.dart';
import 'package:score_tracker/models/game_detail.dart';
import 'package:score_tracker/models/player_in_game.dart';
import 'package:score_tracker/models/player_score.dart';
import 'package:score_tracker/domain/models/room.dart';
import 'package:score_tracker/services/room_sync_coordinator.dart';

import 'game_repository.dart';

class GameDetailStateModel extends ChangeNotifier {
  GameDetailStateModel({this.roomSyncCoordinator});

  final RoomSyncCoordinator? roomSyncCoordinator;
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

    final roundsByIndex = <int, List<GameDetail>>{};
    for (final detail in _availableGameDetails) {
      roundsByIndex.putIfAbsent(detail.gameIndex, () => []).add(detail);
    }
    final roomRounds =
        roundsByIndex.entries
            .map(
              (entry) => RoomRound(
                index: entry.key,
                scores: {
                  for (final detail in entry.value)
                    '${detail.playerId}': detail.score,
                },
                editedPlayerIds: {
                  for (final detail in entry.value)
                    if (detail.editedAt != null) '${detail.playerId}',
                },
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => a.index.compareTo(b.index));
    await roomSyncCoordinator?.recordScoreboard(
      gameId: gameId,
      rounds: roomRounds,
      scores: {
        for (final player in _playersInGame)
          '${player.playerId}': player.totalScore,
      },
    );

    notifyListeners();
  }

  Future<void> addScoresToGame(
    int index,
    int gameId,
    List<PlayerScore> playerScores,
  ) async {
    await GameRepository.addScoresToGame(index, gameId, playerScores);
    await loadGameDetails(gameId);
  }

  Future<void> updateGameDetailScore(
    int detailId,
    int score,
    int gameId,
  ) async {
    await GameRepository.updateGameDetailScore(detailId, score);
    await loadGameDetails(gameId);
  }
}
