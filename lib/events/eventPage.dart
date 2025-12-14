import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                Text(
                  _event.title,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
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
                  DateFormat('MMM d, y • h:mm a').format(_event.dateTime),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),

                if (_attendees.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Container(
                    height: 250,
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
                            'Number of Invites',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: 10),
                          FutureBuilder(
                            future: _inviteService.getAttendees(_event.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  snapshot.data!.length.toString(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              } else {
                                return Text('0');
                              }
                            },
                          ),

                          SizedBox(height: 10),
                          Text(
                            'Invite Status',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
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

                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
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
                                      "${_attendees.where((a) => a.status == 'notgoing').length}",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
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
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            InviteUsersPage(eventId: _event.id),
                      ),
                    );
                  },

                  child: TextButton(
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

                // if (_attendees.isNotEmpty) ...[
                //   SizedBox(height: 20),
                //   Align(
                //     alignment: Alignment.centerLeft,
                //     child: Text(
                //       "Who's Going:",
                //       style: TextStyle(
                //         fontSize: 18,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),

                //   SizedBox(height: 10),
                //   Container(
                //     height: 50,
                //     child: ListView.separated(
                //       scrollDirection: Axis.horizontal,
                //       itemCount: _attendees.length,
                //       separatorBuilder: (context, index) => SizedBox(width: 10),
                //       itemBuilder: (context, index) {
                //         final user = _attendees[index].invitee;
                //         return Chip(
                //           avatar: CircleAvatar(
                //             backgroundColor: Colors.grey[200],
                //             child: Text(
                //               user?.username[0].toUpperCase() ?? '?',
                //               style: TextStyle(
                //                 fontSize: 12,
                //                 color: Colors.black,
                //               ),
                //             ),
                //           ),
                //           label: Text(user?.username ?? 'Unknown'),
                //           backgroundColor: Colors.white,
                //           side: BorderSide(color: Colors.grey[300]!),
                //         );
                //       },
                //     ),
                //   ),
                // ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
