import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../repositories/event_repository.dart';
import '../services/event_service.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final repository = EventRepository();
  ref.onDispose(() => repository.dispose());
  return repository;
});

final eventsStreamProvider = StreamProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.eventsStream;
});

class EventNotifier extends AsyncNotifier<List<Event>> {
  late EventRepository _repository;
  StreamSubscription? _eventsSubscription;

  @override
  Future<List<Event>> build() async {
    _repository = ref.watch(eventRepositoryProvider);

    ref.onDispose(() {
      _eventsSubscription?.cancel();
    });

    await _repository.initialize();

    _eventsSubscription = _repository.eventsStream.listen(
      (events) {
        state = AsyncValue.data(events);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );

    return await _repository.fetchAndSyncEvents();
  }

  Future<void> fetchEvents() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.fetchAndSyncEvents();
    });
  }

  Future<bool> createEvent(String name) async {
    if (name.trim().isEmpty) {
      state = AsyncValue.error(
        'Event name cannot be empty',
        StackTrace.current,
      );
      return false;
    }

    try {
      final eventService = EventService();
      await eventService.createEvent(name: name, startDate: DateTime.now());

      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> updateEvent(int id, String name) async {
    if (name.trim().isEmpty) {
      state = AsyncValue.error(
        'Event name cannot be empty',
        StackTrace.current,
      );
      return false;
    }

    try {
      final eventService = EventService();
      await eventService.updateEvent(eventId: id, name: name);

      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteEvent(int id) async {
    try {
      final eventService = EventService();
      await eventService.deleteEvent(id);

      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Event? getEventById(int id) {
    return _repository.getEventById(id);
  }
}

final eventNotifierProvider = AsyncNotifierProvider<EventNotifier, List<Event>>(
  () {
    return EventNotifier();
  },
);
