import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:score_tracker/database/database_provider.dart';
import 'package:score_tracker/domain/models/room.dart';
import 'package:score_tracker/domain/repositories/room_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomSyncCoordinator {
  RoomSyncCoordinator({
    required this.repository,
    DatabaseProvider? database,
    Connectivity? connectivity,
  }) : _database = database ?? DatabaseProvider.db,
       _connectivity = connectivity ?? Connectivity();

  static const _activeRoomsKey = 'active_room_sessions';

  final RoomRepository repository;
  final DatabaseProvider _database;
  final Connectivity _connectivity;
  final Map<int, String> _activeRooms = {};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<void>? _initialization;
  bool _isFlushing = false;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_activeRoomsKey);
      if (stored != null) {
        final decoded = jsonDecode(stored);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final gameId = int.tryParse(entry.key);
            final roomCode = entry.value;
            if (gameId != null && roomCode is String) {
              _activeRooms[gameId] = roomCode;
            }
          }
        }
      }
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        results,
      ) {
        if (!results.contains(ConnectivityResult.none)) {
          unawaited(flushPending());
        }
      });
      unawaited(flushPending());
    } catch (_) {
      // A missing preferences or connectivity plugin must not block local scoring.
    }
  }

  Future<void> registerRoom({
    required int gameId,
    required String roomCode,
    required List<RoomRound> rounds,
    required Map<String, int> scores,
  }) async {
    await initialize();
    _activeRooms[gameId] = roomCode;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _activeRoomsKey,
        jsonEncode({
          for (final entry in _activeRooms.entries) '${entry.key}': entry.value,
        }),
      );
    } catch (_) {
      // The sync queue still records the initial score snapshot below.
    }
    await recordScoreboard(gameId: gameId, rounds: rounds, scores: scores);
  }

  Future<void> unregisterRoom(int gameId) async {
    await initialize();
    final roomCode = _activeRooms.remove(gameId);
    if (roomCode == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _activeRoomsKey,
        jsonEncode({
          for (final entry in _activeRooms.entries) '${entry.key}': entry.value,
        }),
      );
    } catch (_) {
      // Clearing the local association must not affect the completed game.
    }
    await _database.removePendingRoomSnapshots(roomCode);
  }

  Future<String?> activeRoomFor(int gameId) async {
    await initialize();
    return _activeRooms[gameId];
  }

  Future<void> recordScoreboard({
    required int gameId,
    required List<RoomRound> rounds,
    required Map<String, int> scores,
  }) async {
    await initialize();
    final roomCode = _activeRooms[gameId];
    if (roomCode == null) return;

    try {
      await _database.enqueueRoomSnapshot(
        roomCode: roomCode,
        gameId: gameId,
        payload: jsonEncode({
          'rounds': [
            for (final round in rounds)
              {
                'index': round.index,
                'scores': round.scores,
                'editedPlayerIds': round.editedPlayerIds.toList(),
              },
          ],
          'scores': scores,
        }),
      );
      unawaited(flushPending());
    } catch (_) {
      // Local database writes remain successful even if the outbox cannot be updated.
    }
  }

  Future<void> flushPending() async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      final snapshots = await _database.getPendingRoomSnapshots();
      for (final snapshot in snapshots) {
        try {
          final payload = jsonDecode(snapshot.payload) as Map<String, dynamic>;
          final rounds = (payload['rounds'] as List<dynamic>)
              .map((value) {
                final round = value as Map<String, dynamic>;
                return RoomRound(
                  index: round['index'] as int,
                  scores: (round['scores'] as Map<String, dynamic>).map(
                    (key, value) => MapEntry(key, (value as num).toInt()),
                  ),
                  editedPlayerIds: (round['editedPlayerIds'] as List<dynamic>)
                      .cast<String>()
                      .toSet(),
                );
              })
              .toList(growable: false);
          final scores = (payload['scores'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          );
          await repository.updateScoreboard(
            roomCode: snapshot.roomCode,
            rounds: rounds,
            scores: scores,
          );
          await _database.removePendingRoomSnapshot(snapshot);
        } catch (_) {
          // Retain this snapshot; a later reconnect or score update retries it.
        }
      }
    } catch (_) {
      // Keep local score entry independent of remote service availability.
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
  }
}
