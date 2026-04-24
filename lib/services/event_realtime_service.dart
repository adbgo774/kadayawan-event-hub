import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import 'notification_service.dart';

class EventRealtimeService {
  RealtimeChannel? _channel;
  bool _isListening = false;

  void startListening() {
    if (_isListening) return;

    debugPrint('Starting realtime listener for updates...');

    _channel = supabase.channel('public:updates_notifications');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'updates',
          callback: (payload) async {
            debugPrint('Realtime payload received: ${payload.newRecord}');

            final data = payload.newRecord;
            final message =
                (data['message'] ?? 'There is a new event update.')
                    .toString();

            final lower = message.toLowerCase();

            String title;
            IconData icon;

            if (lower.contains('cancel')) {
              title = 'Event Cancelled';
              icon = Icons.cancel_outlined;
            } else if (lower.contains('update') || lower.contains('changed')) {
              title = 'Event Updated';
              icon = Icons.update;
            } else {
              title = 'New Event Added';
              icon = Icons.notifications_active_outlined;
            }

            await NotificationService.showEventNotification(
              title: title,
              body: message,
            );

            final messenger = rootScaffoldMessengerKey.currentState;
            if (messenger != null) {
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                    content: Row(
                      children: [
                        Icon(icon, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(child: Text('$title\n$message')),
                      ],
                    ),
                  ),
                );
            }
          },
        )
        .subscribe((status, error) {
          debugPrint('Realtime status: $status');
          if (error != null) {
            debugPrint('Realtime error: $error');
          }
        });

    _isListening = true;
  }

  Future<void> dispose() async {
    if (_channel != null) {
      await supabase.removeChannel(_channel!);
      _channel = null;
    }
    _isListening = false;
  }
}