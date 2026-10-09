import '../../domain/entities/conversation_entity.dart';
import 'user_model.dart';

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.userOneId,
    required super.userTwoId,
    super.lastMessage,
    super.lastMessageAt,
    required super.otherUser,
    super.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json, String currentUserId, [int unreadCount = 0]) {
    final userOneJson = json['user_one'];
    final userTwoJson = json['user_two'];
    
    final userOne = userOneJson != null ? UserModel.fromJson(userOneJson) : null;
    final userTwo = userTwoJson != null ? UserModel.fromJson(userTwoJson) : null;

    final otherUser = json['user_one_id'] == currentUserId 
        ? (userTwo ?? userOne!) 
        : (userOne ?? userTwo!);

    return ConversationModel(
      id: json['id'] ?? '',
      userOneId: json['user_one_id'] ?? '',
      userTwoId: json['user_two_id'] ?? '',
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      otherUser: otherUser,
      unreadCount: unreadCount,
    );
  }

  Map<String, dynamic> toJson() {
    final otherUserModel = otherUser is UserModel ? otherUser as UserModel : null;
    final otherUserJson = otherUserModel?.toJson();

    return {
      'id': id,
      'user_one_id': userOneId,
      'user_two_id': userTwoId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      // Store otherUser in the correct slot so fromJson can find it
      'user_one': userOneId == otherUser.id ? otherUserJson : null,
      'user_two': userTwoId == otherUser.id ? otherUserJson : null,
    };
  }

}



