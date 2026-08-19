import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/conversation_model.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../data/models/message_model.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/models/product_model.dart';

class OfflineCache {
  static const String _messagesBox = 'messages';
  static const String _conversationsBox = 'conversations';
  static const String _productsBox = 'products';
  static const String _queueBox = 'message_queue';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_messagesBox);
    await Hive.openBox(_conversationsBox);
    await Hive.openBox(_productsBox);
    await Hive.openBox(_queueBox);
  }

  // ─── Messages ─────────────────────────────────────────────────────────────

  static List<MessageEntity> getCachedMessages(String conversationId) {
    final box = Hive.box(_messagesBox);
    final List? data = box.get(conversationId);
    if (data == null) return [];
    return data.map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> cacheMessageHistory(String conversationId, List<MessageModel> messages) async {
    final box = Hive.box(_messagesBox);
    final data = messages.map((m) => m.toJson()).toList();
    await box.put(conversationId, data);
  }

  // ─── Message Queue ────────────────────────────────────────────────────────

  static List<MessageEntity> getQueuedMessages(String conversationId) {
    final box = Hive.box(_queueBox);
    final List? data = box.get(conversationId);
    if (data == null) return [];
    return data.map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> enqueueMessage(MessageEntity message) async {
    final box = Hive.box(_queueBox);
    final String convId = message.conversationId;
    final List current = box.get(convId, defaultValue: []);
    
    // Convert to model if it's not already, for toJson
    final model = message is MessageModel ? message : MessageModel(
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      text: message.text,
      isRead: message.isRead,
      createdAt: message.createdAt,
    );

    current.add(model.toJson());
    await box.put(convId, current);
  }

  static Future<void> dequeueMessage(String conversationId, String tempId) async {
    final box = Hive.box(_queueBox);
    final List current = box.get(conversationId, defaultValue: []);
    current.removeWhere((m) => m['id'] == tempId);
    await box.put(conversationId, current);
  }

  // ─── Conversations ────────────────────────────────────────────────────────

  static List<ConversationEntity> getCachedConversations(String userId) {
    final box = Hive.box(_conversationsBox);
    final List? data = box.get(userId);
    if (data == null) return [];
    // Note: unreadCount isn't stored here easily without extra logic
    return data.map((e) => ConversationModel.fromJson(Map<String, dynamic>.from(e), userId)).toList();
  }

  static Future<void> cacheConversations(String userId, List<ConversationModel> conversations) async {
    final box = Hive.box(_conversationsBox);
    final data = conversations.map((c) => c.toJson()).toList();
    await box.put(userId, data);
  }

  // ─── Products ─────────────────────────────────────────────────────────────

  static List<ProductEntity> getCachedProducts(String key) {
    final box = Hive.box(_productsBox);
    final List? data = box.get(key);
    if (data == null) return [];
    return data.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> cacheProducts(String key, List<ProductEntity> products) async {
    final box = Hive.box(_productsBox);
    final data = products.map((p) {
      if (p is ProductModel) return p.toJson();
      return ProductModel(
        id: p.id,
        name: p.name,
        description: p.description,
        price: p.price,
        category: p.category,
        university: p.university,
        imageUrls: p.imageUrls,
        sellerId: p.sellerId,
        status: p.status,
        createdAt: p.createdAt,
      ).toJson();
    }).toList();
    await box.put(key, data);
  }
}
