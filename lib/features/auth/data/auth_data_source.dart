import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:jameofit/core/microservice_endpoints.dart';

class AuthDataSource {
  const AuthDataSource({http.Client? client}) : _client = client;

  static const _requestTimeout = Duration(seconds: 15);

  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async {
    late final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse(MicroserviceEndpoints.signIn),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(_requestTimeout);
    } catch (error, stackTrace) {
      debugPrint('Auth sign-in error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw AuthException(
        'No se pudo conectar con el backend de autenticacion. Detalle: ${error.runtimeType}. Revisa la consola de Flutter.',
      );
    }

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthSession(
        userId: (json['id'] as num).toInt(),
        username: (json['username'] as String?) ?? username.trim(),
        token: (json['token'] as String?) ?? '',
      );
    }

    if (response.statusCode == 404) {
      throw const AuthException('Usuario o contrasena incorrectos.');
    }

    throw AuthException(
      'No se pudo iniciar sesion. Backend respondio ${response.statusCode}.',
    );
  }

  Future<AuthSession> signUp({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    late final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse(MicroserviceEndpoints.signUp),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'username': normalizedUsername,
              'password': password,
              'roles': const ['ROLE_CUSTOMER'],
            }),
          )
          .timeout(_requestTimeout);
    } catch (error, stackTrace) {
      debugPrint('Auth sign-up error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw AuthException(
        'No se pudo conectar con el backend de autenticacion. Detalle: ${error.runtimeType}. Revisa la consola de Flutter.',
      );
    }

    if (response.statusCode == 201) {
      return signIn(username: normalizedUsername, password: password);
    }

    if (response.statusCode == 400) {
      throw const AuthException(
        'No se pudo registrar el usuario. Verifica si ya existe o si la contrasena tiene al menos 8 caracteres.',
      );
    }

    throw AuthException(
      'No se pudo crear la cuenta. Backend respondio ${response.statusCode}.',
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.username,
    required this.token,
  });

  final int userId;
  final String username;
  final String token;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
