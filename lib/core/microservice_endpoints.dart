import 'package:flutter/foundation.dart';

class MicroserviceEndpoints {
  static String get _host {
    if (kIsWeb) return 'localhost';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      default:
        return 'localhost';
    }
  }

  static String get profilesBaseUrl => 'http://$_host:8082/api/v1';
  static String get goalsBaseUrl => 'http://$_host:8083/api/v1';
  static String get mealPlansBaseUrl => 'http://$_host:8084/api/v1';
  static String get trackingBaseUrl => 'http://$_host:8085/api/v1';
  static String get iotBaseUrl => 'http://$_host:8091/api/v1';

  static String get trackingByUser => '$trackingBaseUrl/tracking/user/{userId}';
  static String get trackingProgress => '$trackingBaseUrl/tracking/user/{userId}/progress';
  static String get trackingGoalByUser => '$trackingBaseUrl/tracking-goals/user/{userId}';
  static String get mealPlansByProfile => '$mealPlansBaseUrl/meal-plan/profile/{profileId}';
  static String get goals => '$goalsBaseUrl/goals';
  static String get profiles => '$profilesBaseUrl/profiles';
  static String get iotDevicesByUser => '$iotBaseUrl/iot/devices/{userId}';
  static String get iotHydrationByUser => '$iotBaseUrl/iot/hydration/{userId}';
  static String get iotHydrationSummary => '$iotBaseUrl/iot/hydration/{userId}/summary';
  static String get iotWeightHistory => '$iotBaseUrl/iot/weight/{userId}/history';
  static String get iotLatestWeight => '$iotBaseUrl/iot/weight/{userId}/latest';
}
