import 'package:flutter/foundation.dart';

class MicroserviceEndpoints {
  static const _remoteGatewayBaseUrl = String.fromEnvironment(
    'JAMEOFIT_API_BASE_URL',
    defaultValue: 'https://jameofit.duckdns.org',
  );
  static const _useLocalGateway = bool.fromEnvironment(
    'JAMEOFIT_USE_LOCAL_GATEWAY',
    defaultValue: false,
  );

  static String get gatewayBaseUrl =>
      _useLocalGateway ? 'http://$_host:8080' : _remoteGatewayBaseUrl;

  static String get _host {
    if (kIsWeb) return 'localhost';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      default:
        return 'localhost';
    }
  }

  static String get profilesBaseUrl => '$gatewayBaseUrl/api/v1';
  static String get goalsBaseUrl => '$gatewayBaseUrl/api/v1';
  static String get mealPlansBaseUrl => '$gatewayBaseUrl/api/v1';
  static String get trackingBaseUrl => '$gatewayBaseUrl/api/v1';
  static String get iotBaseUrl => '$gatewayBaseUrl/api/v1';
  static String get authenticationBaseUrl =>
      '$gatewayBaseUrl/api/v1/authentication';
  static String get paymentsBaseUrl => '$gatewayBaseUrl/api/v1';
  static String get aiBaseUrl => '$gatewayBaseUrl/api/v1/ai';
  static String get nutritionistBaseUrl => '$gatewayBaseUrl/api/v1';

  static String get trackingByUser => '$trackingBaseUrl/tracking/user/{userId}';
  static String get trackingProgress =>
      '$trackingBaseUrl/tracking/user/{userId}/progress';
  static String get trackingGoalByUser =>
      '$trackingBaseUrl/tracking-goals/user/{userId}';
  static String get mealPlansByProfile =>
      '$mealPlansBaseUrl/meal-plan/profile/{profileId}';
  static String get goals => '$goalsBaseUrl/goals';
  static String get goalCalories => '$goalsBaseUrl/goals/calories';
  static String get goalDietType => '$goalsBaseUrl/goals/diet-type';
  static String get profiles => '$profilesBaseUrl/profiles';
  static String get userProfileByUser =>
      '$profilesBaseUrl/user-profiles/by-user/{userId}';
  static String get userProfiles => '$profilesBaseUrl/user-profiles';
  static String get objectives => '$profilesBaseUrl/objectives';
  static String get allergies => '$profilesBaseUrl/allergies';
  static String get activityLevels => '$profilesBaseUrl/activity-levels';
  static String get signIn => '$authenticationBaseUrl/sign-in';
  static String get signUp => '$authenticationBaseUrl/sign-up';
  static String get iotDevices => '$iotBaseUrl/iot/devices';
  static String get iotDevicesByUser => '$iotBaseUrl/iot/devices/{userId}';
  static String get iotHydrationByUser => '$iotBaseUrl/iot/hydration/{userId}';
  static String get iotHydrationSummary =>
      '$iotBaseUrl/iot/hydration/{userId}/summary';
  static String get iotWeightHistory =>
      '$iotBaseUrl/iot/weight/{userId}/history';
  static String get iotLatestWeight => '$iotBaseUrl/iot/weight/{userId}/latest';

  static String get subscriptions => '$paymentsBaseUrl/subscriptions';
  static String get subscriptionCancel =>
      '$paymentsBaseUrl/subscriptions/{subscriptionId}/cancel';
  static String get subscriptionRenew =>
      '$paymentsBaseUrl/subscriptions/{subscriptionId}/renew';
  static String get subscriptionActive =>
      '$paymentsBaseUrl/subscriptions/users/{userId}/active';
  static String get invoices => '$paymentsBaseUrl/invoices/users/{userId}';
  static String get premiumAccess =>
      '$paymentsBaseUrl/internal/subscriptions/users/{userId}/premium-access';
  static String get createPaymentIntent =>
      '$paymentsBaseUrl/payments/create-intent';

  static String get homeTip => '$aiBaseUrl/home-tip/{userId}';

  static String get nutritionists => '$nutritionistBaseUrl/nutritionists';
  static String get nutritionistsByUser =>
      '$nutritionistBaseUrl/nutritionists/by-user?userId={userId}';
  static String get nutritionistPatients =>
      '$nutritionistBaseUrl/nutritionist-patients';
  static String get nutritionistPatientsByPatient =>
      '$nutritionistBaseUrl/nutritionist-patients/patient/{userId}';
  static String get appointments => '$nutritionistBaseUrl/appointments';
  static String get appointmentsMe => '$nutritionistBaseUrl/appointments/me';
  static String get appointmentById =>
      '$nutritionistBaseUrl/appointments/{id}';

}
