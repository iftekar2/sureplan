import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sureplan/auth/authService.dart';
import 'package:sureplan/events/editEventPage.dart';
import 'package:sureplan/events/inviteUsersPage.dart';
import 'package:sureplan/models/event.dart';
import 'package:sureplan/models/invite.dart';
import 'package:sureplan/services/eventService.dart';
import 'package:sureplan/services/inviteService.dart';

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
        title: Text('Delete Event'),
        content: Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasUpdates);
        return false;
      },

      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context, _hasUpdates),
          ),
          title: Text(
            _event.title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),

        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 300,
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[400]!),
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
                          _event.title,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 10),
                        Text(
                          _event.location,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_event.description != null &&
                            _event.description!.isNotEmpty) ...[
                          SizedBox(height: 10),
                          Text(
                            _event.description!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],

                        SizedBox(height: 10),
                        Text(
                          DateFormat(
                            'MMM d, y • h:mm a',
                          ).format(_event.dateTime),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),

                        if (_attendees.isNotEmpty) ...[
                          SizedBox(height: 20),

                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Who's Invited?",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ..._attendees.take(2).map((invite) {
                                final user = invite.invitee;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 5.0),
                                  child: Row(
                                    children: [
                                      Chip(
                                        avatar: CircleAvatar(
                                          backgroundColor: Colors.grey[200],
                                          child: Text(
                                            user?.username[0].toUpperCase() ??
                                                '?',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        label: Text(
                                          user?.username ?? 'Unknown',
                                        ),
                                        backgroundColor: Colors.white,
                                        side: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              SizedBox(width: 5),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,

                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: Text("Who's Invited?"),
                                      content: Container(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _attendees.length,
                                          itemBuilder: (context, index) {
                                            final user =
                                                _attendees[index].invitee;
                                            return ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor:
                                                    Colors.grey[200],
                                                child: Text(
                                                  user?.username[0]
                                                          .toUpperCase() ??
                                                      '?',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                user?.username ?? 'Unknown',
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      actions: [
                                        Container(
                                          width: 100,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey,
                                            ),
                                          ),

                                          child: TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(
                                              "Close",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 45,
                                  width: 45,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _attendees.length.toString(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (_attendees.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Builder(
                    builder: (context) {
                      final currentUserId = _auth.user?.id;
                      final myInvite =
                          _attendees
                              .where((a) => a.inviteeId == currentUserId)
                              .isNotEmpty
                          ? _attendees.firstWhere(
                              (a) => a.inviteeId == currentUserId,
                            )
                          : null;

                      return Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[400]!),
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: myInvite != null
                                        ? () => _respond(myInvite.id, 'going')
                                        : null,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: myInvite?.status == 'going'
                                            ? Colors.green.withOpacity(0.1)
                                            : null,
                                        border: Border.all(
                                          color: myInvite?.status == 'going'
                                              ? Colors.green
                                              : Colors.grey,
                                          width: myInvite?.status == 'going'
                                              ? 2
                                              : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
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
                                        ? () =>
                                              _respond(myInvite.id, 'not_going')
                                        : null,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: myInvite?.status == 'not_going'
                                            ? Colors.red.withOpacity(0.1)
                                            : null,
                                        border: Border.all(
                                          color: myInvite?.status == 'not_going'
                                              ? Colors.red
                                              : Colors.grey,
                                          width: myInvite?.status == 'not_going'
                                              ? 2
                                              : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
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
                                        ? () => _respond(myInvite.id, 'maybe')
                                        : null,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: myInvite?.status == 'maybe'
                                            ? Colors.blue.withOpacity(0.1)
                                            : null,
                                        border: Border.all(
                                          color: myInvite?.status == 'maybe'
                                              ? Colors.blue
                                              : Colors.grey,
                                          width: myInvite?.status == 'maybe'
                                              ? 2
                                              : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
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
                      );
                    },
                  ),
                ],

                if (_event.createdBy == _auth.user?.id) ...[
                  SizedBox(height: 10),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      side: BorderSide(color: Colors.grey[400]!),
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

                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          splashFactory: NoSplash.splashFactory,
                          elevation: 0,
                          side: BorderSide(color: Colors.grey[400]!),
                          minimumSize: Size(150, 50),
                        ),
                        onPressed: () => _confirmDelete(),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.black, fontSize: 18),
                        ),
                      ),
                      SizedBox(width: 20),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          splashFactory: NoSplash.splashFactory,
                          elevation: 0,
                          side: BorderSide(color: Colors.grey[400]!),
                          minimumSize: Size(150, 50),
                        ),
                        onPressed: _navigateToEditEvent,
                        child: Text(
                          'Edit',
                          style: TextStyle(color: Colors.black, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
