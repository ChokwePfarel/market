import '../../domain/entities/message_entity.dart';

abstract class ChatEvent {}

class LoadMessages extends ChatEvent {
  final String conversationId;
  final String currentUserId;
  LoadMessages({required this.conversationId, required this.currentUserId});
}

class SendMessage extends ChatEvent {
  final String conversationId;
  final String senderId;
  final String text;
  SendMessage({
    required this.conversationId,
    required this.senderId,
    required this.text,
  });
}

class MessageReceived extends ChatEvent {
  final MessageEntity message;
  MessageReceived(this.message);
}

class ResendQueuedMessages extends ChatEvent {
  final String conversationId;
  ResendQueuedMessages({required this.conversationId});
}

class UpdateMessageStatus extends ChatEvent {
  final String messageId;
  final MessageStatus status;
  UpdateMessageStatus({required this.messageId, required this.status});
}

class deleteMessage extends ChatEvent {
  final String messageId;
  deleteMessage({required this.messageId});
}
