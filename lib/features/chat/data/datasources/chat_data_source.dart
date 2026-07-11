import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jameofit/core/microservice_endpoints.dart';
import 'package:jameofit/features/chat/domain/entities/chat_entities.dart';

class ChatDataSource {
  ChatDataSource({required this.authToken, http.Client? client}) : _client = client;

  static const _timeout = Duration(seconds: 15);
  final String authToken;
  final http.Client? _client;
  http.Client get _http => _client ?? http.Client();
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $authToken',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<List<ChatContact>> getContacts() async {
    final response = await _get(MicroserviceEndpoints.chatContacts);
    final data = _list(response, MicroserviceEndpoints.chatContacts);
    return data
        .whereType<Map>()
        .map((value) => ChatContact.fromJson(Map<String, dynamic>.from(value)))
        .where((contact) => contact.accepted && contact.contactUserId > 0)
        .toList();
  }

  Future<List<ChatMessage>> getMessages({
    required int contactUserId,
    int limit = 50,
    DateTime? before,
  }) async {
    final base = MicroserviceEndpoints.chatConversationMessages.replaceFirst(
      '{contactUserId}', '$contactUserId',
    );
    final parameters = <String, String>{'limit': '$limit'};
    if (before != null) parameters['before'] = before.toUtc().toIso8601String();
    final url = Uri.parse(base).replace(queryParameters: parameters).toString();
    final response = await _get(url);
    return _list(response, url)
        .whereType<Map>()
        .map((value) => ChatMessage.fromJson(Map<String, dynamic>.from(value)))
        .toList();
  }

  Future<http.Response> _get(String url) async {
    try {
      return await _http.get(Uri.parse(url), headers: _headers).timeout(_timeout);
    } on Exception {
      throw const ChatApiException(message: 'No se pudo conectar con el servicio de conversaciones.');
    }
  }

  List<dynamic> _list(http.Response response, String url) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ChatApiException(statusCode: response.statusCode, message: _message(response.body));
    }
    try {
      final value = jsonDecode(response.body);
      if (value is List<dynamic>) return value;
    } on FormatException {}
    throw ChatApiException(message: 'Respuesta inválida del servicio de conversaciones en $url.');
  }

  String _message(String body) {
    try {
      final value = jsonDecode(body);
      if (value is Map && value['message'] != null) return '${value['message']}';
    } catch (_) {}
    return 'No se pudo completar la operación de conversación.';
  }
}

class ChatApiException implements Exception {
  const ChatApiException({this.statusCode, required this.message});
  final int? statusCode;
  final String message;
  @override
  String toString() => message;
}
