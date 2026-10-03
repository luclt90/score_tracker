import 'package:flutter_test/flutter_test.dart';
import 'package:score_tracker/domain/models/room.dart';

void main() {
  group('Room', () {
    final now = DateTime.utc(2026, 9, 27);

    test('is joinable only while active and before expiry', () {
      final activeRoom = _room(expiresAt: now.add(const Duration(hours: 1)));
      final closedRoom = _room(
        status: RoomStatus.closed,
        expiresAt: now.add(const Duration(hours: 1)),
      );
      final expiredRoom = _room(expiresAt: now);

      expect(activeRoom.isJoinableAt(now), isTrue);
      expect(closedRoom.isJoinableAt(now), isFalse);
      expect(expiredRoom.isJoinableAt(now), isFalse);
    });

    test('allows no more than ten viewers', () {
      final fullRoom = _room(
        expiresAt: now.add(const Duration(hours: 1)),
        viewers: {
          for (var index = 0; index < maxRoomViewers; index++)
            'viewer-$index': RoomViewer(
              id: 'viewer-$index',
              name: 'Viewer $index',
              joinedAt: now,
            ),
        },
      );

      expect(fullRoom.canAddViewerAt(now), isFalse);
      expect(
        _room(expiresAt: now.add(const Duration(hours: 1))).canAddViewerAt(now),
        isTrue,
      );
    });

    test('preserves round scores and edited player metadata', () {
      final round = RoomRound(
        index: 3,
        scores: const {'player-1': 8, 'player-2': -2},
        editedPlayerIds: const {'player-2'},
      );

      expect(round.scores['player-2'], -2);
      expect(round.editedPlayerIds, contains('player-2'));
      expect(() => round.scores['player-1'] = 10, throwsUnsupportedError);
    });
  });
}

Room _room({
  RoomStatus status = RoomStatus.active,
  required DateTime expiresAt,
  Map<String, RoomViewer> viewers = const {},
}) {
  final createdAt = DateTime.utc(
    2026,
    9,
    27,
  ).subtract(const Duration(hours: 1));
  return Room(
    code: 'ABC234',
    hostId: 'host-1',
    createdAt: createdAt,
    lastActivityAt: createdAt,
    expiresAt: expiresAt,
    status: status,
    players: const [RoomPlayer(id: 'player-1', name: 'Alex')],
    rounds: const [],
    scores: const {'player-1': 8},
    viewers: viewers,
  );
}
