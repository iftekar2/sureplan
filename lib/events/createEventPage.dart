import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sureplan/events/selectInviteesPage.dart';
import 'package:sureplan/models/user_profile.dart';
import 'package:sureplan/services/eventService.dart';
import 'package:sureplan/services/inviteService.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _eventService = EventService();
  final _inviteService = InviteService();

  DateTime _selectedDateTime = DateTime.now().add(Duration(hours: 1));
  List<UserProfile> _selectedInvitees = [];
  bool _isLoading = false;
  bool _isTitleInvalid = false;
  bool _isLocationInvalid = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    // Select date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    // Select time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _createEvent() async {
    _validate();
    if (!_formKey.currentState!.validate() ||
        _isTitleInvalid ||
        _isLocationInvalid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final createdEvent = await _eventService.createEvent(
        title: _titleController.text.trim(),
        dateTime: _selectedDateTime,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      // Send invites to selected users
      if (_selectedInvitees.isNotEmpty) {
        for (var user in _selectedInvitees) {
          try {
            await _inviteService.sendInvite(
              eventId: createdEvent.id,
              inviteeId: user.id,
            );
          } catch (e) {
            print('Failed to invite ${user.username}: $e');
            // Continue inviting others even if one fails
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedInvitees.isNotEmpty
                ? 'Event created and invites sent!'
                : 'Event created successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create event: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _validate() {
    setState(() {
      _isTitleInvalid = _titleController.text.trim().isEmpty;
      _isLocationInvalid = _locationController.text.trim().isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Event',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              Text(
                'Event Title',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),

              SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                onChanged: (value) {
                  if (_isTitleInvalid && value.trim().isNotEmpty) {
                    setState(() => _isTitleInvalid = false);
                  }
                },

                decoration: InputDecoration(
                  hintText: 'e.g., Birthday Party',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text(
                  "Event title is required",
                  style: TextStyle(
                    color: _isTitleInvalid ? Colors.red : Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Date and Time
              Text(
                'Date & Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),

              SizedBox(height: 10),
              InkWell(
                onTap: _selectDateTime,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey),
                      SizedBox(width: 15),
                      Text(
                        DateFormat(
                          'EEE, MMMM d, yyyy • h:mm a',
                        ).format(_selectedDateTime),
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Location field
              Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _locationController,
                onChanged: (value) {
                  if (_isLocationInvalid && value.trim().isNotEmpty) {
                    setState(() => _isLocationInvalid = false);
                  }
                },

                decoration: InputDecoration(
                  hintText: 'e.g., 123 Main St, New York, NY',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text(
                  "Event location is required",
                  style: TextStyle(
                    color: _isLocationInvalid ? Colors.red : Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),

              SizedBox(height: 25),

              // Description field
              Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'e.g., This is going to be a surprise party',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                maxLines: 5,
              ),

              SizedBox(height: 20),

              // Invite friends
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey[400]!),
                  minimumSize: Size(250, 55),
                ),

                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectInviteesPage(
                        alreadySelected: _selectedInvitees,
                      ),
                    ),
                  );

                  if (result != null && result is List<UserProfile>) {
                    setState(() {
                      _selectedInvitees = result;
                    });
                  }
                },

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.people, size: 30),
                    SizedBox(width: 10),
                    Text(
                      _selectedInvitees.isEmpty
                          ? 'Invite Friends'
                          : '${_selectedInvitees.length} Friends Selected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Create button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                onPressed: _isLoading ? null : _createEvent,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Create Event',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
