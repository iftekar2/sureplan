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

  @override
  void initState() {
    super.initState();
    _refreshEvent();
  }

  void _refreshEvent() {
    setState(() {
      _eventService.getEventById(widget.event.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),

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
                widget.event.title,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
              ),

              SizedBox(height: 10),
              Text(
                widget.event.location,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),

              if (widget.event.description != null &&
                  widget.event.description!.isNotEmpty) ...[
                SizedBox(height: 10),
                Text(
                  widget.event.description!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],

              SizedBox(height: 10),
              Text(
                DateFormat('MMM d, y • h:mm a').format(widget.event.dateTime),

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

                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditEventPage(event: widget.event),
                      ),
                    ),
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
    );
  }
}
