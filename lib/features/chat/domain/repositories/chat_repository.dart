import 'package:jameofit/features/chat/domain/entities/chat_entities.dart';

abstract class ChatRepository {
  Future<List<ChatContact>> getContacts();
  Future<List<ChatMessage>> getMessages({
    required int contactUserId,
    int limit = 50,
    DateTime? before,
  });
}
