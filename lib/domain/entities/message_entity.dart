import 'package:equatable/equatable.dart';

enum MessageStatus { pending, sent, error }

class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final bool isRead;
  final DateTime createdAt;
  final MessageStatus status;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.isRead,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? text,
    bool? isRead,
    DateTime? createdAt,
    MessageStatus? status,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, conversationId, senderId, text, isRead, createdAt, status];
}
