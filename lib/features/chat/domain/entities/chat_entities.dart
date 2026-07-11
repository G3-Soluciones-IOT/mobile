class ChatContact {
  const ChatContact({
    required this.contactUserId,
    required this.relationshipId,
    required this.role,
    required this.displayName,
    required this.username,
    required this.profilePictureUrl,
    required this.accepted,
  });

  final int contactUserId;
  final int relationshipId;
  final String role;
  final String displayName;
  final String username;
  final String? profilePictureUrl;
  final bool accepted;

  factory ChatContact.fromJson(Map<String, dynamic> json) => ChatContact(
    contactUserId: (json['contactUserId'] as num?)?.toInt() ?? 0,
    relationshipId: (json['relationshipId'] as num?)?.toInt() ?? 0,
    role: '${json['role'] ?? ''}',
    displayName: '${json['displayName'] ?? json['username'] ?? 'Contacto'}',
    username: '${json['username'] ?? ''}',
    profilePictureUrl: (json['profilePictureUrl'] as String?)?.trim().isEmpty ?? true
        ? null
        : (json['profilePictureUrl'] as String).trim(),
    accepted: json['accepted'] == true,
  );
}

class ChatMessage {
  const ChatMessage({
    this.id,
    this.conversationId,
    required this.senderUserId,
    required this.recipientUserId,
    required this.content,
    required this.sentAt,
    this.readAt,
    this.clientMessageId,
    this.pending = false,
    this.failed = false,
  });

  final String? id;
  final String? conversationId;
  final int senderUserId;
  final int recipientUserId;
  final String content;
  final DateTime sentAt;
  final DateTime? readAt;
  final String? clientMessageId;
  final bool pending;
  final bool failed;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id']?.toString(),
    conversationId: json['conversationId']?.toString(),
    senderUserId: (json['senderUserId'] as num?)?.toInt() ?? 0,
    recipientUserId: (json['recipientUserId'] as num?)?.toInt() ?? 0,
    content: '${json['content'] ?? ''}',
    sentAt: DateTime.tryParse('${json['sentAt'] ?? ''}')?.toUtc() ?? DateTime.now().toUtc(),
    readAt: json['readAt'] == null ? null : DateTime.tryParse('${json['readAt']}')?.toUtc(),
    clientMessageId: json['clientMessageId']?.toString(),
  );

  ChatMessage copyWith({bool? pending, bool? failed}) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderUserId: senderUserId,
    recipientUserId: recipientUserId,
    content: content,
    sentAt: sentAt,
    readAt: readAt,
    clientMessageId: clientMessageId,
    pending: pending ?? this.pending,
    failed: failed ?? this.failed,
  );
}

enum ChatConnectionStatus { disconnected, connecting, connected, error }
