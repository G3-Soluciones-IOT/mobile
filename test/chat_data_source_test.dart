import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jameofit/features/chat/data/datasources/chat_data_source.dart';
import 'package:jameofit/features/chat/domain/entities/chat_entities.dart';

void main() {
  test('ChatContact ignores optional image and preserves accepted relation', () {
    final contact = ChatContact.fromJson({
      'contactUserId': 13,
      'relationshipId': 5,
      'role': 'NUTRITIONIST',
      'displayName': 'Jhon A.',
      'username': 'jhon',
      'profilePictureUrl': null,
      'accepted': true,
    });

    expect(contact.contactUserId, 13);
    expect(contact.profilePictureUrl, isNull);
    expect(contact.accepted, isTrue);
  });

  test('contacts send bearer authorization and filters unaccepted records', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/chat/me/contacts');
      expect(request.headers['authorization'], 'Bearer token');
      return http.Response('[{"contactUserId":13,"relationshipId":5,"role":"NUTRITIONIST","displayName":"Ana","username":"ana","accepted":true},{"contactUserId":14,"accepted":false}]', 200);
    });
    final source = ChatDataSource(authToken: 'token', client: client);

    final contacts = await source.getContacts();

    expect(contacts, hasLength(1));
    expect(contacts.single.displayName, 'Ana');
  });

  test('history uses limit and UTC before parameter', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/chat/conversations/13/messages');
      expect(request.url.queryParameters['limit'], '50');
      expect(request.url.queryParameters['before'], '2026-07-11T10:00:00.000Z');
      return http.Response('[]', 200);
    });

    await ChatDataSource(authToken: 'token', client: client).getMessages(
      contactUserId: 13,
      before: DateTime.parse('2026-07-11T10:00:00Z'),
    );
  });

  test('API errors expose HTTP status for presentation mapping', () async {
    final source = ChatDataSource(
      authToken: 'token',
      client: MockClient((_) async => http.Response('{"message":"forbidden"}', 403)),
    );

    expect(
      source.getContacts(),
      throwsA(isA<ChatApiException>().having((error) => error.statusCode, 'statusCode', 403)),
    );
  });
}
