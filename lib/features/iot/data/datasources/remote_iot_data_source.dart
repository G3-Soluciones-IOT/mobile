import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jameofit/core/microservice_endpoints.dart';

class RemoteIoTDataSource {
  const RemoteIoTDataSource({
    http.Client? client,
  }) : _client = client;

  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  String trackingByUserUrl(int userId) {
    return MicroserviceEndpoints.trackingByUser.replaceFirst('{userId}', '$userId');
  }

  String trackingProgressUrl(int userId) {
    return MicroserviceEndpoints.trackingProgress.replaceFirst('{userId}', '$userId');
  }

  String trackingGoalByUserUrl(int userId) {
    return MicroserviceEndpoints.trackingGoalByUser.replaceFirst('{userId}', '$userId');
  }

  String mealPlanEntriesUrl(int trackingId) {
    return '${MicroserviceEndpoints.trackingBaseUrl}/meal-plan-entries/tracking/$trackingId';
  }

  Future<RemoteTrackingSnapshot> fetchTrackingSnapshot(int userId) async {
    final trackingResponse = await client.get(Uri.parse(trackingByUserUrl(userId)));
    if (trackingResponse.statusCode != 200) {
      throw RemoteIoTException('Tracking no disponible para el usuario $userId');
    }

    final trackingMap = jsonDecode(trackingResponse.body) as Map<String, dynamic>;
    final trackingId = (trackingMap['id'] as num).toInt();
    final consumedMacros = _parseMacros(trackingMap['consumedMacros'] as Map<String, dynamic>?);

    RemoteMacros? targetMacros;
    final goalResponse = await client.get(Uri.parse(trackingGoalByUserUrl(userId)));
    if (goalResponse.statusCode == 200) {
      final goalMap = jsonDecode(goalResponse.body) as Map<String, dynamic>;
      targetMacros = _parseMacros(goalMap['targetMacros'] as Map<String, dynamic>?);
    }

    final mealsResponse = await client.get(Uri.parse(mealPlanEntriesUrl(trackingId)));
    final entries = <RemoteMealEntry>[];
    if (mealsResponse.statusCode == 200) {
      final meals = jsonDecode(mealsResponse.body) as List<dynamic>;
      for (final meal in meals) {
        final item = meal as Map<String, dynamic>;
        entries.add(
          RemoteMealEntry(
            id: (item['id'] as num?)?.toInt() ?? 0,
            recipeId: (item['recipeId'] as num?)?.toInt() ?? 0,
            mealPlanType: (item['mealPlanType'] as String?) ?? 'Meal',
            dayNumber: (item['dayNumber'] as num?)?.toInt() ?? 0,
          ),
        );
      }
    }

    return RemoteTrackingSnapshot(
      trackingId: trackingId,
      date: (trackingMap['date'] as String?) ?? '',
      consumed: consumedMacros,
      target: targetMacros,
      entries: entries,
    );
  }

  RemoteMacros _parseMacros(Map<String, dynamic>? map) {
    return RemoteMacros(
      calories: (map?['calories'] as num?)?.toDouble() ?? 0,
      carbs: (map?['carbs'] as num?)?.toDouble() ?? 0,
      proteins: (map?['proteins'] as num?)?.toDouble() ?? 0,
      fats: (map?['fats'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RemoteTrackingSnapshot {
  const RemoteTrackingSnapshot({
    required this.trackingId,
    required this.date,
    required this.consumed,
    required this.target,
    required this.entries,
  });

  final int trackingId;
  final String date;
  final RemoteMacros consumed;
  final RemoteMacros? target;
  final List<RemoteMealEntry> entries;
}

class RemoteMacros {
  const RemoteMacros({
    required this.calories,
    required this.carbs,
    required this.proteins,
    required this.fats,
  });

  final double calories;
  final double carbs;
  final double proteins;
  final double fats;
}

class RemoteMealEntry {
  const RemoteMealEntry({
    required this.id,
    required this.recipeId,
    required this.mealPlanType,
    required this.dayNumber,
  });

  final int id;
  final int recipeId;
  final String mealPlanType;
  final int dayNumber;
}

class RemoteIoTException implements Exception {
  const RemoteIoTException(this.message);

  final String message;

  @override
  String toString() => message;
}
