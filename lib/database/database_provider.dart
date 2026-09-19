import 'dart:developer';

import 'package:path/path.dart';
import 'package:score_tracker/models/game.dart';
import 'package:score_tracker/models/game_detail.dart';
import 'package:score_tracker/models/player.dart';
import 'package:score_tracker/models/player_score.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseProvider {
  DatabaseProvider._();
  static final DatabaseProvider db = DatabaseProvider._();

  Database? _database;

  static const migrationScripts = [
    'CREATE TABLE Player (id INTEGER primary key autoincrement, name TEXT NOT NULL UNIQUE, memo TEXT, createAt TEXT)',
    'CREATE TABLE Game (id INTEGER primary key autoincrement, numberOfPlayers INTEGER, createAt TEXT)',
    'CREATE TABLE GameDetail (id INTEGER primary key autoincrement, gameIndex INTERGER, score INTEGER, gameId INTEGER, playerId INTEGER, FOREIGN KEY(gameId) REFERENCES Game(id) on delete cascade, FOREIGN KEY(playerId) REFERENCES Player(id) on delete cascade)',
  ];

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _getDatabaseInstance();
    return _database;
  }

  static Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<Database> _getDatabaseInstance() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "ScoreChecker.db");
    return await openDatabase(path, version: migrationScripts.length + 1,
        onCreate: (Database db, int version) async {
      for (int i = 0; i <= migrationScripts.length - 1; i++) {
        await db.execute(migrationScripts[i]);
      }
    }, onUpgrade: (db, oldVersion, newVersion) async {
      for (var i = oldVersion - 1; i < newVersion - 1; i++) {
        await db.execute(migrationScripts[i]);
      }
    }, onConfigure: _onConfigure);
  }

  // Future<int> addPlayerToDatabase(Player player) async {
  //   final db = await database;
  //   var id = await db!.insert("Player", player.toMap(),
  //       conflictAlgorithm: ConflictAlgorithm.replace);
  //   return id;
  // }

  // Future<List<int>> insertPlayers(List<Player> players) async {
  //   // Open the database (ensure you have a reference to your database)
  //   final db = await database;
  //   List<int> insertedPlayerIds = [];
  //   // Loop through the list of players and insert each player
  //   for (Player player in players) {
  //     int playerId = await db!.insert(
  //       'Player', // Table name
  //       player.toMap(), // Converts the player object to a map
  //       conflictAlgorithm: ConflictAlgorithm.replace, // How to handle conflicts
  //     );

  //     // Add the inserted player ID to the list
  //     insertedPlayerIds.add(playerId);
  //   }

  //   // Return the list of inserted player IDs
  //   return insertedPlayerIds;
  // }

  Future<List<int>> insertPlayers(List<Player> players) async {
    // Open the database (ensure you have a reference to your database)
    final db = await database;
    List<int> insertedPlayerIds = [];

    await db!.transaction((txn) async {
      for (Player player in players) {
        // Check if a player with the same name already exists
        List<Map<String, dynamic>> existingPlayers = await txn.query(
          'Player',
          where: 'name = ?',
          whereArgs: [player.name],
        );

        if (existingPlayers.isNotEmpty) {
          // Player with the same name already exists, get its ID
          int existingPlayerId = existingPlayers.first['id'];
          insertedPlayerIds.add(existingPlayerId);
        } else {
          // Player with the name doesn't exist, insert the new player
          int playerId = await txn.insert(
            'Player',
            player.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          insertedPlayerIds.add(playerId);
        }
      }
    });

    return insertedPlayerIds;
  }

  Future<List<Player>> getAllPlayers() async {
    final db = await database;
    var response = await db!.query("Player");
    List<Player> list = response.map((c) => Player.fromMap(c)).toList();
    return list;
  }

  Future<List<Game>> getAllGames() async {
    final db = await database;
    var response = await db!.query("Game", orderBy: 'id DESC');
    List<Game> list = response.map((c) => Game.fromMap(c)).toList();
    return list;
  }

  Future<List<GameDetail>> getGameDetails(int gameId) async {
    final db = await database;
    var response =
        await db!.query("GameDetail", where: "gameId = ?", whereArgs: [gameId]);
    List<GameDetail> list = response.map((c) => GameDetail.fromMap(c)).toList();
    return list;
  }

  Future<Game?> getGameWithId(int id) async {
    final db = await database;
    var response = await db!.query("Game", where: "id = ?", whereArgs: [id]);
    return response.isNotEmpty ? Game.fromMap(response.first) : null;
  }

  Future<int> deleteGameWithId(int id) async {
    final db = await database;
    //one GameDetail table <=> one Game table via gameId, so we also delete GameDetail table when we delete Game table
    db!.delete("GameDetail", where: "gameId = ?", whereArgs: [id]);
    log('deleted game ${id}');

    return db.delete("Game", where: "id = ?", whereArgs: [id]);
  }

  // Future<Player?> getPlayerWithId(int id) async {
  //   final db = await database;
  //   var response = await db!.query("Player", where: "id = ?", whereArgs: [id]);
  //   debugPrint('getPlayerWithId: ${response.length}');
  //   return response.isNotEmpty ? Player.fromMap(response.first) : null;
  // }

  // Future<List<Player>> getPlayerWithIds(List<int> ids) async {
  //   final db = await database;
  //   var response = await db!.query("Player", where: 'id IN (${ids.join(",")})');

  //   List<Player> list = response.map((c) => Player.fromMap(c)).toList();
  //   return list;
  // }

  deletePlayerWithId(int id) async {
    final db = await database;
    return db!.delete("Player", where: "id = ?", whereArgs: [id]);
  }

  // Future<List<GameDetail>> getGameDetailsWithGameId(int gameId) async {
  //   final db = await database;
  //   var response =
  //       await db!.query("GameDetail", where: "gameId = ?", whereArgs: [gameId]);
  //   List<GameDetail> list = response.map((c) => GameDetail.fromMap(c)).toList();

  //   debugPrint('getGameDetailsWithGameId: ${list.length}');
  //   return list;
  // }

  Future<List<Player>> getPlayersWithGameId(int gameId) async {
    final db = await database;

    var response = await db!.rawQuery('''
    SELECT Player.id, Player.name, Player.memo, Player.createAt
    FROM Player
    INNER JOIN GameDetail ON Player.id = GameDetail.playerId
    WHERE GameDetail.gameId = ? GROUP BY Player.id
  ''', [gameId]);

    List<Player> list = response.map((c) => Player.fromMap(c)).toList();
    return list;
  }

  // addGameDetailToDatabase(GameDetail gameDetail) async {
  //   final db = await database;
  //   var id = await db!.insert("GameDetail", gameDetail.toMap(),
  //       conflictAlgorithm: ConflictAlgorithm.replace);
  //   return id;
  // }

  Future<int> addGameToDatabase(Game game, List<int> playerIds) async {
    final db = await database;
    var id = await db!.insert("Game", game.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

//
    final batch = db.batch();

    for (int i = 0; i < playerIds.length; i++) {
      final gameDetail = GameDetail(
          gameIndex: 0, playerId: playerIds[i], gameId: id, score: 0);

      batch.insert('GameDetail', gameDetail.toMap());

      log('inserted to GameDetail, player:${playerIds[i]}');
    }

    await batch.commit();

    return id;
  }

  Future<void> addScoresToGame(
      int index, int gameId, List<PlayerScore> playerScores) async {
    final db = await database;

    final batch = db!.batch();

    for (int i = 0; i < playerScores.length; i++) {
      final gameDetail = GameDetail(
          gameIndex: index,
          playerId: playerScores[i].playerId,
          gameId: gameId,
          score: playerScores[i].score);

      batch.insert('GameDetail', gameDetail.toMap());

      log('inserted to GameDetail, player:${playerScores[i].playerId}, score: ${playerScores[i].score}');
    }

    await batch.commit();
  }
}
