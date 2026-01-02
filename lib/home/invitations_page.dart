import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sureplan/models/invite.dart';
import 'package:sureplan/services/invite_service.dart';

class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  final _inviteService = InviteService();
  bool _isLoading = true;
  List<Invite> _invites = [];
  RealtimeChannel? _inviteChannel;

  @override
  void initState() {
    super.initState();
    _loadInvites();
    _setupInviteListener();
  }

  @override
  void dispose() {
    _inviteChannel?.unsubscribe();
    super.dispose();
  }

  void _setupInviteListener() {
    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return;

    print(
      'DEBUG: Setting up Invites Realtime listener for user: $currentUserId',
    );

    _inviteChannel = client
        .channel('public:event_invites_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'event_invites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'invitee_id',
            value: currentUserId,
          ),
          callback: (payload) {
            print(
              'DEBUG: Realtime event received in InvitationsPage: ${payload.eventType}',
            );
            _loadInvites();
          },
        )
        .subscribe((status, [error]) {
          print('DEBUG: Invites Realtime status: $status');
          if (error != null) {
            print('DEBUG: Invites Realtime error: $error');
          }
        });
  }

  Future<void> _loadInvites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invites = await _inviteService.getMyReceivedInvites();
      setState(() {
        _invites = invites;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading invites: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _respond(String inviteId, String status) async {
    try {
      await _inviteService.respondToInvite(inviteId: inviteId, status: status);
      setState(() {
        _invites.removeWhere((i) => i.id == inviteId);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Responded: ${status.replaceAll('_', ' ')}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to respond: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Invitations',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.black))
          : _invites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No pending invitations',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: _invites.length,
              itemBuilder: (context, index) {
                final invite = _invites[index];
                final event = invite.event;
                final inviter = invite.inviter;

                if (event == null) return SizedBox.shrink();

                return Card(
                  margin: EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  color: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,

                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                color: Colors.black,
                                size: 60,
                              ),
                            ),

                            SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                        ),

                                        children: [
                                          TextSpan(
                                            text:
                                                inviter?.username ?? 'Someone',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          TextSpan(text: ' invited you to '),

                                          TextSpan(
                                            text: event.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 10),

                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 20,
                                        color: Colors.grey,
                                      ),

                                      SizedBox(width: 5),
                                      Text(
                                        DateFormat(
                                          'MMM d, h:mm a',
                                        ).format(event.dateTime),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 18,
                                          //fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Action buttons
                        SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Colors.grey[400]!),
                                ),
                              ),

                              onPressed: () => _respond(invite.id, 'not_going'),
                              child: Text(
                                'Decline',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            SizedBox(width: 10),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Colors.grey[400]!),
                                ),
                              ),
                              onPressed: () => _respond(invite.id, 'maybe'),
                              child: Text(
                                'Maybe',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            SizedBox(width: 10),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Colors.grey[400]!),
                                ),
                              ),

                              onPressed: () => _respond(invite.id, 'going'),
                              child: Text(
                                'Accept',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
