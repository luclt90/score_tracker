import 'package:flutter/foundation.dart';
import 'package:score_tracker/models/player.dart';
import 'game_repository.dart';

class PlayerStateModel extends ChangeNotifier {
  List<Player> _players = <Player>[];

  List<Player> get players {
    return List.from(_players);
  }

  int countPlayer() {
    return _players.length;
  }

  Future<void> loadPlayers({bool isNotify = true}) async {
    _players = await GameRepository.loadPlayers();
    if (isNotify) {
      notifyListeners();
    }
  }

  Future<List<int>> insertPlayers(List<Player> players,
      {bool isNotify = true}) async {
    final ids = await GameRepository.insertPlayers(players);

    loadPlayers(isNotify: isNotify);
    return ids;
  }

  void deletePlayer(int id) {
    GameRepository.deletePlayer(id);
    loadPlayers();
  }

  Future<List<Player>> getPlayersWithGameId(int gameId) {
    return GameRepository.getPlayersWithGameId(gameId);
  }
}
