import '../main.dart';
import '../models/event_model.dart';

class SavedEventService {
  bool isGuestUser() {
    final user = supabase.auth.currentUser;

    if (user == null) return true;

    if (user.isAnonymous == true) return true;

    final provider = user.appMetadata['provider'];
    if (provider == 'anonymous') return true;

    if ((user.email ?? '').trim().toLowerCase() == 'guest@local.dev') {
      return true;
    }

    return false;
  }

  Future<void> saveEvent(String eventId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw 'You must be logged in to save an event.';
    }

    if (isGuestUser()) {
      throw 'Guests cannot save events.';
    }

    final existing = await supabase
        .from('saved_events')
        .select('id')
        .eq('user_id', user.id)
        .eq('event_id', eventId)
        .maybeSingle();

    if (existing != null) {
      throw 'This event is already saved.';
    }

    await supabase.from('saved_events').insert({
      'user_id': user.id,
      'event_id': eventId,
    });
  }

  Future<List<EventModel>> fetchSavedEvents() async {
    final user = supabase.auth.currentUser;

    if (user == null || isGuestUser()) {
      return [];
    }

    final response = await supabase
        .from('saved_events')
        .select('''
          id,
          events (
            id,
            title,
            description,
            image_url,
            date,
            time_start,
            time_end,
            venues (
              name,
              address,
              latitude,
              longitude
            ),
            festivals (
              name,
              year
            )
          )
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final List<EventModel> savedEvents = [];

    for (final item in response as List) {
      final event = item['events'];
      if (event != null && event is Map<String, dynamic>) {
        savedEvents.add(EventModel.fromMap(event));
      }
    }

    return savedEvents;
  }

  Future<void> removeSavedEvent(String eventId) async {
    final user = supabase.auth.currentUser;

    if (user == null || isGuestUser()) return;

    await supabase
        .from('saved_events')
        .delete()
        .eq('user_id', user.id)
        .eq('event_id', eventId);
  }

  Future<bool> isEventSaved(String eventId) async {
    final user = supabase.auth.currentUser;

    if (user == null || isGuestUser()) {
      return false;
    }

    final existing = await supabase
        .from('saved_events')
        .select('id')
        .eq('user_id', user.id)
        .eq('event_id', eventId)
        .maybeSingle();

    return existing != null;
  }

  Future<bool> toggleSavedEvent(String eventId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw 'You must be logged in to save an event.';
    }

    if (isGuestUser()) {
      throw 'Guests cannot save events.';
    }

    final alreadySaved = await isEventSaved(eventId);

    if (alreadySaved) {
      await removeSavedEvent(eventId);
      return false;
    } else {
      await saveEvent(eventId);
      return true;
    }
  }
}