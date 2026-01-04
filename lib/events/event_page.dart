import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sureplan/auth/auth_service.dart';
import 'package:sureplan/events/edit_event_page.dart';
import 'package:sureplan/events/invite_users_page.dart';
import 'package:sureplan/models/event.dart';
import 'package:sureplan/models/invite.dart';
import 'package:sureplan/models/user_profile.dart';
import 'package:sureplan/services/event_service.dart';
import 'package:sureplan/services/invite_service.dart';

class EventPage extends StatefulWidget {
  final Event event;
  const EventPage({super.key, required this.event});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final _eventService = EventService();
  final _inviteService = InviteService();
  late Event _event;
  bool _hasUpdates = false;
  List<Invite> _attendees = [];
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _refreshEvent();
  }

  @override
  void dispose() {
    super.dispose();
    _refreshEvent();
  }

  Future<void> _refreshEvent() async {
    final updatedEvent = await _eventService.getEventById(widget.event.id);
    final attendees = await _inviteService.getAttendees(widget.event.id);
    if (!mounted) return;
    setState(() {
      _event = updatedEvent;
      _attendees = attendees;
    });
  }

  Future<void> _deleteEvent() async {
    try {
      await _eventService.deleteEvent(widget.event.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event deleted Successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to Delete event: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete Event'),
        content: Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),

          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteEvent();
    }
  }

  Future<void> _navigateToEditEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditEventPage(event: _event)),
    );

    if (result == true) {
      _hasUpdates = true;
      _refreshEvent();
    }
  }

  Future<void> _respond(String inviteId, String status) async {
    try {
      await _inviteService.respondToInvite(inviteId: inviteId, status: status);
      await _refreshEvent();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Allow individual user's to remove event from their view
  Future<void> _deleteEventForSelf() async {
    try {
      final currentUserId = _auth.user?.id;
      if (currentUserId == null) {
        throw Exception('You must be logged in');
      }

      final myInvite = _attendees
          .where((a) => a.inviteeId == currentUserId)
          .firstOrNull;

      if (myInvite == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are not invited to this event'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print(
        'DEBUG: Attempting to delete invite ${myInvite.id} for user $currentUserId',
      );

      // Delete the invite record
      await _inviteService.deleteInviteForSelf(myInvite.id);

      print('DEBUG: Successfully deleted invite');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event removed from your list'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('ERROR: Failed to delete invite: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove event: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _confirmRemoveForSelf() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Remove Event'),
        content: Text('Remove this event from your list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteEventForSelf();
    }
  }

  Widget _buildInviteeChip(UserProfile user) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(30, 0, 0, 0),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey,
            child: Text(
              user.username[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 8),
          Text(
            user.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _attendEvent() async {
    try {
      await _inviteService.attendEvent(widget.event.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Going to event'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
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
    final currentUserId = _auth.user?.id;
    final isHost = _event.createdBy.id == currentUserId;
    final myInvite =
        _attendees.where((a) => a.inviteeId == currentUserId).isNotEmpty
        ? _attendees.firstWhere((a) => a.inviteeId == currentUserId)
        : null;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasUpdates);
        return false;
      },

      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _hasUpdates),
          ),

          title: Text(
            _event.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),

          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),
        ),

        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1000,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      _event.backgroundImage ??
                          "https://images.unsplash.com/photo-1631983856436-02b31717416b?q=80&w=987&auto=format&fit=crop",
                    ),
                    alignment: Alignment.topCenter,
                    repeat: ImageRepeat.repeat,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            SafeArea(
              top: true,
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(left: 20, right: 20),

                child: Align(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 300),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white),
                          ),

                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),

                            child: Column(
                              children: [
                                Text(
                                  _event.title,
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: 10),
                                Text(
                                  _event.location,
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: 10),
                                Text(
                                  DateFormat(
                                    'MMM d, y • h:mm a',
                                  ).format(_event.dateTime),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),

                                if (_event.description != null &&
                                    _event.description!.isNotEmpty) ...[
                                  SizedBox(height: 10),
                                  Text(
                                    textAlign: TextAlign.center,
                                    _event.description!,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 10),

                        if (_attendees.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white),
                            ),

                            child: Column(
                              children: [
                                SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Who's Invited?",
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 15),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: _attendees
                                      .where((invite) => invite.invitee != null)
                                      .map(
                                        (invite) =>
                                            _buildInviteeChip(invite.invitee!),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _event.is_public == true
                                    ? "Public Event"
                                    : "Private Event",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                ),
                              ),

                              const SizedBox(height: 5),
                              Text(
                                _event.is_public == true
                                    ? "Anyone can join this event!"
                                    : "Only invited people can join this event!",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),

                        if (_event.is_public == true &&
                            !isHost &&
                            myInvite?.status != 'going') ...[
                          SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0887ff),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white),
                            ),
                            child: TextButton(
                              onPressed: _attendEvent,
                              child: const Text(
                                "Attend Event",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: 20),

                        if (_attendees.isNotEmpty) ...[
                          SizedBox(height: 10),
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white),
                            ),

                            child: Padding(
                              padding: EdgeInsets.only(
                                top: 10,
                                left: 20,
                                right: 20,
                                bottom: 10,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Invite Status',
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),

                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: myInvite != null
                                            ? () =>
                                                  _respond(myInvite.id, 'going')
                                            : null,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: myInvite?.status == 'going'
                                                ? Colors.green.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : null,
                                            border: Border.all(
                                              color: myInvite?.status == 'going'
                                                  ? Colors.green
                                                  : Colors.grey,
                                              width: myInvite?.status == 'going'
                                                  ? 2
                                                  : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),

                                          child: Column(
                                            children: [
                                              SizedBox(height: 5),
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 30,
                                              ),

                                              SizedBox(height: 5),
                                              Text(
                                                'Going',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green,
                                                ),
                                              ),

                                              SizedBox(height: 3),
                                              Text(
                                                "${_attendees.where((a) => a.status == 'going').length}",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      GestureDetector(
                                        onTap: myInvite != null
                                            ? () => _respond(
                                                myInvite.id,
                                                'not_going',
                                              )
                                            : null,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color:
                                                myInvite?.status == 'not_going'
                                                ? Colors.red.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : null,
                                            border: Border.all(
                                              color:
                                                  myInvite?.status ==
                                                      'not_going'
                                                  ? Colors.red
                                                  : Colors.grey,
                                              width:
                                                  myInvite?.status ==
                                                      'not_going'
                                                  ? 2
                                                  : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),

                                          child: Column(
                                            children: [
                                              SizedBox(height: 5),
                                              Icon(
                                                Icons.remove_circle,
                                                color: Colors.red,
                                                size: 30,
                                              ),

                                              SizedBox(height: 5),
                                              Text(
                                                'Not Going',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red,
                                                ),
                                              ),

                                              SizedBox(height: 3),
                                              Text(
                                                "${_attendees.where((a) => a.status == 'not_going').length}",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      GestureDetector(
                                        onTap: myInvite != null
                                            ? () =>
                                                  _respond(myInvite.id, 'maybe')
                                            : null,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: myInvite?.status == 'maybe'
                                                ? Colors.blue.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : null,
                                            border: Border.all(
                                              color: myInvite?.status == 'maybe'
                                                  ? Colors.blue
                                                  : Colors.grey,
                                              width: myInvite?.status == 'maybe'
                                                  ? 2
                                                  : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),

                                          child: Column(
                                            children: [
                                              SizedBox(height: 5),
                                              Icon(
                                                Icons.question_mark,
                                                color: Colors.blue,
                                                size: 30,
                                              ),

                                              SizedBox(height: 5),
                                              Text(
                                                'Maybe',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue,
                                                ),
                                              ),

                                              SizedBox(height: 3),
                                              Text(
                                                "${_attendees.where((a) => a.status == 'maybe').length}",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Show different buttons for event creator vs invitees
                        if (_event.createdBy.id == _auth.user?.id) ...[
                          SizedBox(height: 10),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Color.fromARGB(218, 0, 0, 0),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              side: BorderSide(color: Colors.white),
                              minimumSize: Size(250, 55),
                            ),

                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      InviteUsersPage(eventId: _event.id),
                                ),
                              );
                            },

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.people, size: 30),
                                SizedBox(width: 10),
                                Text(
                                  'Invite Friends',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Color.fromARGB(218, 0, 0, 0),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  side: BorderSide(color: Colors.white),
                                  minimumSize: Size(150, 50),
                                ),

                                onPressed: () => _confirmDelete(),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),

                              SizedBox(width: 20),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Color.fromARGB(218, 0, 0, 0),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  side: BorderSide(color: Colors.white),
                                  minimumSize: Size(150, 50),
                                ),

                                onPressed: _navigateToEditEvent,
                                child: Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 50),
                        ] else if (_attendees.any(
                          (a) => a.inviteeId == _auth.user?.id,
                        )) ...[
                          SizedBox(height: 20),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Color.fromARGB(218, 0, 0, 0),
                              foregroundColor: Colors.red,
                              elevation: 0,
                              side: BorderSide(color: Colors.white),
                              minimumSize: Size(150, 50),
                            ),

                            onPressed: _confirmRemoveForSelf,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.remove_circle_outline, size: 30),
                                SizedBox(width: 10),
                                Text(
                                  'Remove from My Events',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 50),
                        ],
                      ],
                    ),
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
