import '../main.dart';
import '../models/event_model.dart';

class EventService {
  Future<List<EventModel>> fetchEvents() async {
    final response = await supabase.from('events').select('''
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
    ''').order('date', ascending: true);

    return (response as List)
        .map((item) => EventModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}