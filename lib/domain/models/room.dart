const maxRoomViewers = 10;

enum RoomStatus { active, closed, expired }

final class Room {
  Room({
    required this.code,
    required this.hostId,
    required this.createdAt,
    required this.lastActivityAt,
    required this.expiresAt,
    required this.status,
    required List<RoomPlayer> players,
    required List<RoomRound> rounds,
    required Map<String, int> scores,
    required Map<String, RoomViewer> viewers,
  }) : players = List.unmodifiable(players),
       rounds = List.unmodifiable(rounds),
       scores = Map.unmodifiable(scores),
       viewers = Map.unmodifiable(viewers);

  final String code;
  final String hostId;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final DateTime expiresAt;
  final RoomStatus status;
  final List<RoomPlayer> players;
  final List<RoomRound> rounds;
  final Map<String, int> scores;
  final Map<String, RoomViewer> viewers;

  bool isJoinableAt(DateTime now) =>
      status == RoomStatus.active && now.isBefore(expiresAt);

  bool canAddViewerAt(DateTime now) =>
      isJoinableAt(now) && viewers.length < maxRoomViewers;
}

final class RoomPlayer {
  const RoomPlayer({required this.id, required this.name});

  final String id;
  final String name;
}

final class RoomRound {
  RoomRound({
    required this.index,
    required Map<String, int> scores,
    Set<String> editedPlayerIds = const <String>{},
  }) : scores = Map.unmodifiable(scores),
       editedPlayerIds = Set.unmodifiable(editedPlayerIds);

  final int index;
  final Map<String, int> scores;
  final Set<String> editedPlayerIds;
}

final class RoomViewer {
  const RoomViewer({
    required this.id,
    required this.name,
    required this.joinedAt,
  });

  final String id;
  final String name;
  final DateTime joinedAt;
}
