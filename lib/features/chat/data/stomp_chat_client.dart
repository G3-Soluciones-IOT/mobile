import 'dart:async';
import 'dart:convert';

import 'package:jameofit/core/microservice_endpoints.dart';
import 'package:jameofit/features/chat/domain/entities/chat_entities.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

abstract class ChatTransport {
  Stream<ChatMessage> get messages;
  Stream<ChatConnectionStatus> get connectionStates;
  bool get isConnected;
  Future<void> connect(String token);
  void send({
    required int recipientUserId,
    required String content,
    required String clientMessageId,
  });
  Future<void> dispose();
}

class StompChatClient implements ChatTransport {
  final _messages = StreamController<ChatMessage>.broadcast();
  final _states = StreamController<ChatConnectionStatus>.broadcast();
  StompClient? _client;
  bool _connected = false;
  bool _disposed = false;

  @override
  Stream<ChatMessage> get messages => _messages.stream;
  @override
  Stream<ChatConnectionStatus> get connectionStates => _states.stream;
  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect(String token) async {
    if (_disposed || _connected || _client != null) return;
    _states.add(ChatConnectionStatus.connecting);
    final headers = {'Authorization': 'Bearer $token'};
    _client = StompClient(
      config: StompConfig.sockJS(
        url: MicroserviceEndpoints.chatWebSocketUrl,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (frame) {
          _connected = true;
          _states.add(ChatConnectionStatus.connected);
          _client?.subscribe(
            destination: '/user/queue/messages',
            callback: (frame) {
              final body = frame.body;
              if (body == null) return;
              try {
                final value = jsonDecode(body);
                if (value is Map<String, dynamic>) {
                  _messages.add(ChatMessage.fromJson(value));
                } else if (value is Map) {
                  _messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(value)));
                }
              } catch (_) {
                // A malformed frame must not take down the active subscription.
              }
            },
          );
        },
        onDisconnect: (_) {
          _connected = false;
          if (!_disposed) _states.add(ChatConnectionStatus.disconnected);
        },
        onStompError: (_) {
          _connected = false;
          if (!_disposed) _states.add(ChatConnectionStatus.error);
        },
        onWebSocketError: (_) {
          _connected = false;
          if (!_disposed) _states.add(ChatConnectionStatus.error);
        },
        onWebSocketDone: () {
          _connected = false;
          if (!_disposed) _states.add(ChatConnectionStatus.disconnected);
        },
      ),
    )..activate();
  }

  @override
  void send({
    required int recipientUserId,
    required String content,
    required String clientMessageId,
  }) {
    if (!_connected || _client == null) throw StateError('El chat no está conectado.');
    _client!.send(
      destination: '/app/chat.send',
      body: jsonEncode({
        'recipientUserId': recipientUserId,
        'content': content,
        'clientMessageId': clientMessageId,
      }),
    );
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _connected = false;
    _client?.deactivate();
    _client = null;
    await _messages.close();
    await _states.close();
  }
}
