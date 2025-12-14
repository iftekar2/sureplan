import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/models/invite.dart';
import 'package:sureplan/models/user_profile.dart';

class InviteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Search for users by username or email.
  Future<List<UserProfile>> searchUsers(String query) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('user_profiles')
        .select()
        .or('username.ilike.%$query%,email.ilike.%$query%')
        .neq('id', currentUserId) // Don't show myself
        .limit(20);

    return (response as List)
        .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Send an invite to a user
  Future<void> sendInvite({
    required String eventId,
    required String inviteeId,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Not logged in');

    // Check if invite already exists
    final existingParams = await _supabase
        .from('event_invites')
        .select()
        .eq('event_id', eventId)
        .eq('invitee_id', inviteeId)
        .maybeSingle();

    if (existingParams != null) {
      throw Exception('User is already invited');
    }

    await _supabase.from('event_invites').insert({
      'event_id': eventId,
      'inviter_id': currentUserId,
      'invitee_id': inviteeId,
      'status': 'pending',
    });
  }

  /// Get pending invites for the current user
  Future<List<Invite>> getMyReceivedInvites() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('event_invites')
        .select('*, events(*), inviter:user_profiles!inviter_id(*)')
        .eq('invitee_id', currentUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Invite.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Respond to an invite
  Future<void> respondToInvite({
    required String inviteId,
    required String status, // 'going', 'not_going', 'maybe'
  }) async {
    await _supabase
        .from('event_invites')
        .update({'status': status})
        .eq('id', inviteId);
  }

  /// Get list of confirmed attendees for an event
  Future<List<Invite>> getAttendees(String eventId) async {
    final response = await _supabase
        .from('event_invites')
        .select('*, invitee:user_profiles!invitee_id(*)')
        .eq('event_id', eventId)
        .eq('status', 'going'); // Only fetch confirmed attendees

    return (response as List)
        .map((json) => Invite.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
