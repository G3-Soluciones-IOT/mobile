import 'dart:async';

import 'package:jameofit/features/auth/data/auth_data_source.dart';
import 'package:jameofit/features/chat/data/datasources/chat_data_source.dart';
import 'package:jameofit/features/chat/data/stomp_chat_client.dart';
import 'package:jameofit/features/chat/domain/entities/chat_entities.dart';
import 'package:jameofit/features/chat/domain/repositories/chat_repository.dart';
import 'package:uuid/uuid.dart';

class ChatViewState {
  const ChatViewState({
    this.contacts = const [],
    this.messages = const [],
    this.selectedContact,
    this.isLoadingContacts = false,
    this.isLoadingMessages = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.connectionStatus = ChatConnectionStatus.disconnected,
    this.errorMessage,
    this.unreadContactIds = const {},
  });

  final List<ChatContact> contacts;
  final List<ChatMessage> messages;
  final ChatContact? selectedContact;
  final bool isLoadingContacts;
  final bool isLoadingMessages;
  final bool isLoadingMore;
  final bool hasMore;
  final ChatConnectionStatus connectionStatus;
  final String? errorMessage;
  final Set<int> unreadContactIds;

  ChatViewState copyWith({
    List<ChatContact>? contacts,
    List<ChatMessage>? messages,
    ChatContact? selectedContact,
    bool clearSelectedContact = false,
    bool? isLoadingContacts,
    bool? isLoadingMessages,
    bool? isLoadingMore,
    bool? hasMore,
    ChatConnectionStatus? connectionStatus,
    String? errorMessage,
    bool clearError = false,
    Set<int>? unreadContactIds,
  }) => ChatViewState(
    contacts: contacts ?? this.contacts,
    messages: messages ?? this.messages,
    selectedContact: clearSelectedContact ? null : (selectedContact ?? this.selectedContact),
    isLoadingContacts: isLoadingContacts ?? this.isLoadingContacts,
    isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    connectionStatus: connectionStatus ?? this.connectionStatus,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    unreadContactIds: unreadContactIds ?? this.unreadContactIds,
  );
}

class ChatController {
  ChatController({
    required ChatRepository repository,
    required ChatTransport transport,
    required AuthSession session,
    required void Function() onUnauthorized,
    Uuid? uuid,
  }) : _repository = repository,
       _transport = transport,
       _session = session,
       _onUnauthorized = onUnauthorized,
       _uuid = uuid ?? const Uuid() {
    _messageSubscription = _transport.messages.listen(_onMessage);
    _connectionSubscription = _transport.connectionStates.listen((status) {
      _emit(_state.copyWith(connectionStatus: status));
      if (status == ChatConnectionStatus.disconnected || status == ChatConnectionStatus.error) {
        _markPendingAsFailed();
      }
    });
  }

  final ChatRepository _repository;
  final ChatTransport _transport;
  final AuthSession _session;
  final void Function() _onUnauthorized;
  final Uuid _uuid;
  final _states = StreamController<ChatViewState>.broadcast();
  late final StreamSubscription<ChatMessage> _messageSubscription;
  late final StreamSubscription<ChatConnectionStatus> _connectionSubscription;
  ChatViewState _state = const ChatViewState();
  bool _started = false;

