import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sureplan/events/editEventPage.dart';
import 'package:sureplan/models/event.dart';
import 'package:sureplan/services/eventService.dart';

class EventPage extends StatefulWidget {
  final Event event;
  const EventPage({super.key, required this.event});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final _eventService = EventService();
  late Event _event;
  bool _hasUpdates = false;

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
    if (!mounted) return;
    setState(() {
      _event = updatedEvent;
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

                SizedBox(height: 30),
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
            ),
          ),
        ),
      ),
    );
  }
}
