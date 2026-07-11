import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jameofit/core/microservice_endpoints.dart';
import 'package:jameofit/features/iot/domain/entities/iot_entities.dart';

class RemoteIoTDataSource {
  const RemoteIoTDataSource({
    required this.userId,
    this.username,
    this.authToken,
    http.Client? client,
  }) : _client = client;

  static const _requestTimeout = Duration(seconds: 15);

  final int userId;
  final String? username;
  final String? authToken;
  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  Map<String, String> get _headers {
    final token = authToken?.trim();
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<IoTOverview> fetchOverview() async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(const Duration(days: 6));
    var iotUnavailable = false;

    Future<List<dynamic>> safeIoTList(
      String url, {
      bool allowNotFound = false,
    }) async {
      try {
        return await _getJsonList(url, allowNotFound: allowNotFound);
      } on RemoteIoTException {
        iotUnavailable = true;
        return <dynamic>[];
      }
    }

    Future<Map<String, dynamic>> safeIoTMap(
      String url, {
      bool allowNotFound = false,
    }) async {
      try {
        return await _getJsonMap(url, allowNotFound: allowNotFound);
      } on RemoteIoTException {
        iotUnavailable = true;
        return <String, dynamic>{};
      }
    }

    final responses = await Future.wait([
      safeIoTList(_devicesByUserUrl(userId)),
      safeIoTMap(_hydrationSummaryUrl(userId, today)),
      safeIoTList(_hydrationByUserUrl(userId, today)),
      safeIoTMap(_latestWeightUrl(userId), allowNotFound: true),
      safeIoTList(_weightHistoryUrl(userId, weekStart, today)),
      safeIoTList(_hydrationByUserUrl(userId, yesterday), allowNotFound: true),
      _getJsonMap(trackingProgressUrl(userId), allowNotFound: true),
      _getJsonMap(_goalByUserUrl(userId), allowNotFound: true),
      _getJsonMap(_userProfileByUserUrl(userId), allowNotFound: true),
    ]);

    final devices = responses[0] as List<dynamic>;
    final hydrationSummary = responses[1] as Map<String, dynamic>;
    final hydrationRecords = responses[2] as List<dynamic>;
    final latestWeight = responses[3] as Map<String, dynamic>;
    final weightHistory = responses[4] as List<dynamic>;
    final yesterdayHydrationRecords = responses[5] as List<dynamic>;
    final trackingProgress = responses[6] as Map<String, dynamic>;
    final goal = responses[7] as Map<String, dynamic>;
    final userProfile = responses[8] as Map<String, dynamic>;

    final linkedDevices = devices.map(_linkedDeviceFromJson).toList();
    final waterLiters = _numValue(hydrationSummary['totalMl']) / 1000;
    final goalLiters = _numValue(hydrationSummary['goalMl']) / 1000;
    final weightKg = _weightKg(latestWeight);
    final sortedWeights = _sortedByRecordedAt(weightHistory);
    final hydration = _buildHydration(
      hydrationSummary: hydrationSummary,
      records: hydrationRecords,
    );
    final weight = _buildWeight(
      latestWeight: latestWeight,
      weightHistory: sortedWeights,
    );
    final todayEntries = [
      ..._historyEntriesFromHydration(hydrationRecords),
      if (latestWeight.isNotEmpty) _historyEntryFromWeight(latestWeight),
    ]..sort((a, b) => b.time.compareTo(a.time));
    final yesterdayEntries = _historyEntriesFromHydration(
      yesterdayHydrationRecords,
    );

    return IoTOverview(
      userName: 'Usuario $userId',
      liveModeLabel: 'EN DIRECTO',
      integrationStatus: IntegrationStatus(
        isConnected: !iotUnavailable,
        sourceLabel: 'iot-service',
        message: iotUnavailable
            ? 'El servicio IoT no esta disponible temporalmente. Se muestran los datos del perfil y metas.'
            : 'Datos sincronizados desde IoT service',
      ),
      userSummary: _buildUserSummary(
        userProfile: userProfile,
        goal: goal,
        trackingProgress: trackingProgress,
        fallbackWeightKg: weightKg,
      ),
      linkedDevices: linkedDevices,
      dailySummary: DailySummary(
        waterLiters: waterLiters,
        weightKg: weightKg,
        hint: _hydrationHint(waterLiters, goalLiters),
      ),
      hydration: hydration,
      weight: weight,
      coach: _buildCoach(
        waterLiters: waterLiters,
        goalLiters: goalLiters,
        weightKg: weightKg,
      ),
      alertCenter: _buildAlerts(
        waterLiters: waterLiters,
        goalLiters: goalLiters,
        latestWeight: latestWeight,
      ),
      settings: _buildSettings(goalLiters),
      history: HistoryFeed(
        todayLabel: 'HOY - ${todayEntries.length} REGISTROS',
        yesterdayLabel: 'AYER - ${yesterdayEntries.length} REGISTROS',
        todayEntries: todayEntries,
        yesterdayEntries: yesterdayEntries,
      ),
      setup: _buildSetup(),
    );
  }

