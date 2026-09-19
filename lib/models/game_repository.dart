import 'package:score_tracker/database/database_provider.dart';
import 'package:score_tracker/models/game_detail.dart';
import 'package:score_tracker/models/player.dart';
import 'package:score_tracker/models/player_score.dart';

import 'game.dart';

class GameRepository {
  static Future<List<Player>> loadPlayers() {
    return DatabaseProvider.db.getAllPlayers();
  }

  static Future<List<Game>> loadGames() {
    return DatabaseProvider.db.getAllGames();
  }

  static Future<List<GameDetail>> loadGameDetails(int gameId) {
    return DatabaseProvider.db.getGameDetails(gameId);
  }

  static Future<int> addGame(Game game, List<int> playerIds) {
    return DatabaseProvider.db.addGameToDatabase(game, playerIds);
  }

  static Future<List<int>> insertPlayers(List<Player> players) {
    return DatabaseProvider.db.insertPlayers(players);
  }

  static Future<Game?> getGameWithId(int id) {
    return DatabaseProvider.db.getGameWithId(id);
  }

  static Future<int> deleteGame(int id) {
    return DatabaseProvider.db.deleteGameWithId(id);
  }

  static void deletePlayer(int id) {
    return DatabaseProvider.db.deletePlayerWithId(id);
  }

  static Future<List<Player>> getPlayersWithGameId(int gameId) {
    return DatabaseProvider.db.getPlayersWithGameId(gameId);
  }

  static Future<void> addScoresToGame(
      int index, int gameId, List<PlayerScore> playerScores) {
    return DatabaseProvider.db.addScoresToGame(index, gameId, playerScores);
  }

  static Future<int> updateGameDetailScore(int detailId, int score) {
    return DatabaseProvider.db.updateGameDetailScore(detailId, score);
  }
}
