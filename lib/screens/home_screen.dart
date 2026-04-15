import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../main.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import 'event_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = AuthService();
  final eventService = EventService();

  late Future<List<EventModel>> eventsFuture;

  @override
  void initState() {
    super.initState();
    eventsFuture = eventService.fetchEvents();
  }

  Future<void> _refreshEvents() async {
    setState(() {
      eventsFuture = eventService.fetchEvents();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';
    return DateFormat('MMMM d, y').format(date);
  }

  String _formatTimeRange(String? start, String? end) {
    if (start == null && end == null) return 'Time not available';
    if (start != null && end != null) return '$start - $end';
    return start ?? end ?? 'Time not available';
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final isGuest = user?.isAnonymous ?? false;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        title: const Text('Kadayawan Event Hub'),
        actions: [
          IconButton(
            onPressed: _refreshEvents,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () async {
              await authService.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.yellow,
                    AppColors.orange,
                    AppColors.red,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGuest ? 'Welcome, Guest!' : 'Welcome to Kadayawan!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isGuest
                        ? 'Browse festival schedules and event details.'
                        : 'Discover events, venues, and festival celebrations in Davao City.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Signed in as: ${user?.email ?? "Guest User"}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.red,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<EventModel>>(
              future: eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error loading events: ${snapshot.error}'),
                    ),
                  );
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No events found yet.'),
                    ),
                  );
                }

                return Column(
                  children: events.map((event) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.event,
                            color: AppColors.green,
                          ),
                        ),
                        title: Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatDate(event.date)),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimeRange(
                                  event.timeStart,
                                  event.timeEnd,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(event.venueName ?? 'Unknown venue'),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailsScreen(event: event),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}