  String trackingByUserUrl(int userId) {
    return MicroserviceEndpoints.trackingByUser.replaceFirst(
      '{userId}',
      '$userId',
    );
  }

  String trackingProgressUrl(int userId) {
    return MicroserviceEndpoints.trackingProgress.replaceFirst(
      '{userId}',
      '$userId',
    );
  }

  String trackingGoalByUserUrl(int userId) {
    return MicroserviceEndpoints.trackingGoalByUser.replaceFirst(
      '{userId}',
      '$userId',
    );
  }

  String mealPlanEntriesUrl(int trackingId) {
    return '${MicroserviceEndpoints.trackingBaseUrl}/meal-plan-entries/tracking/$trackingId';
  }

  String _goalByUserUrl(int userId) {
    return '${MicroserviceEndpoints.goals}?userId=$userId';
  }

  String _userProfileByUserUrl(int userId) {
    return MicroserviceEndpoints.userProfileByUser.replaceFirst(
      '{userId}',
      '$userId',
    );
  }

  String _devicesByUserUrl(int userId) {
    return MicroserviceEndpoints.iotDevicesByUser.replaceFirst(
      '{userId}',
      '$userId',
    );
  }

  String _hydrationByUserUrl(int userId, DateTime date) {
    final base = MicroserviceEndpoints.iotHydrationByUser.replaceFirst(
      '{userId}',
      '$userId',
    );
    return '$base?date=${_dateParam(date)}';
  }

  String _hydrationSummaryUrl(int userId, DateTime date) {
    final base = MicroserviceEndpoints.iotHydrationSummary.replaceFirst(
      '{userId}',
      '$userId',
    );
    return '$base?date=${_dateParam(date)}';
  }

  String _latestWeightUrl(int userId) {
    return MicroserviceEndpoints.iotLatestWeight.replaceFirst(
      '{userId}',
      '$userId',
    );
  }

  String _weightHistoryUrl(int userId, DateTime from, DateTime to) {
    final base = MicroserviceEndpoints.iotWeightHistory.replaceFirst(
      '{userId}',
      '$userId',
    );
    return '$base?from=${_dateParam(from)}&to=${_dateParam(to)}';
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

  Future<List<dynamic>> _getJsonList(
    String url, {
    bool allowNotFound = false,
  }) async {
    final response = await _get(url);
    if (allowNotFound && response.statusCode == 404) return <dynamic>[];
    _ensureSuccess(response, url);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<http.Response> _get(String url) async {
    try {
      return await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);
    } on Exception {
      throw RemoteIoTException(
        'No se pudo conectar con el backend IoT al consultar $url',
      );
    }
  }

  void _ensureSuccess(http.Response response, String url) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw RemoteIoTException(
      'IoT service respondio ${response.statusCode} al consultar $url',
    );
  }

