class Event {
  final String id;
  final String title;
  final DateTime dateTime;
  final String location;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create Event from JSON (from Supabase)
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      dateTime: DateTime.parse(json['date_time'] as String),
      location: json['location'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert Event to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date_time': dateTime.toIso8601String(),
      'location': location,
      'created_by': createdBy,
    };
  }

  // Create a copy with updated fields
  Event copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? location,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
