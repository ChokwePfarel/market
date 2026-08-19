import '../../domain/entities/message_entity.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<MessageEntity> messages;
  final bool isSending;

  ChatLoaded({required this.messages, this.isSending = false});

  ChatLoaded copyWith({List<MessageEntity>? messages, bool? isSending}) =>
      ChatLoaded(
        messages:  messages  ?? this.messages,
        isSending: isSending ?? this.isSending,
      );
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}
