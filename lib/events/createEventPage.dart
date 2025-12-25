import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final supabase = Supabase.instance.client;
  final _hostNameController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now().add(Duration(hours: 1));
  List<UserProfile> _selectedInvitees = [];
  bool _isLoading = false;
  bool _isTitleInvalid = false;
  bool _isLocationInvalid = false;
  String? _hostUsername;

  @override
  void initState() {
    super.initState();
    _fetchHostUsername();
  }

  Future<void> _fetchHostUsername() async {
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        final profile = await supabase
            .from('user_profiles')
            .select('username')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null && mounted) {
          setState(() {
            _hostUsername = profile['username'] as String?;
          });
        } else if (mounted) {
          setState(() {
            _hostUsername = 'Host';
          });
        }
      } catch (e) {
        debugPrint('Error fetching host username: $e');
        if (mounted) {
          setState(() {
            _hostUsername = 'Host';
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _hostNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    // Select date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.purple),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    // Select time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
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

      Navigator.pop(context, true);
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

  void _showEventDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 50),
                    const Text(
                      "Event Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Done",
                        style: TextStyle(color: Colors.blue, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "EVENT DESCRIPTION",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),

                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 6,
                        style: const TextStyle(color: Colors.white),

                        decoration: InputDecoration(
                          hintText: "Tell your guests about your event.",
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        "Character Limit: 0/1000",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "HOST NAME",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),

                      const SizedBox(height: 8),
                      TextField(
                        controller: _hostNameController,
                        onChanged: (value) {
                          setState(() {
                            _hostUsername = value;
                          });
                        },

                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Ellen Sweeney",
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        "This is how guests will see you in the event. You can also change your name on a per-event basis.",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInviteeChip(UserProfile user) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              user.username[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            user.username,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color get titleColor => _isTitleInvalid ? Colors.red : Colors.grey;
  Color get locationColor => _isLocationInvalid ? Colors.red : Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(30, 0, 0, 0),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textAlign: TextAlign.center,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,

                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),

                      decoration: InputDecoration(
                        hintText: 'Event Title',
                        hintStyle: TextStyle(color: titleColor),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),

                    const Divider(
                      color: Color.fromARGB(57, 42, 42, 42),
                      height: 30,
                    ),

                    // 2. Date and Time Section
                    GestureDetector(
                      onTap: () => _selectDateTime(),
                      child: Column(
                        children: [
                          Image.network(
                            "https://img.icons8.com/?size=100&id=mlr7FnQ3G7zb&format=png&color=000000",
                            color: Color.fromARGB(255, 67, 67, 67),
                            height: 40,
                            width: 40,
                          ),

                          const SizedBox(height: 8),
                          Text(
                            DateFormat(
                              'E, MMMM d, h:mm a',
                            ).format(_selectedDateTime),
                            style: const TextStyle(
                              color: Color.fromARGB(255, 67, 67, 67),
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      color: Color.fromARGB(57, 42, 42, 42),
                      height: 30,
                    ),

                    GestureDetector(
                      onTap: () => {},

                      child: Column(
                        children: [
                          Image.network(
                            "https://img.icons8.com/?size=100&id=43731&format=png&color=000000",
                            color: Color.fromARGB(255, 67, 67, 67),
                            height: 30,
                            width: 30,
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            controller: _locationController,
                            textAlign: TextAlign.center,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,

                            // onChanged: (value)
                            style: TextStyle(
                              color: Color.fromARGB(255, 67, 67, 67),
                              fontSize: 20,
                            ),

                            decoration: InputDecoration(
                              hintText: "Location",
                              hintStyle: TextStyle(color: locationColor),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(30, 0, 0, 0),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),

                child: Column(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: RichText(
                          textAlign: TextAlign.center,

                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                            ),

                            children: [
                              const TextSpan(
                                text: "Hosted by ",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                ),
                              ),

                              TextSpan(
                                text: _hostUsername ?? '...',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    GestureDetector(
                      onTap: () => _showEventDetails(context),
                      child: Text(
                        _descriptionController.text.isEmpty
                            ? "Add a description...."
                            : _descriptionController.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),

              if (_selectedInvitees.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(30, 0, 0, 0),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),

                  child: Column(
                    children: [
                      const Text(
                        "Who's Invited?",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 15),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _selectedInvitees
                            .map((user) => _buildInviteeChip(user))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // TextFormField(
              //         controller: _titleController,
              //         textAlign: TextAlign.center,
              //         maxLines: null,
              //         keyboardType: TextInputType.multiline,
              //         textInputAction: TextInputAction.newline,

              //         style: const TextStyle(
              //           color: Colors.black,
              //           fontSize: 32,
              //           fontWeight: FontWeight.bold,
              //         ),

              //         decoration: const InputDecoration(
              //           hintText: 'Event Title',
              //           hintStyle: TextStyle(color: Colors.grey),
              //           border: InputBorder.none,
              //           isDense: true,
              //         ),
              //       ),

              // Title field
              // Text(
              //   'Event Title',
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              // ),

              // SizedBox(height: 10),
              // TextFormField(
              //   controller: _titleController,
              //   onChanged: (value) {
              //     if (_isTitleInvalid && value.trim().isNotEmpty) {
              //       setState(() => _isTitleInvalid = false);
              //     }
              //   },

              //   decoration: InputDecoration(
              //     hintText: 'e.g., Birthday Party',
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(15),
              //     ),
              //   ),
              // ),

              // Padding(
              //   padding: const EdgeInsets.only(top: 8.0, left: 4.0),
              //   child: Text(
              //     "Event title is required",
              //     style: TextStyle(
              //       color: _isTitleInvalid ? Colors.red : Colors.black,
              //       fontSize: 14,
              //     ),
              //   ),
              // ),

              // SizedBox(height: 20),

              // // Date and Time
              // Text(
              //   'Date & Time',
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              // ),

              // SizedBox(height: 10),
              // InkWell(
              //   onTap: _selectDateTime,
              //   child: Container(
              //     padding: EdgeInsets.all(16),
              //     decoration: BoxDecoration(
              //       border: Border.all(color: Colors.grey),
              //       borderRadius: BorderRadius.circular(15),
              //     ),
              //     child: Row(
              //       children: [
              //         Icon(Icons.calendar_today, color: Colors.grey),
              //         SizedBox(width: 15),
              //         Text(
              //           DateFormat(
              //             'EEE, MMMM d, yyyy • h:mm a',
              //           ).format(_selectedDateTime),
              //           style: TextStyle(fontSize: 16),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),

              // SizedBox(height: 20),

              // // Location field
              // Text(
              //   'Location',
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              // ),
              // SizedBox(height: 10),
              // TextFormField(
              //   controller: _locationController,
              //   onChanged: (value) {
              //     if (_isLocationInvalid && value.trim().isNotEmpty) {
              //       setState(() => _isLocationInvalid = false);
              //     }
              //   },

              //   decoration: InputDecoration(
              //     hintText: 'e.g., 123 Main St, New York, NY',
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(15),
              //     ),
              //   ),
              // ),
              // Padding(
              //   padding: const EdgeInsets.only(top: 8.0, left: 4.0),
              //   child: Text(
              //     "Event location is required",
              //     style: TextStyle(
              //       color: _isLocationInvalid ? Colors.red : Colors.black,
              //       fontSize: 14,
              //     ),
              //   ),
              // ),
              // SizedBox(height: 25),

              // // Description field
              // Text(
              //   'Description',
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              // ),
              // SizedBox(height: 10),
              // TextFormField(
              //   controller: _descriptionController,
              //   decoration: InputDecoration(
              //     hintText: 'e.g., This is going to be a surprise party',
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(15),
              //     ),
              //   ),
              //   maxLines: 5,
              // ),
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
                      'Invite Friends',
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
