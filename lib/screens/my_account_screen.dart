import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../main.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../services/saved_event_service.dart';
import 'event_details_screen.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final AuthService authService = AuthService();
  final SavedEventService savedEventService = SavedEventService();

  late Future<List<EventModel>> savedEventsFuture;

  @override
  void initState() {
    super.initState();
    savedEventsFuture = savedEventService.fetchSavedEvents();
  }

  Future<void> _refreshSavedEvents() async {
    setState(() {
      savedEventsFuture = savedEventService.fetchSavedEvents();
    });
  }

  String _getDisplayName() {
    final user = supabase.auth.currentUser;

    final metadataName = user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.userMetadata?['display_name'];

    if (metadataName != null &&
        metadataName.toString().trim().isNotEmpty) {
      return metadataName.toString();
    }

    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Guest User';
  }

  String _getEmail() {
    final user = supabase.auth.currentUser;
    return user?.email ?? 'guest@local.dev';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';
    return DateFormat('MMMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = savedEventService.isGuestUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSavedEvents,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.purple,
                    AppColors.red,
                    AppColors.orange,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 70,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Account Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// ACCOUNT INFO
            _AccountInfoCard(
              icon: Icons.person_outline,
              title: 'User Name',
              value: _getDisplayName(),
            ),
            _AccountInfoCard(
              icon: Icons.email_outlined,
              title: 'Email',
              value: _getEmail(),
            ),

            const SizedBox(height: 16),

            /// SAVED EVENTS TITLE
            const Text(
              'Saved Events',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.red,
              ),
            ),

            const SizedBox(height: 10),

            /// GUEST MESSAGE
            if (isGuest)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Guest users cannot save events.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              )
            else
              FutureBuilder<List<EventModel>>(
                future: savedEventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading saved events: ${snapshot.error}',
                        ),
                      ),
                    );
                  }

                  final savedEvents = snapshot.data ?? [];

                  if (savedEvents.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No saved events yet.'),
                      ),
                    );
                  }

                  return Column(
                    children: savedEvents.map((event) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),

                          /// ICON
                          leading: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.yellow.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.bookmark,
                              color: AppColors.orange,
                            ),
                          ),

                          /// TITLE
                          title: Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          /// DATE
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_formatDate(event.date)),
                          ),

                          /// UNSAVE BUTTON
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.bookmark_remove_outlined,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              await savedEventService
                                  .removeSavedEvent(event.id);

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Event removed from saved events.',
                                  ),
                                ),
                              );

                              _refreshSavedEvents();
                            },
                          ),

                          /// OPEN DETAILS
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventDetailsScreen(event: event),
                              ),
                            );

                            _refreshSavedEvents();
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

            const SizedBox(height: 20),

            /// LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authService.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _AccountInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.yellow.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.orange),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(value),
        ),
      ),
    );
  }
}