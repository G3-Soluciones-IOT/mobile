import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jameofit/core/microservice_endpoints.dart';
import 'package:jameofit/features/iot/domain/entities/iot_entities.dart';

class RemoteIoTDataSource {
  const RemoteIoTDataSource({
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
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<IoTOverview> fetchOverview() async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(const Duration(days: 6));

    final responses = await Future.wait([
      _getJsonList(_devicesByUserUrl(userId)),
      _getJsonMap(_hydrationSummaryUrl(userId, today)),
      _getJsonList(_hydrationByUserUrl(userId, today)),
      _getJsonMap(_latestWeightUrl(userId), allowNotFound: true),
      _getJsonList(_weightHistoryUrl(userId, weekStart, today)),
      _getJsonList(_hydrationByUserUrl(userId, yesterday), allowNotFound: true),
    ]);

    final devices = responses[0] as List<dynamic>;
    final hydrationSummary = responses[1] as Map<String, dynamic>;
    final hydrationRecords = responses[2] as List<dynamic>;
    final latestWeight = responses[3] as Map<String, dynamic>;
    final weightHistory = responses[4] as List<dynamic>;
    final yesterdayHydrationRecords = responses[5] as List<dynamic>;

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
        isConnected: true,
        sourceLabel: 'iot-service',
        message: 'Datos sincronizados desde IoT service',
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
          title: 'Toma automatica',
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
          : 'Ultima medicion: ${_timeLabel(latestWeight['recordedAt'] as String?)}',
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
              : 'Meta de hidratacion alcanzada hoy. Buen ritmo.',
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
            ? 'Meta de hidratacion cumplida'
            : 'Hidratacion bajo la meta',
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
        SettingToggle(label: 'Alerta de hidratacion baja', enabled: true),
        SettingToggle(label: 'Sincronizacion de peso', enabled: true),
      ],
    );
  }

  IoTSettings _buildSettings(double goalLiters) {
    return IoTSettings(
      deviceToggles: const [
        SettingToggle(label: 'Auto-registro habilitado', enabled: true),
        SettingToggle(label: 'Notificaciones de hidratacion', enabled: true),
      ],
      scaleToggles: const [
        SettingToggle(label: 'Sincronizacion automatica', enabled: true),
        SettingToggle(label: 'Mostrar composicion corporal', enabled: false),
      ],
      tags: {
        'Meta diaria de agua': '${goalLiters.toStringAsFixed(1)} L',
        'Frecuencia de alerta': 'Diaria',
        'Max. sugerencias por dia': '5 mensajes',
      },
    );
  }

  DeviceSetup _buildSetup() {
    return const DeviceSetup(
      searchLabel: 'Buscando dispositivos cerca...',
      steps: [
        SetupStep(
          order: 1,
          title: 'Bluetooth activado en tu telefono',
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
          title: 'Confirmar vinculacion',
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
        title: 'Toma automatica',
        subtitle: 'Sensor de flujo - ${map['deviceId'] ?? 'Bebedor'}',
        value: '${_numValue(map['amountMl']).round()}ml',
        accentHex: 0xFFD9EDFB,
      );
    }).toList();
  }

  HistoryEntry _historyEntryFromWeight(Map<String, dynamic> record) {
    return HistoryEntry(
      time: _timeLabel(record['recordedAt'] as String?),
      title: 'Medicion de peso',
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
    final pending = goalLiters - waterLiters;
    if (pending <= 0) return 'Meta diaria de agua alcanzada';
    return 'Bebe ${pending.toStringAsFixed(1)}L mas para alcanzar tu meta diaria';
  }

  String _weightInsight(List<double> values) {
    if (values.length < 2) {
      return 'Esperando mas mediciones para calcular tendencia';
    }
    final delta = values.last - values.first;
    if (delta.abs() < 0.1) return 'Peso estable esta semana';
    final verb = delta < 0 ? 'bajaste' : 'subiste';
    return 'Tendencia semanal: $verb ${delta.abs().toStringAsFixed(1)}kg';
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