  Future<RemoteTrackingSnapshot> fetchTrackingSnapshot(int userId) async {
    final trackingResponse = await _get(trackingByUserUrl(userId));
    if (trackingResponse.statusCode != 200) {
      throw RemoteIoTException(
        'Tracking no disponible para el usuario $userId',
      );
    }

    final trackingMap =
        jsonDecode(trackingResponse.body) as Map<String, dynamic>;
    final trackingId = (trackingMap['id'] as num).toInt();
    final consumedMacros = _parseMacros(
      trackingMap['consumedMacros'] as Map<String, dynamic>?,
    );

    RemoteMacros? targetMacros;
    final goalResponse = await _get(trackingGoalByUserUrl(userId));
    if (goalResponse.statusCode == 200) {
      final goalMap = jsonDecode(goalResponse.body) as Map<String, dynamic>;
      targetMacros = _parseMacros(
        goalMap['targetMacros'] as Map<String, dynamic>?,
      );
    }

    final mealsResponse = await _get(mealPlanEntriesUrl(trackingId));
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

  UserSummary _buildUserSummary({
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> goal,
    required Map<String, dynamic> trackingProgress,
    required double fallbackWeightKg,
  }) {
    final consumed =
        trackingProgress['consumed'] as Map<String, dynamic>? ?? {};
    final target = trackingProgress['target'] as Map<String, dynamic>? ?? {};
    final goalObjective = '${goal['objective'] ?? ''}';
    final profileObjective = '${userProfile['objectiveName'] ?? ''}';
    final allergies =
        (userProfile['allergyNames'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .where((item) => item.isNotEmpty)
            .toList();

    return UserSummary(
      displayName: (username?.trim().isNotEmpty ?? false)
          ? username!.trim()
          : 'Usuario $userId',
      objectiveLabel: _friendlyObjective(profileObjective, goalObjective),
      activityLabel: _friendlyText('${userProfile['activityLevelName'] ?? ''}'),
      userScore: (userProfile['userScore'] as num?)?.toInt() ?? 0,
      genderLabel: _friendlyGender('${userProfile['gender'] ?? ''}'),
      ageLabel: _ageLabel(userProfile['birthDate'] as String?),
      heightCm: _normalizeHeightCm(_numValue(userProfile['height'])),
      weightKg: _numValue(userProfile['weight']) > 0
          ? _numValue(userProfile['weight'])
          : fallbackWeightKg,
      targetWeightKg: _numValue(goal['targetWeightKg']),
      dietLabel: _friendlyText('${goal['dietPreset'] ?? ''}'),
      dailyCalories: _numValue(target['calories']),
      macros: [
        MacroStatus(
          label: 'Calorias',
          consumed: _numValue(consumed['calories']),
          target: _numValue(target['calories']),
          unit: 'kcal',
          accentHex: 0xFF16B548,
        ),
        MacroStatus(
          label: 'Carbohidratos',
          consumed: _numValue(consumed['carbs']),
          target: _numValue(target['carbs']),
          unit: 'g',
          accentHex: 0xFF1E9ADF,
        ),
        MacroStatus(
          label: 'Proteinas',
          consumed: _numValue(consumed['proteins']),
          target: _numValue(target['proteins']),
          unit: 'g',
          accentHex: 0xFFA02CC8,
        ),
        MacroStatus(
          label: 'Grasas',
          consumed: _numValue(consumed['fats']),
          target: _numValue(target['fats']),
          unit: 'g',
          accentHex: 0xFFE66300,
        ),
      ],
      allergies: allergies,
    );
  }

  LinkedDevice _linkedDeviceFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    final type = '${map['deviceType'] ?? ''}';
    final isBottle = type.contains('BOTTLE');
    final active = '${map['status'] ?? ''}' == 'ACTIVE';
    final lastSeen = map['lastSeenAt'] as String?;
    return LinkedDevice(
      name: isBottle ? 'Bebedor Inteligente' : 'Balanza Inteligente',
      type: isBottle ? 'Smart Bottle' : 'Smart Scale',
      status: active ? 'Activo' : 'Inactivo',
      lastSync: lastSeen == null
          ? 'Registrado'
          : 'Ultima sinc. ${_timeLabel(lastSeen)}',
      battery: 100,
      accentHex: isBottle ? 0xFF16B548 : 0xFF1E9ADF,
    );
  }

  HydrationDetail _buildHydration({
    required Map<String, dynamic> hydrationSummary,
    required List<dynamic> records,
  }) {
    final totalLiters = _numValue(hydrationSummary['totalMl']) / 1000;
    final goalLiters = _numValue(hydrationSummary['goalMl']) / 1000;
    final percent = _numValue(hydrationSummary['progressPercentage']).round();
    return HydrationDetail(
      consumedLiters: totalLiters,
      goalLiters: goalLiters,
      goalPercent: percent,
      statusLabel: 'Sincronizado',
      reminder: _hydrationHint(totalLiters, goalLiters),
      records: _sortedByRecordedAt(records).map((record) {
        final map = record as Map<String, dynamic>;
        return HydrationRecord(
          time: _timeLabel(map['recordedAt'] as String?),
          title: 'Toma automática',
          subtitle: 'Registrado por ${map['deviceId'] ?? 'dispositivo IoT'}',
          amountMl: _numValue(map['amountMl']).round(),
        );
      }).toList(),
    );
  }

  WeightDetail _buildWeight({
    required Map<String, dynamic> latestWeight,
    required List<dynamic> weightHistory,
  }) {
    final values = weightHistory
        .map((record) => _weightKg(record as Map<String, dynamic>))
        .where((value) => value > 0)
        .toList();
    final currentWeight = _weightKg(latestWeight);
    final chartValues = values.isEmpty ? [currentWeight] : values;
    final weekValues = chartValues.length == 1
        ? [chartValues.first, chartValues.first]
        : chartValues;
    return WeightDetail(
      weightKg: currentWeight,
      imc: currentWeight > 0 ? currentWeight / (1.74 * 1.74) : 0,
      lastMeasurement: latestWeight.isEmpty
          ? 'Sin mediciones registradas'
          : 'Última medición: ${_timeLabel(latestWeight['recordedAt'] as String?)}',
      weekLabels: _weekLabels(weekValues.length),
      weekValues: weekValues,
      composition: const [
        BodyCompositionMetric(
          label: 'Masa muscular',
          percent: 0,
          accentHex: 0xFF16B548,
        ),
        BodyCompositionMetric(
          label: 'Masa grasa',
          percent: 0,
          accentHex: 0xFF1E9ADF,
        ),
        BodyCompositionMetric(
          label: 'Agua corporal',
          percent: 0,
          accentHex: 0xFFA02CC8,
        ),
      ],
      insight: _weightInsight(values),
    );
  }

  CoachConversation _buildCoach({
    required double waterLiters,
    required double goalLiters,
    required double weightKg,
  }) {
    final pending = (goalLiters - waterLiters).clamp(0, double.infinity);
    return CoachConversation(
      status: 'Con datos IoT',
      messages: [
        CoachMessage(
          text: pending > 0
              ? 'Hoy llevas ${waterLiters.toStringAsFixed(1)}L. Te faltan ${pending.toStringAsFixed(1)}L para llegar a tu meta.'
              : 'Meta de hidratación alcanzada hoy. Buen ritmo.',
          isAssistant: true,
        ),
        CoachMessage(
          text: weightKg > 0
              ? 'Tu ultimo peso registrado es ${weightKg.toStringAsFixed(1)}kg. Usare ese dato para ajustar recomendaciones.'
              : 'Aun no hay peso sincronizado desde la balanza.',
          isAssistant: true,
        ),
      ],
    );
  }

  AlertCenter _buildAlerts({
    required double waterLiters,
    required double goalLiters,
    required Map<String, dynamic> latestWeight,
  }) {
    final notifications = <AlertNotification>[
      AlertNotification(
        title: waterLiters >= goalLiters
            ? 'Meta de hidratación cumplida'
            : 'Hidratación bajo la meta',
        subtitle:
            '${waterLiters.toStringAsFixed(1)}L de ${goalLiters.toStringAsFixed(1)}L',
        timeLabel: 'Hoy',
        accentHex: waterLiters >= goalLiters ? 0xFFCFEFDB : 0xFFFFCC7A,
      ),
      if (latestWeight.isNotEmpty)
        AlertNotification(
          title: 'Peso sincronizado',
          subtitle: '${_weightKg(latestWeight).toStringAsFixed(1)}kg - Balanza',
          timeLabel: _timeLabel(latestWeight['recordedAt'] as String?),
          accentHex: 0xFFD9EDFB,
        ),
    ];
    return AlertCenter(
      summary: '${notifications.length} notificaciones hoy',
      notifications: notifications,
      toggles: const [
        SettingToggle(label: 'Alerta de hidratación baja', enabled: true),
        SettingToggle(label: 'Sincronización de peso', enabled: true),
      ],
    );
  }

  IoTSettings _buildSettings(double goalLiters) {
    return IoTSettings(
      deviceToggles: const [
        SettingToggle(label: 'Auto-registro habilitado', enabled: true),
        SettingToggle(label: 'Notificaciones de hidratación', enabled: true),
      ],
      scaleToggles: const [
        SettingToggle(label: 'Sincronización automática', enabled: true),
        SettingToggle(label: 'Mostrar composicion corporal', enabled: false),
      ],
      tags: {
        'Meta diaria de agua': '${goalLiters.toStringAsFixed(1)} L',
        'Frecuencia de alerta': 'Diaria',
        'Máx. sugerencias por día': '5 mensajes',
      },
    );
  }

  DeviceSetup _buildSetup() {
    return const DeviceSetup(
      searchLabel: 'Buscando dispositivos cerca...',
      steps: [
        SetupStep(
          order: 1,
          title: 'Bluetooth activado en tu teléfono',
          isDone: true,
          isActive: false,
        ),
        SetupStep(
          order: 2,
          title: 'Dispositivo en modo de emparejamiento',
          isDone: true,
          isActive: false,
        ),
        SetupStep(
          order: 3,
          title: 'Selecciona tu dispositivo',
          isDone: false,
          isActive: true,
        ),
        SetupStep(
          order: 4,
          title: 'Confirmar vinculación',
          isDone: false,
          isActive: false,
        ),
      ],
      foundDevice: LinkedDevice(
        name: 'JameoFit Bottle S1',
        type: 'Bebedor inteligente',
        status: 'Encontrado',
        lastSync: 'Listo para conectar',
        battery: 100,
        accentHex: 0xFF16B548,
      ),
    );
  }

  List<HistoryEntry> _historyEntriesFromHydration(List<dynamic> records) {
    return _sortedByRecordedAt(records).map((record) {
      final map = record as Map<String, dynamic>;
      return HistoryEntry(
        time: _timeLabel(map['recordedAt'] as String?),
        title: 'Toma automática',
        subtitle: 'Sensor de flujo - ${map['deviceId'] ?? 'Bebedor'}',
        value: '${_numValue(map['amountMl']).round()}ml',
        accentHex: 0xFFD9EDFB,
      );
    }).toList();
  }

  HistoryEntry _historyEntryFromWeight(Map<String, dynamic> record) {
    return HistoryEntry(
      time: _timeLabel(record['recordedAt'] as String?),
      title: 'Medición de peso',
      subtitle: 'Balanza inteligente - ${record['deviceId'] ?? 'IoT'}',
      value: '${_weightKg(record).toStringAsFixed(1)}kg',
      accentHex: 0xFFCFEFDB,
    );
  }

  List<dynamic> _sortedByRecordedAt(List<dynamic> records) {
    final sorted = [...records];
    sorted.sort((a, b) {
      final aDate =
          DateTime.tryParse(
            (a as Map<String, dynamic>)['recordedAt'] as String? ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          DateTime.tryParse(
            (b as Map<String, dynamic>)['recordedAt'] as String? ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });
    return sorted;
  }

  String _hydrationHint(double waterLiters, double goalLiters) {
    if (goalLiters <= 0) {
      return 'Configura tu meta diaria de agua para ver recomendaciones.';
    }
    final pending = goalLiters - waterLiters;
    if (pending <= 0) return 'Meta diaria de agua alcanzada';
    return 'Bebe ${pending.toStringAsFixed(1)}L más para alcanzar tu meta diaria';
  }

  String _weightInsight(List<double> values) {
    if (values.length < 2) {
      return 'Esperando más mediciones para calcular tendencia';
    }
    final delta = values.last - values.first;
    if (delta.abs() < 0.1) return 'Peso estable esta semana';
    final verb = delta < 0 ? 'bajaste' : 'subiste';
    return 'Tendencia semanal: $verb ${delta.abs().toStringAsFixed(1)}kg';
  }

  String _friendlyText(String raw) {
    if (raw.isEmpty) return 'Sin definir';
    return raw
        .split('_')
        .map(
          (token) => token.isEmpty
              ? token
              : '${token[0]}${token.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _friendlyObjective(String profileObjective, String goalObjective) {
    if (profileObjective.isNotEmpty) return profileObjective;
    switch (goalObjective) {
      case 'LOSE_WEIGHT':
        return 'Perder peso';
      case 'GAIN_MUSCLE':
        return 'Ganar musculo';
      case 'MAINTAIN_WEIGHT':
        return 'Mantener peso';
      default:
        return 'Sin objetivo';
    }
  }

  String _friendlyGender(String raw) {
    switch (raw.toUpperCase()) {
      case 'MALE':
        return 'Masculino';
      case 'FEMALE':
        return 'Femenino';
      default:
        return raw.isEmpty ? 'Sin definir' : _friendlyText(raw);
    }
  }

  String _ageLabel(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return 'Edad no registrada';
    final date = _parseBirthDate(birthDate);
    if (date == null) return 'Edad no registrada';
    final now = DateTime.now();
    var age = now.year - date.year;
    final birthdayPending =
        now.month < date.month ||
        (now.month == date.month && now.day < date.day);
    if (birthdayPending) age--;
    return '$age años';
  }

  DateTime? _parseBirthDate(String raw) {
    final isoDate = DateTime.tryParse(raw);
    if (isoDate != null) return isoDate;

    final parts = raw.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    return DateTime(year, month, day);
  }

  double _normalizeHeightCm(double rawHeight) {
    if (rawHeight <= 0) return 0;
    if (rawHeight <= 3) return rawHeight * 100;
    return rawHeight;
  }

  List<String> _weekLabels(int length) {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    if (length <= 0) return const ['Hoy'];
    if (length >= labels.length) return labels;
    return labels.sublist(labels.length - length);
  }

  double _weightKg(Map<String, dynamic> map) {
    return _numValue(map['grams']) / 1000;
  }

  double _numValue(dynamic value) {
    return (value as num?)?.toDouble() ?? 0;
  }

  String _dateParam(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _timeLabel(String? value) {
    if (value == null || value.isEmpty) return '--:--';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '--:--';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
