import 'package:provider/provider.dart';
import 'package:score_tracker/data/firebase/firebase_anonymous_identity.dart';
import 'package:score_tracker/data/firebase/firebase_room_repository.dart';
import 'package:score_tracker/domain/repositories/room_repository.dart';

final roomRepositoryProvider = Provider<RoomRepository>(
  create: (context) =>
      FirebaseRoomRepository(identity: FirebaseAnonymousIdentity()),
);
