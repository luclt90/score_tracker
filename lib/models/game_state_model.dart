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
    bool refreshGames = true,
  }) async {
    final id = await GameRepository.addGame(game, playerIds);
    if (refreshGames) {
      await loadGames(isNotify: isNotify);
    } else if (isNotify) {
      notifyListeners();
    }
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