  ChatViewState get state => _state;
  Stream<ChatViewState> get stream => _states.stream;
  int get currentUserId => _session.userId;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await Future.wait([refreshContacts(), _transport.connect(_session.token)]);
  }

  Future<void> refreshContacts() async {
    _emit(_state.copyWith(isLoadingContacts: true, clearError: true));
    try {
      final contacts = await _repository.getContacts();
      final selectedId = _state.selectedContact?.contactUserId;
      final selected = selectedId == null ? null : _find(contacts, selectedId);
      _emit(_state.copyWith(
        contacts: contacts,
        selectedContact: selected,
        clearSelectedContact: selectedId != null && selected == null,
        isLoadingContacts: false,
      ));
    } on ChatApiException catch (error) {
      _handleApiError(error, loadingContacts: true);
    } catch (_) {
      _emit(_state.copyWith(isLoadingContacts: false, errorMessage: 'No se pudieron cargar las conversaciones.'));
    }
  }

  Future<void> openConversation(int contactUserId) async {
    var contact = _find(_state.contacts, contactUserId);
    if (contact == null) {
      await refreshContacts();
      contact = _find(_state.contacts, contactUserId);
    }
    if (contact == null) {
      _emit(_state.copyWith(errorMessage: 'Ya no tienes acceso a esta conversación.'));
      return;
    }
    _emit(_state.copyWith(
      selectedContact: contact,
      messages: const [],
      isLoadingMessages: true,
      hasMore: true,
      clearError: true,
      unreadContactIds: {..._state.unreadContactIds}..remove(contactUserId),
    ));
    try {
      final messages = await _repository.getMessages(contactUserId: contactUserId);
      _emit(_state.copyWith(
        messages: _sortedUnique(messages),
        isLoadingMessages: false,
        hasMore: messages.length == 50,
      ));
    } on ChatApiException catch (error) {
      _handleApiError(error, loadingMessages: true);
    } catch (_) {
      _emit(_state.copyWith(isLoadingMessages: false, errorMessage: 'No se pudo cargar el historial.'));
    }
  }

  Future<void> loadMore() async {
    final contact = _state.selectedContact;
    if (contact == null || _state.isLoadingMore || !_state.hasMore || _state.messages.isEmpty) return;
    _emit(_state.copyWith(isLoadingMore: true));
    try {
      final older = await _repository.getMessages(
        contactUserId: contact.contactUserId,
        before: _state.messages.first.sentAt,
      );
      _emit(_state.copyWith(
        messages: _sortedUnique([...older, ..._state.messages]),
        isLoadingMore: false,
        hasMore: older.length == 50,
      ));
    } on ChatApiException catch (error) {
      _handleApiError(error, loadingMore: true);
    } catch (_) {
      _emit(_state.copyWith(isLoadingMore: false, errorMessage: 'No se pudo cargar más mensajes.'));
    }
  }

  void closeConversation() => _emit(_state.copyWith(clearSelectedContact: true, messages: const [], clearError: true));

  void send(String value) {
    final contact = _state.selectedContact;
    final content = value.trim();
    if (contact == null || content.isEmpty) return;
    final message = ChatMessage(
      senderUserId: _session.userId,
      recipientUserId: contact.contactUserId,
      content: content,
      sentAt: DateTime.now().toUtc(),
      clientMessageId: _uuid.v4(),
      pending: true,
    );
    _emit(_state.copyWith(messages: [..._state.messages, message]));
    try {
      _transport.send(recipientUserId: contact.contactUserId, content: content, clientMessageId: message.clientMessageId!);
    } catch (_) {
      _replaceMessage(message.clientMessageId!, message.copyWith(pending: false, failed: true));
    }
  }

  void retry(ChatMessage message) {
    if (!message.failed || message.clientMessageId == null) return;
    final retrying = message.copyWith(pending: true, failed: false);
    _replaceMessage(message.clientMessageId!, retrying);
    try {
      _transport.send(recipientUserId: message.recipientUserId, content: message.content, clientMessageId: message.clientMessageId!);
    } catch (_) {
      _replaceMessage(message.clientMessageId!, retrying.copyWith(pending: false, failed: true));
    }
  }

  void _onMessage(ChatMessage message) {
    final active = _state.selectedContact;
    final isActive = active != null &&
        (message.senderUserId == active.contactUserId || message.recipientUserId == active.contactUserId);
    if (isActive) {
      final matchingPending = message.clientMessageId != null && _state.messages.any((item) => item.clientMessageId == message.clientMessageId);
      final messages = matchingPending
          ? _state.messages.map((item) => item.clientMessageId == message.clientMessageId ? message : item).toList()
          : _sortedUnique([..._state.messages, message]);
      _emit(_state.copyWith(messages: messages));
      return;
    }
    final otherUserId = message.senderUserId == _session.userId ? message.recipientUserId : message.senderUserId;
    if (_state.contacts.any((contact) => contact.contactUserId == otherUserId)) {
      _emit(_state.copyWith(unreadContactIds: {..._state.unreadContactIds, otherUserId}));
    }
  }

  void _replaceMessage(String clientMessageId, ChatMessage replacement) {
    _emit(_state.copyWith(messages: _state.messages.map((item) => item.clientMessageId == clientMessageId ? replacement : item).toList()));
  }

  void _markPendingAsFailed() {
    if (!_state.messages.any((message) => message.pending)) return;
    _emit(_state.copyWith(
      messages: _state.messages
          .map((message) => message.pending ? message.copyWith(pending: false, failed: true) : message)
          .toList(),
    ));
  }

  List<ChatMessage> _sortedUnique(List<ChatMessage> input) {
    final keys = <String>{};
    final result = <ChatMessage>[];
    for (final item in input) {
      final key = item.id ?? item.clientMessageId ?? '${item.senderUserId}-${item.recipientUserId}-${item.sentAt.microsecondsSinceEpoch}';
      if (keys.add(key)) result.add(item);
    }
    result.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return result;
  }

  ChatContact? _find(List<ChatContact> contacts, int id) {
    for (final contact in contacts) {
      if (contact.contactUserId == id) return contact;
    }
    return null;
  }

  void _handleApiError(ChatApiException error, {bool loadingContacts = false, bool loadingMessages = false, bool loadingMore = false}) {
    if (error.statusCode == 401) {
      _onUnauthorized();
      return;
    }
    final message = error.statusCode == 403
        ? 'Ya no tienes acceso a esta conversación.'
        : error.statusCode == 404
        ? 'El contacto ya no está disponible. Actualiza la lista.'
        : error.message;
    _emit(_state.copyWith(
      isLoadingContacts: loadingContacts ? false : null,
      isLoadingMessages: loadingMessages ? false : null,
      isLoadingMore: loadingMore ? false : null,
      errorMessage: message,
    ));
    if (error.statusCode == 403 || error.statusCode == 404) refreshContacts();
  }

  void _emit(ChatViewState value) {
    _state = value;
    if (!_states.isClosed) _states.add(value);
  }

  Future<void> close() async {
    await _messageSubscription.cancel();
    await _connectionSubscription.cancel();
    await _transport.dispose();
    await _states.close();
  }
}
