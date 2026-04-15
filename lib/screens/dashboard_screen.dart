import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'event_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EventService eventService = EventService();
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
    if (date == null) return 'No date available';
    return DateFormat('MMMM d, y').format(date);
  }

  String _formatTime(String? start, String? end) {
    if (start == null && end == null) return 'Time not available';
    if (start != null && end != null) return '$start - $end';
    return start ?? end ?? 'Time not available';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kadayawan Event Hub'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        child: FutureBuilder<List<EventModel>>(
          future: eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading events: ${snapshot.error}',
                      ),
                    ),
                  ),
                ],
              );
            }

            final events = snapshot.data ?? [];

            if (events.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No events found.'),
                    ),
                  ),
                ],
              );
            }

            return ListView(
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
                        AppColors.purple,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kadayawan Event Hub',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Browse festival events, venues, and schedules in one dashboard.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Festival Events',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 12),
                ...events.map((event) => _EventCard(
                      event: event,
                      formattedDate: _formatDate(event.date),
                      formattedTime:
                          _formatTime(event.timeStart, event.timeEnd),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final String formattedDate;
  final String formattedTime;

  const _EventCard({
    required this.event,
    required this.formattedDate,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        event.imageUrl != null && event.imageUrl!.trim().isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            hasImage
                ? Image.network(
                    event.imageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.grey.shade300,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 48),
                            SizedBox(height: 8),
                            Text('Image failed to load'),
                          ],
                        ),
                      );
                    },
                  )
                : Container(
                    width: double.infinity,
                    height: 180,
                    color: Colors.grey.shade300,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 48),
                        SizedBox(height: 8),
                        Text('No image available'),
                      ],
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: AppColors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: AppColors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          formattedTime,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place,
                          size: 16, color: AppColors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.venueName ?? 'Unknown venue',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.description ?? 'No description available.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Tap to view details',
                      style: TextStyle(
                        color: AppColors.brown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}