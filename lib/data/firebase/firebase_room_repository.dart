import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:score_tracker/data/firebase/firebase_anonymous_identity.dart';
import 'package:score_tracker/domain/models/room.dart';
import 'package:score_tracker/domain/repositories/room_repository.dart';

class FirebaseRoomRepository implements RoomRepository {
  FirebaseRoomRepository({
    this.database,
    required this.identity,
    Random? random,
  }) : _random = random ?? Random.secure();

  static const _roomCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _roomLifetime = Duration(hours: 24);
  static const _roomCodeLength = 6;
  static const _roomCodeAttempts = 20;

  final FirebaseDatabase? database;
  final FirebaseAnonymousIdentity identity;
  final Random _random;

  late final DatabaseReference _rooms = _createRoomsReference();

  DatabaseReference _createRoomsReference() {
    final instance = database ?? FirebaseDatabase.instance;
    instance.setPersistenceEnabled(true);
    return instance.ref('rooms');
  }

  @override
  Future<String> currentUserId() => identity.requireUserId();

  @override
  Future<String> createRoom({
    required String hostId,
    required List<RoomPlayer> players,
    required List<RoomRound> rounds,
    required Map<String, int> scores,
  }) async {
    try {
      final userId = await identity.requireUserId();
      if (hostId != userId) {
        throw StateError('The room host must be the authenticated user.');
      }

      final now = DateTime.now().toUtc();
      final publicData = <String, Object?>{
        'hostId': hostId,
        'createdAt': now.millisecondsSinceEpoch,
        'lastActivityAt': now.millisecondsSinceEpoch,
        'expiresAt': now.add(_roomLifetime).millisecondsSinceEpoch,
        'status': RoomStatus.active.name,
        'players': players.map(_playerToMap).toList(growable: false),
        'rounds': _roundsToMap(rounds),
        'scores': scores,
      };

      for (var attempt = 0; attempt < _roomCodeAttempts; attempt++) {
        final code = _generateRoomCode();
        final result = await _rooms
            .child(code)
            .child('public')
            .runTransaction(
              (currentData) => currentData == null
                  ? Transaction.success(publicData)
                  : Transaction.abort(),
              applyLocally: false,
            );
        if (result.committed) return code;
      }
      throw StateError('Unable to allocate a unique room code.');
    } catch (error, stackTrace) {
      await _recordSyncError(error, stackTrace);
      if (error is RoomRepositoryException) rethrow;
      throw RoomRepositoryException(_roomErrorCode(error));
    }
  }

