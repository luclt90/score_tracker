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

  Future<int> addGame(Game game, List<int> playerIds, {bool isNotify = true}) {
    var id = GameRepository.addGame(game, playerIds);
    loadGames(isNotify: isNotify);

    return id;
  }

  Future<Game?> getGameWithId(int id) async {
    return GameRepository.getGameWithId(id);
  }

  void deleteGame(int id) {
    GameRepository.deleteGame(id).then((value) {
      loadGames();
    });
  }
}
