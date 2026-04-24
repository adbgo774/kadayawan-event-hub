import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_colors.dart';
import '../models/event_model.dart';
import '../services/feedback_service.dart';
import '../services/location_service.dart';
import '../services/saved_event_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final LocationService _locationService = LocationService();
  final SavedEventService _savedEventService = SavedEventService();
  final FeedbackService _feedbackService = FeedbackService();

  final TextEditingController _commentController = TextEditingController();

  bool _isLoadingLocation = false;
  bool _isSaving = false;
  bool _isSaved = false;
  bool _isCheckingSaved = true;

  bool _isSubmittingFeedback = false;
  bool _isLoadingFeedback = true;

  int _selectedRating = 0;
  List<Map<String, dynamic>> _feedbackList = [];

  String? _distanceText;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _loadFeedback();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkIfSaved() async {
    try {
      final saved = await _savedEventService.isEventSaved(widget.event.id);
      if (!mounted) return;
      setState(() {
        _isSaved = saved;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSaved = false;
        });
      }
    }
  }

  Future<void> _loadFeedback() async {
    try {
      final feedback = await _feedbackService.fetchFeedbackForEvent(widget.event.id);
      final myFeedback =
          await _feedbackService.fetchMyFeedbackForEvent(widget.event.id);

      if (!mounted) return;

      setState(() {
        _feedbackList = feedback;

        if (myFeedback != null) {
          _selectedRating = (myFeedback['rating'] as num?)?.toInt() ?? 0;
          _commentController.text = (myFeedback['comments'] ?? '').toString();
        }
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFeedback = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date available';
    return DateFormat('MMMM d, y').format(date);
  }

  String _formatTimeRange(String? start, String? end) {
    if (start == null && end == null) return 'Time not available';
    if (start != null && end != null) return '$start - $end';
    return start ?? end ?? 'Time not available';
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return '';
    return DateFormat('MMM d, y • h:mm a').format(parsed.toLocal());
  }

  Future<void> _getDistanceToVenue() async {
    final venueLat = widget.event.venueLatitude;
    final venueLng = widget.event.venueLongitude;

    if (venueLat == null || venueLng == null) {
      setState(() {
        _locationError = 'Venue coordinates are not available.';
      });
      return;
    }

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      final km = _locationService.distanceInKm(
        startLat: position.latitude,
        startLng: position.longitude,
        endLat: venueLat,
        endLng: venueLng,
      );

      setState(() {
        _distanceText = '${km.toStringAsFixed(2)} km away';
      });
    } catch (e) {
      setState(() {
        _locationError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _openDirections() async {
    final venueLat = widget.event.venueLatitude;
    final venueLng = widget.event.venueLongitude;

    if (venueLat == null || venueLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venue coordinates are not available.')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$venueLat,$venueLng',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions.')),
      );
    }
  }

  Future<void> _toggleSaveEvent() async {
    if (_savedEventService.isGuestUser()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guests cannot save events.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final isNowSaved =
          await _savedEventService.toggleSavedEvent(widget.event.id);

      if (!mounted) return;

      setState(() {
        _isSaved = isNowSaved;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowSaved
                ? 'Event saved successfully.'
                : 'Event removed from saved events.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackService.isGuestUser()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guests cannot submit feedback.')),
      );
      return;
    }

    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating first.')),
      );
      return;
    }

    setState(() {
      _isSubmittingFeedback = true;
    });

    try {
      await _feedbackService.submitFeedback(
        eventId: widget.event.id,
        rating: _selectedRating,
        comments: _commentController.text,
      );

      await _loadFeedback();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingFeedback = false;
        });
      }
    }
  }

  Widget _buildStarPicker(bool isGuest) {
    return Row(
      children: List.generate(5, (index) {
        final star = index + 1;
        return IconButton(
          onPressed: isGuest
              ? null
              : () {
                  setState(() {
                    _selectedRating = star;
                  });
                },
          icon: Icon(
            star <= _selectedRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        widget.event.imageUrl != null && widget.event.imageUrl!.trim().isNotEmpty;
    final isGuest = _savedEventService.isGuestUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: hasImage
                ? Image.network(
                    widget.event.imageUrl!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 220,
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 60),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 220,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image_outlined, size: 60),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          _InfoCard(
            icon: Icons.event,
            title: 'Event',
            value: widget.event.title,
          ),
          _InfoCard(
            icon: Icons.calendar_today,
            title: 'Date',
            value: _formatDate(widget.event.date),
          ),
          _InfoCard(
            icon: Icons.access_time,
            title: 'Time',
            value: _formatTimeRange(
              widget.event.timeStart,
              widget.event.timeEnd,
            ),
          ),
          _InfoCard(
            icon: Icons.place,
            title: 'Venue',
            value: widget.event.venueName ?? 'Unknown venue',
          ),
          _InfoCard(
            icon: Icons.map_outlined,
            title: 'Address',
            value: widget.event.venueAddress ?? 'No address available',
          ),
          _InfoCard(
            icon: Icons.description_outlined,
            title: 'Description',
            value: widget.event.description ?? 'No description available',
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (isGuest || _isSaving || _isCheckingSaved)
                  ? null
                  : _toggleSaveEvent,
              icon: Icon(
                _isSaved
                    ? Icons.bookmark_remove_outlined
                    : Icons.bookmark_add_outlined,
              ),
              label: Text(
                _isCheckingSaved
                    ? 'Checking...'
                    : _isSaving
                        ? 'Please wait...'
                        : _isSaved
                            ? 'Unsave Event'
                            : 'Save Event',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isGuest ? Colors.grey : AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (isGuest)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Guest users cannot save events or submit feedback.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location Tools',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingLocation)
                    const Text('Getting your current location...')
                  else if (_distanceText != null)
                    Text(
                      _distanceText!,
                      style: const TextStyle(fontSize: 15),
                    )
                  else if (_locationError != null)
                    Text(
                      _locationError!,
                      style: const TextStyle(color: Colors.red),
                    )
                  else
                    const Text('Check how far you are from this venue.'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _getDistanceToVenue,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Get Distance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openDirections,
                        icon: const Icon(Icons.directions),
                        label: const Text('Open Directions'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rate and Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Your Rating'),
                  const SizedBox(height: 6),
                  _buildStarPicker(isGuest),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    enabled: !isGuest && !_isSubmittingFeedback,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: isGuest
                          ? 'Guests cannot submit feedback.'
                          : 'Write your feedback here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (isGuest || _isSubmittingFeedback)
                          ? null
                          : _submitFeedback,
                      icon: const Icon(Icons.rate_review_outlined),
                      label: Text(
                        _isSubmittingFeedback
                            ? 'Submitting...'
                            : 'Submit Feedback',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isGuest ? Colors.grey : AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Feedback',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingFeedback)
                    const Center(child: CircularProgressIndicator())
                  else if (_feedbackList.isEmpty)
                    const Text('No feedback yet for this event.')
                  else
                    ..._feedbackList.map((item) {
                      final rating = (item['rating'] as num?)?.toInt() ?? 0;
                      final comments = (item['comments'] ?? '').toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comments.isEmpty
                                  ? 'No comment provided.'
                                  : comments,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDateTime(item['created_at']),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
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