  String _roomErrorCode(Object error) {
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      if (code.contains('permission-denied'))
        return 'database_permission_denied';
      if (code.contains('database-not-found') ||
          code.contains('database-url')) {
        return 'database_not_configured';
      }
      if (code.contains('operation-not-allowed')) {
        return 'anonymous_auth_disabled';
      }
      if (code.contains('network-request-failed') ||
          code.contains('unavailable')) {
        return 'network_unavailable';
      }
      if (code.contains('no-app')) return 'firebase_not_initialized';
      return 'firebase_${code.replaceAll('/', '_')}';
    }
    if (error is StateError) return 'room_code_allocation_failed';
    return 'room_creation_failed';
  }

  @override
  Stream<Room> watchRoom(String roomCode) async* {
    final normalizedCode = _normalizeCode(roomCode);
    final userId = await identity.requireUserId();
    final roomRef = _rooms.child(normalizedCode);
    final publicRef = roomRef.child('public');
    final hostSnapshot = await publicRef.child('hostId').get();

    if (hostSnapshot.value == userId) {
      yield* _watchHostRoom(
        normalizedCode,
        publicRef,
        roomRef.child('viewers'),
      );
      return;
    }

    await for (final event in publicRef.onValue) {
      final data = _asMap(event.snapshot.value);
      if (data == null) throw const RoomRepositoryException('room_not_found');
      yield _roomFromMap(normalizedCode, data, const {});
    }
  }

  Stream<Room> _watchHostRoom(
    String roomCode,
    DatabaseReference publicRef,
    DatabaseReference viewersRef,
  ) {
    late final StreamController<Room> controller;
    StreamSubscription<DatabaseEvent>? publicSubscription;
    StreamSubscription<DatabaseEvent>? viewerSubscription;
    Map<String, Object?>? publicData;
    Map<String, RoomViewer> viewers = const {};

    void emitRoom() {
      final data = publicData;
      if (data != null && !controller.isClosed) {
        controller.add(_roomFromMap(roomCode, data, viewers));
      }
    }

    controller = StreamController<Room>(
      onListen: () {
        publicSubscription = publicRef.onValue.listen((event) {
          final data = _asMap(event.snapshot.value);
          if (data == null) {
            controller.addError(
              const RoomRepositoryException('room_not_found'),
            );
            return;
          }
          publicData = data;
          emitRoom();
        }, onError: controller.addError);
        viewerSubscription = viewersRef.onValue.listen((event) {
          viewers = _decodeViewers(_asMap(event.snapshot.value) ?? const {});
          emitRoom();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await publicSubscription?.cancel();
        await viewerSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> updateScoreboard({
    required String roomCode,
    required List<RoomRound> rounds,
    required Map<String, int> scores,
  }) async {
    final now = DateTime.now().toUtc();
    try {
      await _rooms.child(_normalizeCode(roomCode)).child('public').update({
        'rounds': _roundsToMap(rounds),
        'scores': scores,
        'lastActivityAt': now.millisecondsSinceEpoch,
        'expiresAt': now.add(_roomLifetime).millisecondsSinceEpoch,
      });
    } catch (error, stackTrace) {
      await _recordSyncError(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> closeRoom(String roomCode) async {
    try {
      await _rooms.child(_normalizeCode(roomCode)).child('public').update({
        'status': RoomStatus.closed.name,
        'closedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      });
    } catch (error, stackTrace) {
      await _recordSyncError(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addViewer({
    required String roomCode,
    required String viewerId,
    required String name,
  }) async {
    final userId = await identity.requireUserId();
    if (viewerId != userId) {
      throw StateError('A viewer can only register their own identity.');
    }

    final roomRef = _rooms.child(_normalizeCode(roomCode));
    final publicSnapshot = await roomRef.child('public').get();
    final publicData = _asMap(publicSnapshot.value);
    if (publicData == null) {
      throw const RoomRepositoryException('room_not_found');
    }
    final room = _roomFromMap(_normalizeCode(roomCode), publicData, const {});
    if (!room.isJoinableAt(DateTime.now().toUtc())) {
      throw const RoomRepositoryException('room_ended');
    }

    final slotsRef = roomRef.child('slots');
    final viewerRef = roomRef.child('viewers').child(viewerId);
    final existingViewer = _asMap((await viewerRef.get()).value);
    final existingSlot = existingViewer?['slotId'] as String?;
    if (existingSlot != null) {
      await viewerRef.update({'name': name.trim()});
      return;
    }

    await viewerRef.onDisconnect().remove();

    try {
      String? reservedSlot;
      for (var index = 0; index < maxRoomViewers; index++) {
        final slotId = 'slot$index';
        final slotRef = slotsRef.child(slotId);
        await slotRef.onDisconnect().remove();
        final result = await slotRef.runTransaction(
          (currentData) => currentData == null || currentData == viewerId
              ? Transaction.success(viewerId)
              : Transaction.abort(),
          applyLocally: false,
        );
        if (result.committed && result.snapshot.value == viewerId) {
          reservedSlot = slotId;
          break;
        }
        await slotRef.onDisconnect().cancel();
      }
      if (reservedSlot == null) {
        await viewerRef.onDisconnect().cancel();
        throw const RoomRepositoryException('room_full');
      }
      await viewerRef.set({
        'name': name.trim(),
        'joinedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
        'slotId': reservedSlot,
      });
    } catch (error, stackTrace) {
      await _recordSyncError(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeViewer({
    required String roomCode,
    required String viewerId,
  }) async {
    final userId = await identity.requireUserId();
    if (viewerId != userId) {
      throw StateError('A viewer can only remove their own presence.');
    }
    await _removeViewerPresence(
      _rooms.child(_normalizeCode(roomCode)),
      viewerId,
    );
  }

  @override
  Future<void> kickViewer({
    required String roomCode,
    required String viewerId,
  }) async {
    final roomRef = _rooms.child(_normalizeCode(roomCode));
    await roomRef.child('kicked').child(viewerId).set(true);
    await _removeViewerPresence(roomRef, viewerId);
  }

  Future<void> _removeViewerPresence(
    DatabaseReference roomRef,
    String viewerId,
  ) async {
    final viewerRef = roomRef.child('viewers').child(viewerId);
    final snapshot = await viewerRef.get();
    final slotId = _asMap(snapshot.value)?['slotId'] as String?;
    if (slotId != null) await roomRef.child('slots').child(slotId).remove();
    await viewerRef.remove();
  }

  @override
  Future<void> cleanupExpiredRooms() async {
    throw UnsupportedError(
      'Room expiration cleanup must run in a trusted scheduled backend.',
    );
  }

  String _generateRoomCode() => List.generate(
    _roomCodeLength,
    (_) => _roomCodeAlphabet[_random.nextInt(_roomCodeAlphabet.length)],
  ).join();

  String _normalizeCode(String code) => code.trim().toUpperCase();

  Map<String, Object?> _playerToMap(RoomPlayer player) => {
    'id': player.id,
    'name': player.name,
  };

  Map<String, Object?> _roundsToMap(List<RoomRound> rounds) => {
    for (final round in rounds)
      '${round.index}': {
        'scores': round.scores,
        'editedPlayerIds': round.editedPlayerIds.toList(growable: false),
      },
  };

  Room _roomFromMap(
    String code,
    Map<String, Object?> data,
    Map<String, RoomViewer> viewers,
  ) {
    final rawPlayers = data['players'];
    final rawRounds = _asMap(data['rounds']) ?? const <String, Object?>{};
    final rawScores = _asMap(data['scores']) ?? const <String, Object?>{};
    return Room(
      code: code,
      hostId: data['hostId'] as String? ?? '',
      createdAt: _dateFromValue(data['createdAt']),
      lastActivityAt: _dateFromValue(data['lastActivityAt']),
      expiresAt: _dateFromValue(data['expiresAt']),
      status: RoomStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => RoomStatus.expired,
      ),
      players: rawPlayers is List
          ? rawPlayers
                .whereType<Map>()
                .map(
                  (player) => RoomPlayer(
                    id: player['id']?.toString() ?? '',
                    name: player['name'] as String? ?? '',
                  ),
                )
                .toList(growable: false)
          : const [],
      rounds:
          rawRounds.entries
              .map((entry) {
                final roundData =
                    _asMap(entry.value) ?? const <String, Object?>{};
                final roundScores = _asMap(roundData['scores']) ?? const {};
                final editedIds = roundData['editedPlayerIds'];
                return RoomRound(
                  index: int.tryParse(entry.key) ?? 0,
                  scores: roundScores.map(
                    (key, value) => MapEntry(key, _asInt(value)),
                  ),
                  editedPlayerIds: editedIds is List
                      ? editedIds.map((id) => id.toString()).toSet()
                      : const {},
                );
              })
              .toList(growable: false)
            ..sort((a, b) => a.index.compareTo(b.index)),
      scores: rawScores.map((key, value) => MapEntry(key, _asInt(value))),
      viewers: viewers,
    );
  }

  Map<String, RoomViewer> _decodeViewers(Map<String, Object?> data) => {
    for (final entry in data.entries)
      entry.key: RoomViewer(
        id: entry.key,
        name: _asMap(entry.value)?['name'] as String? ?? '',
        joinedAt: _dateFromValue(_asMap(entry.value)?['joinedAt']),
      ),
  };

  Map<String, Object?>? _asMap(Object? value) {
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  int _asInt(Object? value) => value is num ? value.toInt() : 0;

  DateTime _dateFromValue(Object? value) =>
      DateTime.fromMillisecondsSinceEpoch(_asInt(value), isUtc: true);

  Future<void> _recordSyncError(Object error, StackTrace stackTrace) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Room synchronization failed',
      );
    } catch (_) {
      // Crash reporting must not replace the original repository failure.
    }
  }
}
