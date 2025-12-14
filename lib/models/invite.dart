import 'package:sureplan/models/event.dart';
import 'package:sureplan/models/user_profile.dart';

class Invite {
  final String id;
  final String eventId;
  final String inviterId;
  final String inviteeId;
  final String status;
  final DateTime createdAt;

  // Optional expanded details for UI convenience
  final Event? event;
  final UserProfile? inviter;
  final UserProfile? invitee;

  Invite({
    required this.id,
    required this.eventId,
    required this.inviterId,
    required this.inviteeId,
    required this.status,
    required this.createdAt,
    this.event,
    this.inviter,
    this.invitee,
  });

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      inviterId: json['inviter_id'] as String,
      inviteeId: json['invitee_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      event: json['events'] != null ? Event.fromJson(json['events']) : null,
      inviter: json['inviter'] != null
          ? UserProfile.fromJson(json['inviter'])
          : null,
      invitee: json['invitee'] != null
          ? UserProfile.fromJson(json['invitee'])
          : null,
    );
  }
}
