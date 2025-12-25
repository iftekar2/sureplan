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
      'created_by': userId,
    };

    print('DEBUG: Creating event with local time: $dateTime');
    print('DEBUG: Storing as UTC: ${dateTime.toUtc()}');

    final response = await _supabase
        .from('events')
        .insert(eventData)
        .select('*, user_profiles(username)')
        .single();

    return Event.fromJson(response);
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

    return (response as List)
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single event by ID
  Future<Event> getEventById(String eventId) async {
    final response = await _supabase
        .from('events')
        .select('*, user_profiles(username)')
        .eq('id', eventId)
        .single();

    return Event.fromJson(response);
  }

  /// Update an event
  Future<Event> updateEvent({
    required String eventId,
    String? title,
    DateTime? dateTime,
    String? location,
    String? description,
  }) async {
    final updateData = <String, dynamic>{};

    if (title != null) updateData['title'] = title;
    if (dateTime != null) updateData['date_time'] = dateTime.toIso8601String();
    if (location != null) updateData['location'] = location;
    if (description != null) updateData['description'] = description;

    final response = await _supabase
        .from('events')
        .update(updateData)
        .eq('id', eventId)
        .select('*, user_profiles(username)')
        .single();

    return Event.fromJson(response);
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    await _supabase.from('events').delete().eq('id', eventId);
  }

  /// Get upcoming events (future events only)
  Future<List<Event>> getUpcomingEvents() async {
    final now = DateTime.now().toIso8601String();
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) return [];

    // 1. Fetch events created by current user
    final createdResponse = await _supabase
        .from('events')
        .select('*, user_profiles(username)')
        .eq('created_by', userId)
        .gte('date_time', now)
        .order('date_time', ascending: true);

    final createdEvents = (createdResponse as List)
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();

    print('DEBUG: Created events count: ${createdEvents.length}');

    // 2. Fetch events where current user is invited and responded
    final invitedResponse = await _supabase
        .from('event_invites')
        .select('*, events(*, user_profiles(username))')
        .eq('invitee_id', userId)
        .neq('status', 'pending');

    print('DEBUG: Raw invited response: ${invitedResponse.length} records');
    print('DEBUG: Invited response data: $invitedResponse');

    final nowDateTime = DateTime.now();
    print('DEBUG: Current time: $nowDateTime (${nowDateTime.toUtc()} UTC)');

    final invitedEvents = (invitedResponse as List)
        .map((json) => json['events'])
        .where((eventJson) {
          if (eventJson == null) {
            print('DEBUG: Skipping null event');
            return false;
          }
          return true;
        })
        .map((eventJson) {
          final event = Event.fromJson(eventJson as Map<String, dynamic>);
          print(
            'DEBUG: Event "${event.title}" - date_time: ${event.dateTime} (${event.dateTime.toUtc()} UTC)',
          );
          print('DEBUG: Is after now? ${event.dateTime.isAfter(nowDateTime)}');
          return event;
        })
        .where((event) => event.dateTime.isAfter(nowDateTime))
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
}
