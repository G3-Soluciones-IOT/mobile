import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jameofit/core/microservice_endpoints.dart';
import 'package:jameofit/features/appointments/domain/entities/appointment_entities.dart';

class AppointmentDataSource {
  AppointmentDataSource({
    required this.userId,
    this.authToken,
    http.Client? client,
  }) : _client = client;

  static const _requestTimeout = Duration(seconds: 30);

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

  Future<List<Nutritionist>> getNutritionists() async {
    try {
      final url = MicroserviceEndpoints.nutritionists;
      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        return json.map((item) => Nutritionist.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Nutritionist>> getNutritionistsByUser() async {
    try {
      final url = MicroserviceEndpoints.nutritionistsByUser
          .replaceFirst('{userId}', userId.toString());
      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is List) {
          return json.map((item) => Nutritionist.fromJson(item)).toList();
        } else if (json is Map<String, dynamic>) {
          return [Nutritionist.fromJson(json)];
        }
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<NutritionistPatient> createNutritionistPatient({
    required int nutritionistId,
    required String serviceType,
    required DateTime startDate,
    required DateTime scheduledAt,
  }) async {
    final url = MicroserviceEndpoints.nutritionistPatients;

    final formattedStartDate = startDate.toUtc().toIso8601String().replaceAll('+00:00', 'Z');
    final formattedScheduledAt = scheduledAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z');

    final body = jsonEncode({
      'nutritionistId': nutritionistId,
      'patientUserId': userId,
      'serviceType': serviceType,
      'startDate': formattedStartDate,
      'scheduledAt': formattedScheduledAt,
    });

    final response = await client
        .post(
      Uri.parse(url),
      headers: _headers,
      body: body,
    )
        .timeout(_requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return NutritionistPatient.fromJson(json);
    }

    throw Exception('Error al crear la relación: ${response.statusCode}');
  }

  Future<List<Appointment>> getMyAppointments({
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      String url = MicroserviceEndpoints.appointmentsMe;
      final params = <String, String>{};

      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }
      if (from != null) {
        params['from'] = from.toUtc().toIso8601String().replaceAll('+00:00', 'Z');
      }
      if (to != null) {
        params['to'] = to.toUtc().toIso8601String().replaceAll('+00:00', 'Z');
      }

      if (params.isNotEmpty) {
        url = '$url?${Uri(queryParameters: params).query}';
      }

      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        return json.map((item) => Appointment.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Appointment> createAppointment({
    required int nutritionistPatientId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String reason,
    String? notes,
    String? meetingUrl,
  }) async {
    final url = MicroserviceEndpoints.appointments;

    final formattedDate = scheduledAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z');

    final body = jsonEncode({
      'nutritionistPatientId': nutritionistPatientId,
      'scheduledAt': formattedDate,
      'durationMinutes': durationMinutes,
      'reason': reason,
      'notes': notes ?? '',
      'meetingUrl': meetingUrl ?? 'meeting-${DateTime.now().millisecondsSinceEpoch}',
    });

    final response = await client
        .post(
      Uri.parse(url),
      headers: _headers,
      body: body,
    )
        .timeout(_requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Appointment.fromJson(json);
    }

    throw Exception('Error al crear la cita: ${response.statusCode} - ${response.body}');
  }

  Future<Appointment?> getAppointmentDetail(int appointmentId) async {
    try {
      final url = MicroserviceEndpoints.appointmentById
          .replaceFirst('{id}', appointmentId.toString());
      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Appointment.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<NutritionistPatient>> getNutritionistPatientsByPatient() async {
    try {
      final url = MicroserviceEndpoints.nutritionistPatientsByPatient
          .replaceFirst('{userId}', userId.toString());
      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        return json.map((item) => NutritionistPatient.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
