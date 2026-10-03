import 'package:score_tracker/domain/models/room.dart';

class RoomRepositoryException implements Exception {
  const RoomRepositoryException(this.code);

  final String code;

  @override
  String toString() => 'RoomRepositoryException($code)';
}

// Backend implementations can be swapped by changing the Provider binding.
abstract interface class RoomRepository {
  Future<String> currentUserId();

  Future<String> createRoom({
    required String hostId,
    required List<RoomPlayer> players,
    required List<RoomRound> rounds,
    required Map<String, int> scores,
  });

  Stream<Room> watchRoom(String roomCode);

  Future<void> updateScoreboard({
    required String roomCode,
    required List<RoomRound> rounds,
    required Map<String, int> scores,
  });

  Future<void> closeRoom(String roomCode);

  Future<void> addViewer({
    required String roomCode,
    required String viewerId,
    required String name,
  });

  Future<void> removeViewer({
    required String roomCode,
    required String viewerId,
  });

  Future<void> kickViewer({required String roomCode, required String viewerId});

  Future<void> cleanupExpiredRooms();
}
