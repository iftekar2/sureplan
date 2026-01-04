class EventCreator {
  final String id;
  final String username;

  EventCreator({required this.id, required this.username});

  factory EventCreator.fromJson(Map<String, dynamic> json, String id) {
    return EventCreator(
      id: id,
      username: json['username'] as String? ?? 'Unknown',
    );
  }
}

class Event {
  final String id;
  final String title;
  final DateTime dateTime;
  final String location;
  final EventCreator createdBy;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? status;
  final String? inviteeId;
  final String? inviteeStatus;
  final String? backgroundImage;
  final bool? is_public;
  final String? short_id;

  Event({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.createdBy,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.inviteeId,
    required this.inviteeStatus,
    this.backgroundImage,
    required this.is_public,
    required this.short_id,
  });

  // Create Event from JSON (from Supabase)
  factory Event.fromJson(Map<String, dynamic> json) {
    final dateTimeStr = json['date_time'] as String;
    final parsedDateTime = DateTime.parse(dateTimeStr);

    // Support both direct ID and joined user profile
    final creatorId = json['created_by'] as String;
    final creatorData = json['user_profiles'] as Map<String, dynamic>?;

    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      dateTime: parsedDateTime.toLocal(),
      location: json['location'] as String,
      createdBy: creatorData != null
          ? EventCreator.fromJson(creatorData, creatorId)
          : EventCreator(id: creatorId, username: 'Unknown'),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      status: json['status'] as String?,
      inviteeId: json['invitee_id'] as String?,
      inviteeStatus: json['invitee_status'] as String?,
      backgroundImage: json['background_image'] as String?,
      is_public: json['is_public'] as bool?,
      short_id: json['short_id'] as String?,
    );
  }

  // Convert Event to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date_time': dateTime.toIso8601String(),
      'location': location,
      'created_by': createdBy.id,
      'description': description,
      'status': status,
      'invitee_id': inviteeId,
      'invitee_status': inviteeStatus,
      'background_image': backgroundImage,
      'is_public': is_public,
      'short_id': short_id,
    };
  }

  // Create a copy with updated fields
  Event copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? location,
    EventCreator? createdBy,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? inviteeId,
    String? inviteeStatus,
    String? backgroundImage,
    bool? is_public,
    String? short_id,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      createdBy: createdBy ?? this.createdBy,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      inviteeId: inviteeId ?? this.inviteeId,
      inviteeStatus: inviteeStatus ?? this.inviteeStatus,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      is_public: is_public ?? this.is_public,
      short_id: short_id ?? this.short_id,
    );
  }
}
