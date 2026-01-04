import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/models/event.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new event
  Future<Event> createEvent({
    required String title,
    required DateTime dateTime,
    required String location,
    String? description,
    String? backgroundImageUrl,
    bool? isPublic,
    String? shortId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be logged in to create events');
    }

    final eventData = {
      'title': title,
      'date_time': dateTime.toUtc().toIso8601String(),
      'location': location,
      'description': description,
      'background_image': backgroundImageUrl,
      'created_by': userId,
      'is_public': isPublic,
      'short_id': shortId,
    };

    print('DEBUG: Creating event with local time: $dateTime');
    print('DEBUG: Storing as UTC: ${dateTime.toUtc()}');

    final response = await _supabase
        .from('events')
        .insert(eventData)
        .select('*, user_profiles(username)')
        .single();

    final Map<String, dynamic> eventWithStatus = Map.from(response);
    eventWithStatus['status'] = 'Hosting';
    eventWithStatus['invitee_id'] = userId;
    eventWithStatus['invitee_status'] = 'Hosting';

    return Event.fromJson(eventWithStatus);
  }

  /// Get all events
  Future<List<Event>> getAllEvents() async {
    final response = await _supabase
        .from('events')
        .select('*, user_profiles(username)')
        .order('date_time', ascending: true);

    return (response as List)
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get events created by current user
  Future<List<Event>> getMyEvents() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be logged in');
    }

    final response = await _supabase
        .from('events')
        .select('*, user_profiles(username)')
        .eq('created_by', userId)
        .order('date_time', ascending: true);

    return (response as List).map((json) {
      final Map<String, dynamic> eventWithStatus = Map<String, dynamic>.from(
        json as Map,
      );
      eventWithStatus['status'] = 'Hosting';
      eventWithStatus['invitee_id'] = userId;
      eventWithStatus['invitee_status'] = 'Hosting';
      return Event.fromJson(eventWithStatus);
    }).toList();
  }

  /// Get a single event by ID
  Future<Event> getEventById(String eventId) async {
    final response = await _supabase
        .from('events')
        .select('*, user_profiles(username)')
        .eq('id', eventId)
        .single();

    final Map<String, dynamic> eventWithStatus = Map.from(response);
    final userId = _supabase.auth.currentUser?.id;
    if (response['created_by'] == userId) {
      eventWithStatus['status'] = 'Hosting';
      eventWithStatus['invitee_id'] = userId;
      eventWithStatus['invitee_status'] = 'Hosting';
    }

    return Event.fromJson(eventWithStatus);
  }

  /// Update an event
  Future<Event> updateEvent({
    required String eventId,
    String? title,
    DateTime? dateTime,
    String? location,
    String? description,
    String? backgroundImageUrl,
    bool? isPublic,
  }) async {
    final updateData = <String, dynamic>{};

    if (title != null) updateData['title'] = title;
    if (dateTime != null) updateData['date_time'] = dateTime.toIso8601String();
    if (location != null) updateData['location'] = location;
    if (description != null) updateData['description'] = description;
    if (backgroundImageUrl != null) {
      updateData['background_image'] = backgroundImageUrl;
    }
    if (isPublic != null) updateData['is_public'] = isPublic;

    final response = await _supabase
        .from('events')
        .update(updateData)
        .eq('id', eventId)
        .select('*, user_profiles(username)')
        .single();

    final Map<String, dynamic> eventWithStatus = Map.from(response);
    final userId = _supabase.auth.currentUser?.id;
    eventWithStatus['status'] = 'Hosting';
    eventWithStatus['invitee_id'] = userId;
    eventWithStatus['invitee_status'] = 'Hosting';

    return Event.fromJson(eventWithStatus);
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    await _supabase.from('events').delete().eq('id', eventId);
  }

  /// Get upcoming events (future events only)
  Future<List<Event>> getUpcomingEvents() async {
    // Use UTC for comparison with database and add a 3-hour grace period
    // so that ongoing events don't immediately vanish.
    final now = DateTime.now().toUtc();
    final graceTime = now.subtract(const Duration(hours: 3)).toIso8601String();
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) return [];

    // 1. Fetch events created by current user
    final createdResponse = await _supabase
        .from('events')
        .select('*, user_profiles(username)')
        .eq('created_by', userId)
        .gte('date_time', graceTime)
        .order('date_time', ascending: true);

    final createdEvents = (createdResponse as List).map((json) {
      final eventMap = Map<String, dynamic>.from(json as Map);
      eventMap['status'] = 'Hosting';
      eventMap['invitee_id'] = userId;
      eventMap['invitee_status'] = 'Hosting';
      return Event.fromJson(eventMap);
    }).toList();

    print('DEBUG: Created events count: ${createdEvents.length}');

    // 2. Fetch events where current user is invited and responded
    final invitedResponse = await _supabase
        .from('event_invites')
        .select('*, events(*, user_profiles(username))')
        .eq('invitee_id', userId)
        .neq('status', 'pending');

    print('DEBUG: Raw invited response: ${invitedResponse.length} records');

    final graceDateTime = DateTime.now().subtract(const Duration(hours: 3));

    final invitedEvents = (invitedResponse as List)
        .where((json) => json['events'] != null)
        .map((json) {
          final eventJson = json['events'] as Map<String, dynamic>;
          final eventMap = Map<String, dynamic>.from(eventJson);
          final inviteStatus = json['status'] as String?;

          eventMap['status'] = inviteStatus;
          eventMap['invitee_id'] = userId;
          eventMap['invitee_status'] = inviteStatus;

          return Event.fromJson(eventMap);
        })
        .where((event) => event.dateTime.isAfter(graceDateTime))
        .toList();

    print(
      'DEBUG: Invited events count (after filtering): ${invitedEvents.length}',
    );

    // 3. Merge and sort
    final allEvents = [...createdEvents, ...invitedEvents];

    // Deduplicate by ID
    final uniqueEvents = {for (var e in allEvents) e.id: e}.values.toList();

    // Sort by date
    uniqueEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    print('DEBUG: Final unique events count: ${uniqueEvents.length}');

    return uniqueEvents;
  }

  /// Get past events
  Future<List<Event>> getPastEvents() async {
    final now = DateTime.now().toIso8601String();

    final response = await _supabase
        .from('events')
        .select('*, user_profiles(username)')
        .lt('date_time', now)
        .order('date_time', ascending: false);

    return (response as List)
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Upload event background image
  Future<String> uploadEventBackground(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User must be logged in');

    final fileExt = imageFile.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = '$userId/$fileName';

    await _supabase.storage
        .from('event-backgrounds')
        .upload(filePath, imageFile);

    final String publicUrl = _supabase.storage
        .from('event-backgrounds')
        .getPublicUrl(filePath);

    return publicUrl;
  }

  /// Search events by short_id
  Future<List<Event>> searchEventsByShortId(String shortId) async {
    final response = await _supabase
        .from('events')
        .select('*, user_profiles(username)')
        .eq('short_id', shortId.toUpperCase());

    return (response as List)
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
