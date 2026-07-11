import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/chat/domain/entities/chat_entities.dart';
import 'package:jameofit/features/chat/presentation/chat_controller.dart';

class CommunicationsPage extends StatefulWidget {
  const CommunicationsPage({super.key, required this.controller});
  final ChatController controller;

  @override
  State<CommunicationsPage> createState() => _CommunicationsPageState();
}

class _CommunicationsPageState extends State<CommunicationsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.start();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<ChatViewState>(
    stream: widget.controller.stream,
    initialData: widget.controller.state,
    builder: (context, snapshot) {
      final state = snapshot.data ?? const ChatViewState();
      if (state.selectedContact != null) {
        return _ConversationView(controller: widget.controller, state: state);
      }
      return _ContactsView(controller: widget.controller, state: state);
    },
  );
}

class _ContactsView extends StatelessWidget {
  const _ContactsView({required this.controller, required this.state});
  final ChatController controller;
  final ChatViewState state;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text('Comunicaciones', style: TextStyle(color: AppTheme.ink, fontSize: 24, fontWeight: FontWeight.w800)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          const Expanded(child: Text('Conversa con tu nutricionista', style: TextStyle(color: AppTheme.muted))),
          _ConnectionIndicator(status: state.connectionStatus),
        ]),
      ),
      if (state.errorMessage != null)
        _ErrorBanner(message: state.errorMessage!, onRetry: controller.refreshContacts),
      Expanded(
        child: state.isLoadingContacts && state.contacts.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
            : RefreshIndicator(
                color: AppTheme.brandGreen,
                onRefresh: controller.refreshContacts,
                child: state.contacts.isEmpty
                    ? ListView(children: const [SizedBox(height: 180), Center(child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text('Aún no tienes nutricionistas aceptados para conversar.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted)),
                      ))])
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        itemCount: state.contacts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final contact = state.contacts[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => controller.openConversation(contact.contactUserId),
                            child: Ink(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8E8E8))),
                              child: Row(children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFEAF8EE),
                                  foregroundImage: contact.profilePictureUrl == null ? null : NetworkImage(contact.profilePictureUrl!),
                                  child: Text(contact.displayName.isEmpty ? '?' : contact.displayName[0].toUpperCase(), style: const TextStyle(color: AppTheme.brandGreen, fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(contact.displayName, style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(contact.role == 'NUTRITIONIST' ? 'Nutricionista' : contact.role, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
                                ])),
                                if (state.unreadContactIds.contains(contact.contactUserId))
                                  const CircleAvatar(radius: 5, backgroundColor: AppTheme.brandGreen),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
      ),
    ],
  );
}

class _ConversationView extends StatefulWidget {
  const _ConversationView({required this.controller, required this.state});
  final ChatController controller;
  final ChatViewState state;

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels < 80) widget.controller.loadMore();
    });
  }

  @override
  void didUpdateWidget(covariant _ConversationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.messages.isEmpty && widget.state.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    widget.controller.send(text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final contact = state.selectedContact!;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 16, 8),
        child: Row(children: [
          IconButton(onPressed: widget.controller.closeConversation, icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink)),
          CircleAvatar(backgroundColor: const Color(0xFFEAF8EE), child: Text(contact.displayName.isEmpty ? '?' : contact.displayName[0].toUpperCase(), style: const TextStyle(color: AppTheme.brandGreen))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(contact.displayName, style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w800, fontSize: 17)),
            Text(_connectionLabel(state.connectionStatus), style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          ])),
        ]),
      ),
      if (state.errorMessage != null) _ErrorBanner(message: state.errorMessage!, onRetry: () => widget.controller.openConversation(contact.contactUserId)),
      Expanded(
        child: state.isLoadingMessages
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0 && state.isLoadingMore) return const Padding(padding: EdgeInsets.all(8), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))));
                  final message = state.messages[index - (state.isLoadingMore ? 1 : 0)];
                  return _MessageBubble(message: message, own: message.senderUserId == widget.controller.currentUserId, onRetry: () => widget.controller.retry(message));
                },
              ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(hintText: 'Escribe un mensaje', filled: true, fillColor: Color(0xFFF6F7F3), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(22)), borderSide: BorderSide.none)),
            )),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _send, style: IconButton.styleFrom(backgroundColor: AppTheme.brandGreen), icon: const Icon(Icons.send_rounded)),
          ]),
        ),
      ),
    ]);
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.own, required this.onRetry});
  final ChatMessage message;
  final bool own;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Align(
    alignment: own ? Alignment.centerRight : Alignment.centerLeft,
    child: GestureDetector(
      onTap: message.failed ? onRetry : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: BoxDecoration(color: own ? AppTheme.brandGreen : const Color(0xFFF1F2EF), borderRadius: BorderRadius.circular(15)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(message.content, style: TextStyle(color: own ? Colors.white : AppTheme.ink)),
          if (message.pending || message.failed) Text(message.failed ? 'No enviado · toca para reintentar' : 'Enviando…', style: TextStyle(color: own ? Colors.white70 : AppTheme.muted, fontSize: 10)),
        ]),
      ),
    ),
  );
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.status});
  final ChatConnectionStatus status;
  @override
  Widget build(BuildContext context) => Text(_connectionLabel(status), style: const TextStyle(color: AppTheme.muted, fontSize: 12));
}

String _connectionLabel(ChatConnectionStatus status) {
  switch (status) {
    case ChatConnectionStatus.connected:
      return 'En línea';
    case ChatConnectionStatus.connecting:
      return 'Conectando…';
    case ChatConnectionStatus.disconnected:
      return 'Sin conexión';
    case ChatConnectionStatus.error:
      return 'Reconectando…';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0), padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFFFFF0EB), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFE66300), fontSize: 13))), TextButton(onPressed: onRetry, child: const Text('Reintentar'))]),
  );
}
