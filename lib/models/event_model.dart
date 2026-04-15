class EventModel {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final DateTime? date;
  final String? timeStart;
  final String? timeEnd;
  final String? venueName;
  final String? venueAddress;
  final double? venueLatitude;
  final double? venueLongitude;
  final String? festivalName;
  final int? festivalYear;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.date,
    this.timeStart,
    this.timeEnd,
    this.venueName,
    this.venueAddress,
    this.venueLatitude,
    this.venueLongitude,
    this.festivalName,
    this.festivalYear,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    final venue = map['venues'];
    final festival = map['festivals'];

    return EventModel(
      id: map['id'].toString(),
      title: map['title'] ?? 'Untitled Event',
      description: map['description'],
      imageUrl: map['image_url'],
      date: map['date'] != null ? DateTime.tryParse(map['date']) : null,
      timeStart: map['time_start']?.toString(),
      timeEnd: map['time_end']?.toString(),
      venueName: venue is Map<String, dynamic> ? venue['name'] : null,
      venueAddress: venue is Map<String, dynamic> ? venue['address'] : null,
      venueLatitude: venue is Map<String, dynamic>
          ? (venue['latitude'] as num?)?.toDouble()
          : null,
      venueLongitude: venue is Map<String, dynamic>
          ? (venue['longitude'] as num?)?.toDouble()
          : null,
      festivalName: festival is Map<String, dynamic> ? festival['name'] : null,
      festivalYear: festival is Map<String, dynamic> ? festival['year'] : null,
    );
  }
}