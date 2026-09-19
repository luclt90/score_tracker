import 'package:flutter/foundation.dart';

import 'game.dart';
import 'game_repository.dart';

class GameStateModel extends ChangeNotifier {
  List<Game> _availableGames = <Game>[];

  List<Game> get availableGames {
    return List.from(_availableGames);
  }

  int countGame() {
    return _availableGames.length;
  }

  Future<void> loadGames({bool isNotify = true}) async {
    _availableGames = await GameRepository.loadGames();
    if (isNotify) {
      notifyListeners();
    }
  }

  Future<int> addGame(
    Game game,
    List<int> playerIds, {
    bool isNotify = true,
  }) async {
    // Wait for SQLite to finish writing before reading the history again.
    // Previously these operations raced, so HomePage could receive the old list
    // until the user manually refreshed it.
    final id = await GameRepository.addGame(game, playerIds);
    await loadGames(isNotify: isNotify);
    return id;
  }

  Future<Game?> getGameWithId(int id) async {
    return GameRepository.getGameWithId(id);
  }

  Future<void> deleteGame(int id) async {
    await GameRepository.deleteGame(id);
    await loadGames();
  }
}
