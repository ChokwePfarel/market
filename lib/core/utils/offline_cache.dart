import 'package:flutter/cupertino.dart';
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

  // Hive deserializes nested maps as Map<dynamic, dynamic>.
  // This recursively casts any map/list structure to Map<String, dynamic>
  // so every fromJson factory receives the type it expects.
  static Map<String, dynamic> _deepCast(dynamic raw) {
    if (raw is! Map) return {};
    final map = Map<String, dynamic>.from(raw);
    return map.map((key, value) {
      if (value is Map) return MapEntry(key, _deepCast(value));
      if (value is List) return MapEntry(key, _deepCastList(value));
      return MapEntry(key, value);
    });
  }

  static List<dynamic> _deepCastList(List raw) {
    return raw.map((item) {
      if (item is Map) return _deepCast(item);
      if (item is List) return _deepCastList(item);
      return item;
    }).toList();
  }

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      await _openBoxes();
      debugPrint('OfflineCache: Hive initialized and boxes opened.');
    } catch (e) {
      debugPrint('OfflineCache: Initialization error: $e');
    }
  }

  static Future<void> _openBoxes() async {
    if (!Hive.isBoxOpen(_messagesBox)) await Hive.openBox(_messagesBox);
    if (!Hive.isBoxOpen(_conversationsBox)) await Hive.openBox(_conversationsBox);
    if (!Hive.isBoxOpen(_productsBox)) await Hive.openBox(_productsBox);
    if (!Hive.isBoxOpen(_queueBox)) await Hive.openBox(_queueBox);
  }

  static Future<void> clearAll() async {
    try {
      await Hive.box(_messagesBox).clear();
      await Hive.box(_conversationsBox).clear();
      await Hive.box(_productsBox).clear();
      await Hive.box(_queueBox).clear();
      debugPrint('OfflineCache: All boxes cleared.');
    } catch (e) {
      debugPrint('OfflineCache: Clear error: $e');
    }
  }

  // ─── Messages ─────────────────────────────────────────────────────────────

  static List<MessageEntity> getCachedMessages(String conversationId) {
    if (!Hive.isBoxOpen(_messagesBox)) return [];
    final box = Hive.box(_messagesBox);
    final List? data = box.get(conversationId);
    if (data == null) return [];
    return data.map((e) => MessageModel.fromJson(_deepCast(e))).toList();
  }

  static Future<void> cacheMessageHistory(String conversationId, List<MessageModel> messages) async {
    await _openBoxes();
    final box = Hive.box(_messagesBox);
    final data = messages.map((m) => m.toJson()).toList();
    await box.put(conversationId, data);
  }

  // ─── Message Queue ────────────────────────────────────────────────────────

  static List<MessageEntity> getQueuedMessages(String conversationId) {
    if (!Hive.isBoxOpen(_queueBox)) return [];
    final box = Hive.box(_queueBox);
    final List? data = box.get(conversationId);
    if (data == null) return [];
    return data.map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> enqueueMessage(MessageEntity message) async {
    await _openBoxes();
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
    await _openBoxes();
    final box = Hive.box(_queueBox);
    final List current = box.get(conversationId, defaultValue: []);
    current.removeWhere((m) => m['id'] == tempId);
    await box.put(conversationId, current);
  }

  // ─── Conversations ────────────────────────────────────────────────────────

  static List<ConversationEntity> getCachedConversations(String userId) {
    if (!Hive.isBoxOpen(_conversationsBox)) return [];
    final box = Hive.box(_conversationsBox);
    final List? data = box.get('inbox_$userId');
    if (data == null) return [];
    return data
        .map((json) => ConversationModel.fromJson(_deepCast(json), userId))
        .toList();
  }

  static Future<void> cacheConversations(String userId, List<ConversationModel> conversations) async {
    await _openBoxes();
    final box = Hive.box(_conversationsBox);
    final data = conversations.map((c) => c.toJson()).toList();
    await box.put('inbox_$userId', data);
  }

  // ─── Products ─────────────────────────────────────────────────────────────

  static List<ProductEntity> getCachedProducts(String key) {
    if (!Hive.isBoxOpen(_productsBox)) return [];
    final box = Hive.box(_productsBox);
    final List? data = box.get(key);
    if (data == null) return [];
    return data.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> cacheProducts(String key, List<ProductEntity> products) async {
    await _openBoxes();
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

