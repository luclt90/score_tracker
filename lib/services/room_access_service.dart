import 'package:shared_preferences/shared_preferences.dart';

class RoomAccessService {
  Future<bool> hasUsedFreeRoom(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_keyFor(userId)) ?? false;
  }

  Future<void> markFreeRoomUsed(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_keyFor(userId), true);
  }

  String _keyFor(String userId) => 'free_multi_viewer_room_used_$userId';
}
