import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

class RoomAnalyticsService {
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (_) {
      // Analytics must not interrupt room or purchase flows.
    }
  }
}
