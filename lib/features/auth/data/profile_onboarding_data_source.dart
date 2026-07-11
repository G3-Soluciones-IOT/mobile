import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jameofit/core/microservice_endpoints.dart';

class ProfileOnboardingDataSource {
  const ProfileOnboardingDataSource({
    required this.userId,
    this.authToken,
    http.Client? client,
  }) : _client = client;

  static const _requestTimeout = Duration(seconds: 15);

  final int userId;
  final String? authToken;
  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  Map<String, String> get _headers {
    final token = authToken?.trim();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<PendingOnboarding?> fetchPendingOnboarding() async {
    final responses = await Future.wait([
      _getJsonMap(_userProfileByUserUrl(userId), allowNotFound: true),
      _getJsonMap(_goalByUserUrl(userId), allowNotFound: true),
      _getJsonList(MicroserviceEndpoints.activityLevels),
      _getJsonList(MicroserviceEndpoints.objectives),
      _getJsonList(MicroserviceEndpoints.allergies),
    ]);

    final profileMap = responses[0] as Map<String, dynamic>;
    final goalMap = responses[1] as Map<String, dynamic>;
    final activityLevels = (responses[2] as List<dynamic>)
        .map(
          (item) => CatalogOption.fromActivityLevel(item as Map<String, dynamic>),
        )
        .toList();
    final objectives = (responses[3] as List<dynamic>)
        .map((item) => CatalogOption.fromObjective(item as Map<String, dynamic>))
        .toList();
    final allergies = (responses[4] as List<dynamic>)
        .map((item) => CatalogOption.fromAllergy(item as Map<String, dynamic>))
        .toList();

    final existingProfile = profileMap.isEmpty
        ? null
        : ExistingUserProfile.fromJson(profileMap);
    final existingGoal = goalMap.isEmpty ? null : ExistingGoal.fromJson(goalMap);

    final hasCompleteProfile =
        existingProfile != null && existingProfile.isComplete;
    final hasCompleteGoal = existingGoal != null && existingGoal.isComplete;
    if (hasCompleteProfile && hasCompleteGoal) return null;

    return PendingOnboarding(
      existingProfile: existingProfile,
      existingGoal: existingGoal,
      activityLevels: activityLevels,
      objectives: objectives,
      allergies: allergies,
    );
  }

  Future<void> saveOnboarding(ProfileOnboardingSubmission submission) async {
    final profileBody = jsonEncode({
      'userId': userId,
      'gender': submission.gender,
      'height': submission.heightCm,
      'weight': submission.weightKg,
      'userScore': submission.userScore,
      'activityLevelId': submission.activityLevelId,
      'objectiveId': submission.objectiveId,
      'allergyIds': submission.allergyIds,
      'birthDate': _formatDate(submission.birthDate),
    });

    final profileUrl = submission.profileId == null
        ? MicroserviceEndpoints.userProfiles
        : '${MicroserviceEndpoints.userProfiles}/${submission.profileId}';
    final profileResponse = submission.profileId == null
        ? await _post(profileUrl, body: profileBody)
        : await _put(profileUrl, body: profileBody);
    _ensureSuccess(
      profileResponse,
      profileUrl,
      acceptedStatusCodes: submission.profileId == null ? {201} : {204},
    );

    final goalCaloriesUrl =
        '${MicroserviceEndpoints.goalCalories}?userId=$userId';
    final goalCaloriesResponse = await _put(
      goalCaloriesUrl,
      body: jsonEncode({
        'objective': submission.goalObjective,
        'targetWeightKg': submission.targetWeightKg,
        'pace': submission.goalPace,
      }),
    );
    _ensureSuccess(goalCaloriesResponse, goalCaloriesUrl);

    final goalDietUrl = '${MicroserviceEndpoints.goalDietType}?userId=$userId';
    final goalDietResponse = await _put(
      goalDietUrl,
      body: jsonEncode({'preset': submission.dietPreset}),
    );
    _ensureSuccess(goalDietResponse, goalDietUrl);
  }

  String _userProfileByUserUrl(int userId) {
    return MicroserviceEndpoints.userProfileByUser.replaceFirst(
      '{userId}',
      '$userId',
    );
  }

  String _goalByUserUrl(int userId) {
    return '${MicroserviceEndpoints.goals}?userId=$userId';
  }

  Future<Map<String, dynamic>> _getJsonMap(
    String url, {
    bool allowNotFound = false,
  }) async {
    final response = await _get(url);
    if (allowNotFound && response.statusCode == 404) return <String, dynamic>{};
    _ensureSuccess(response, url);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _getJsonList(String url) async {
    final response = await _get(url);
    _ensureSuccess(response, url);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<http.Response> _get(String url) async {
    try {
      return await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);
    } on Exception {
      throw const ProfileOnboardingException(
        'No se pudo cargar el formulario inicial. Intenta nuevamente.',
      );
    }
  }

  Future<http.Response> _post(String url, {required String body}) async {
    try {
      return await client
          .post(Uri.parse(url), headers: _headers, body: body)
          .timeout(_requestTimeout);
    } on Exception {
      throw const ProfileOnboardingException(
        'No se pudo guardar tu perfil. Intenta nuevamente.',
      );
    }
  }

  Future<http.Response> _put(String url, {required String body}) async {
    try {
      return await client
          .put(Uri.parse(url), headers: _headers, body: body)
          .timeout(_requestTimeout);
    } on Exception {
      throw const ProfileOnboardingException(
        'No se pudo guardar tu perfil. Intenta nuevamente.',
      );
    }
  }

  void _ensureSuccess(
    http.Response response,
    String url, {
    Set<int> acceptedStatusCodes = const {200},
  }) {
    if (acceptedStatusCodes.contains(response.statusCode)) return;

    if (response.statusCode == 400) {
      throw const ProfileOnboardingException(
        'Algunos datos no son válidos. Revisa el formulario.',
      );
    }

    throw ProfileOnboardingException(
      'El backend respondió ${response.statusCode} al procesar $url.',
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class PendingOnboarding {
  const PendingOnboarding({
    required this.existingProfile,
    required this.existingGoal,
    required this.activityLevels,
    required this.objectives,
    required this.allergies,
  });

  final ExistingUserProfile? existingProfile;
  final ExistingGoal? existingGoal;
  final List<CatalogOption> activityLevels;
  final List<CatalogOption> objectives;
  final List<CatalogOption> allergies;
}

class ExistingUserProfile {
  const ExistingUserProfile({
    required this.id,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.userScore,
    required this.birthDate,
    required this.activityLevelId,
    required this.objectiveId,
    required this.allergyNames,
  });

  factory ExistingUserProfile.fromJson(Map<String, dynamic> json) {
    return ExistingUserProfile(
      id: (json['id'] as num?)?.toInt(),
      gender: (json['gender'] as String? ?? '').trim(),
      heightCm: _asDouble(json['height']),
      weightKg: _asDouble(json['weight']),
      userScore: (json['userScore'] as num?)?.toInt() ?? 0,
      birthDate: _parseBirthDate(json['birthDate'] as String?),
      activityLevelId: (json['activityLevelId'] as num?)?.toInt(),
      objectiveId: (json['objectiveId'] as num?)?.toInt(),
      allergyNames: (json['allergyNames'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  final int? id;
  final String gender;
  final double heightCm;
  final double weightKg;
  final int userScore;
  final DateTime? birthDate;
  final int? activityLevelId;
  final int? objectiveId;
  final List<String> allergyNames;

  bool get isComplete =>
      gender.isNotEmpty &&
      heightCm > 0 &&
      weightKg > 0 &&
      birthDate != null &&
      activityLevelId != null &&
      objectiveId != null;
}

class ExistingGoal {
  const ExistingGoal({
    required this.objective,
    required this.targetWeightKg,
    required this.pace,
    required this.dietPreset,
  });

  factory ExistingGoal.fromJson(Map<String, dynamic> json) {
    return ExistingGoal(
      objective: (json['objective'] as String? ?? '').trim(),
      targetWeightKg: _asDouble(json['targetWeightKg']),
      pace: (json['pace'] as String? ?? '').trim(),
      dietPreset: (json['dietPreset'] as String? ?? '').trim(),
    );
  }

  final String objective;
  final double targetWeightKg;
  final String pace;
  final String dietPreset;

  bool get isComplete =>
      objective.isNotEmpty &&
      targetWeightKg > 0 &&
      pace.isNotEmpty &&
      dietPreset.isNotEmpty;
}

class CatalogOption {
  const CatalogOption({
    required this.id,
    required this.label,
    this.description,
    this.goalObjective,
    this.score,
  });

  factory CatalogOption.fromActivityLevel(Map<String, dynamic> json) {
    return CatalogOption(
      id: (json['id'] as num).toInt(),
      label: (json['name'] as String? ?? 'Sin nombre').trim(),
      description: (json['description'] as String? ?? '').trim(),
    );
  }

  factory CatalogOption.fromObjective(Map<String, dynamic> json) {
    final label = (json['objectiveName'] as String? ??
            json['name'] as String? ??
            'Sin objetivo')
        .trim();
    return CatalogOption(
      id: (json['id'] as num).toInt(),
      label: label,
      goalObjective: _mapGoalObjective(label),
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }

  factory CatalogOption.fromAllergy(Map<String, dynamic> json) {
    return CatalogOption(
      id: (json['id'] as num).toInt(),
      label: (json['name'] as String? ?? 'Sin nombre').trim(),
    );
  }

  final int id;
  final String label;
  final String? description;
  final String? goalObjective;
  final int? score;

  static String? _mapGoalObjective(String raw) {
    final normalized = _normalize(raw);
    if (normalized.contains('baj') || normalized.contains('perd')) {
      return 'LOSE_WEIGHT';
    }
    if (normalized.contains('mant')) {
      return 'MAINTAIN_WEIGHT';
    }
    if (normalized.contains('gan') ||
        normalized.contains('masa') ||
        normalized.contains('muscul')) {
      return 'GAIN_MUSCLE';
    }
    return null;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }
}

class ProfileOnboardingSubmission {
  const ProfileOnboardingSubmission({
    required this.profileId,
    required this.gender,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevelId,
    required this.objectiveId,
    required this.userScore,
    required this.allergyIds,
    required this.goalObjective,
    required this.targetWeightKg,
    required this.goalPace,
    required this.dietPreset,
  });

  final int? profileId;
  final String gender;
  final DateTime birthDate;
  final double heightCm;
  final double weightKg;
  final int activityLevelId;
  final int objectiveId;
  final int userScore;
  final List<int> allergyIds;
  final String goalObjective;
  final double targetWeightKg;
  final String goalPace;
  final String dietPreset;
}

class ProfileOnboardingException implements Exception {
  const ProfileOnboardingException(this.message);

  final String message;

  @override
  String toString() => message;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _parseBirthDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final normalized = value.trim();
  final isoDate = DateTime.tryParse(normalized);
  if (isoDate != null) return isoDate;

  final parts = normalized.split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}
