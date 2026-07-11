import 'package:jameofit/features/chat/data/datasources/chat_data_source.dart';
import 'package:jameofit/features/chat/domain/entities/chat_entities.dart';
import 'package:jameofit/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required ChatDataSource dataSource}) : _dataSource = dataSource;
  final ChatDataSource _dataSource;
  @override
  Future<List<ChatContact>> getContacts() => _dataSource.getContacts();
  @override
  Future<List<ChatMessage>> getMessages({required int contactUserId, int limit = 50, DateTime? before}) =>
      _dataSource.getMessages(contactUserId: contactUserId, limit: limit, before: before);
}
