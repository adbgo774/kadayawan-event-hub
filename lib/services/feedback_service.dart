import '../main.dart';

class FeedbackService {
  bool isGuestUser() {
    final user = supabase.auth.currentUser;

    if (user == null) return true;

    try {
      if (user.isAnonymous == true) return true;
    } catch (_) {}

    final provider = user.appMetadata['provider'];
    final email = (user.email ?? '').trim().toLowerCase();

    return provider == 'anonymous' || email == 'guest@local.dev';
  }

  Future<void> submitFeedback({
    required String eventId,
    required int rating,
    required String comments,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw 'You must be logged in to submit feedback.';
    }

    if (isGuestUser()) {
      throw 'Guests cannot submit feedback.';
    }

    final trimmedComments = comments.trim();

    if (rating < 1 || rating > 5) {
      throw 'Please select a rating from 1 to 5.';
    }

    final existing = await supabase
        .from('feedback')
        .select('id')
        .eq('user_id', user.id)
        .eq('event_id', eventId)
        .maybeSingle();

    if (existing != null) {
      await supabase
          .from('feedback')
          .update({
            'rating': rating,
            'comments': trimmedComments,
            'created_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);
    } else {
      await supabase.from('feedback').insert({
        'user_id': user.id,
        'event_id': eventId,
        'rating': rating,
        'comments': trimmedComments,
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchFeedbackForEvent(String eventId) async {
    final response = await supabase
        .from('feedback')
        .select('id, user_id, rating, comments, created_at')
        .eq('event_id', eventId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> fetchMyFeedbackForEvent(String eventId) async {
    final user = supabase.auth.currentUser;

    if (user == null || isGuestUser()) return null;

    final response = await supabase
        .from('feedback')
        .select('id, rating, comments, created_at')
        .eq('user_id', user.id)
        .eq('event_id', eventId)
        .maybeSingle();

    if (response == null) return null;

    return Map<String, dynamic>.from(response);
  }
}