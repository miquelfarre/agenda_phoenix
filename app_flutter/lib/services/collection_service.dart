import 'package:hive_ce/hive.dart';
import '../models/event_collection.dart';
import '../models/event_collection_hive.dart';
import 'api_client.dart';
import '../utils/app_exceptions.dart';
import 'sync_service.dart';

class CollectionService {
  static final CollectionService _instance = CollectionService._internal();
  factory CollectionService() => _instance;
  CollectionService._internal();

  static const String _boxName = 'event_collections';
  Box<EventCollectionHive>? _box;

  Future<void> initialize() async {
    try {
      _box = Hive.isBoxOpen(_boxName)
          ? Hive.box<EventCollectionHive>(_boxName)
          : await Hive.openBox<EventCollectionHive>(_boxName);
    } catch (e) {
      rethrow;
    }
  }

  List<EventCollection> getLocalCollections() {
    if (_box == null) {
      return [];
    }

    try {
      return _box!.values
          .map((hive) => hive.toEventCollection())
          .where((collection) => !collection.isDeleted)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      return [];
    }
  }

  EventCollection? getLocalCollection(String id) {
    if (_box == null) return null;

    try {
      final hive = _box!.get(id);
      final collection = hive?.toEventCollection();
      return (collection?.isDeleted == false) ? collection : null;
    } catch (e) {
      return null;
    }
  }

  List<EventCollection> getCollectionsOwnedBy(String userId) {
    return getLocalCollections()
        .where((collection) => collection.isOwnedBy(userId))
        .toList();
  }

  List<EventCollection> getCollectionsSharedWith(String userId) {
    return getLocalCollections()
        .where((collection) => collection.isSharedWith(userId))
        .toList();
  }

  List<EventCollection> getPublicCollections() {
    return getLocalCollections()
        .where((collection) => collection.isPublic)
        .toList();
  }

  List<EventCollection> getCollectionsAccessibleBy(String userId) {
    return getLocalCollections()
        .where((collection) => collection.hasAccessBy(userId))
        .toList();
  }

  List<EventCollection> getCollectionsContainingEvent(String eventId) {
    return getLocalCollections()
        .where((collection) => collection.containsEvent(eventId))
        .toList();
  }

  Future<List<EventCollection>> fetchCollections() async {
    try {
      final response = await ApiClientFactory.instance.get(
        '/api/v1/event-collections',
      );
      final collections = <EventCollection>[];

      for (final item in response as List) {
        final collection = EventCollection.fromJson(item);
        collections.add(collection);

        try {
          await SyncService.syncCollections();
        } catch (e) {}
      }

      return collections;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch collections: ${e.toString()}');
    }
  }

  Future<EventCollection> createCollection({
    required String name,
    String? description,
    String color = '#2196F3',
    bool isPublic = false,
    List<String> eventIds = const [],
  }) async {
    try {
      final data = {
        'name': name,
        'description': description,
        'color': color,
        'is_public': isPublic,
        'event_ids': eventIds,
      };

      final response = await ApiClientFactory.instance.post(
        '/api/v1/event-collections',
        body: data,
      );
      final collection = EventCollection.fromJson(response);

      try {
        await SyncService.syncCollections();
      } catch (e) {}

      return collection;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create collection: ${e.toString()}');
    }
  }

  Future<EventCollection> updateCollection(
    String id, {
    String? name,
    String? description,
    String? color,
    bool? isPublic,
    List<String>? eventIds,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (color != null) data['color'] = color;
      if (isPublic != null) data['is_public'] = isPublic;
      if (eventIds != null) data['event_ids'] = eventIds;

      final response = await ApiClientFactory.instance.put(
        '/api/v1/event-collections/$id',
        body: data,
      );
      final collection = EventCollection.fromJson(response);

      try {
        await SyncService.syncCollections();
      } catch (e) {}

      return collection;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update collection: ${e.toString()}');
    }
  }

  Future<void> deleteCollection(String id) async {
    try {
      await ApiClientFactory.instance.delete('/api/v1/event-collections/$id');

      try {
        await SyncService.syncCollections();
      } catch (e) {}
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete collection: ${e.toString()}');
    }
  }

  Future<EventCollection> addEventToCollection(
    String collectionId,
    String eventId,
  ) async {
    try {
      final data = {'event_id': eventId};
      final response = await ApiClientFactory.instance.post(
        '/api/v1/event-collections/$collectionId/events',
        body: data,
      );
      final collection = EventCollection.fromJson(response);

      try {
        await SyncService.syncCollections();
      } catch (e) {}

      return collection;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to add event to collection: ${e.toString()}');
    }
  }

  Future<EventCollection> removeEventFromCollection(
    String collectionId,
    String eventId,
  ) async {
    try {
      await ApiClientFactory.instance.delete(
        '/api/v1/event-collections/$collectionId/events/$eventId',
      );

      final collection = getLocalCollection(collectionId);
      if (collection != null) {
        final updatedCollection = collection.removeEvent(eventId);
        await _storeCollectionLocally(updatedCollection);
        return updatedCollection;
      }

      throw ApiException('Collection not found locally');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Failed to remove event from collection: ${e.toString()}',
      );
    }
  }

  Future<EventCollection> shareCollection(
    String collectionId,
    String userId,
  ) async {
    try {
      final data = {'user_id': userId};
      final response = await ApiClientFactory.instance.post(
        '/api/v1/event-collections/$collectionId/share',
        body: data,
      );
      final collection = EventCollection.fromJson(response);

      await _storeCollectionLocally(collection);

      return collection;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to share collection: ${e.toString()}');
    }
  }

  Future<EventCollection> unshareCollection(
    String collectionId,
    String userId,
  ) async {
    try {
      await ApiClientFactory.instance.delete(
        '/api/v1/event-collections/$collectionId/share/$userId',
      );

      try {
        await SyncService.syncCollections();
      } catch (e) {}
      final updated = getLocalCollection(collectionId);
      if (updated != null) return updated;

      throw ApiException('Collection not found locally');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to unshare collection: ${e.toString()}');
    }
  }

  bool isOwnedByUser(String collectionId, String userId) {
    final collection = getLocalCollection(collectionId);
    return collection?.isOwnedBy(userId) ?? false;
  }

  Map<String, dynamic> getCollectionStats() {
    final collections = getLocalCollections();

    return {
      'total': collections.length,
      'public': collections.where((c) => c.isPublic).length,
      'shared': collections.where((c) => c.isShared).length,
      'with_events': collections.where((c) => c.isNotEmpty).length,
      'empty': collections.where((c) => c.isEmpty).length,
      'total_events': collections.fold<int>(0, (sum, c) => sum + c.eventCount),
    };
  }

  Future<void> _storeCollectionLocally(EventCollection collection) async {
    try {
      await SyncService.syncCollections();
    } catch (e) {}
  }

  Future<void> clearLocalData() async {
    try {
      await _box?.clear();
    } catch (e) {}
  }
}
