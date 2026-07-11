import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jameofit/core/microservice_endpoints.dart';

class CoachDataSource {
  CoachDataSource({
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

  Future<HomeTip?> getHomeTip() async {
    try {
      final url = MicroserviceEndpoints.homeTip
          .replaceFirst('{userId}', userId.toString());

      print('🔍 Obteniendo home tip en: $url');

      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);

      print('📥 Home tip status: ${response.statusCode}');
      print('📥 Home tip body: ${response.body}');

      if (response.statusCode == 204) {
        print('ℹ️ No hay tip disponible (204)');
        return null;
      }

      if (response.statusCode == 403) {
        print('⛔ Usuario no tiene acceso premium (403)');
        return null;
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return HomeTip(
          userId: json['userId'] ?? userId,
          message: json['message'] ?? '',
          period: json['period'] ?? 'DAILY',
          generatedAt: json['generatedAt'] != null
              ? DateTime.parse(json['generatedAt'])
              : DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener home tip: $e');
      return null;
    }
  }
}

class HomeTip {
  const HomeTip({
    required this.userId,
    required this.message,
    required this.period,
    required this.generatedAt,
  });

  final int userId;
  final String message;
  final String period;
  final DateTime generatedAt;
}
