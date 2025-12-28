import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/events/invite_users_page.dart';
import 'package:sureplan/models/event.dart';
import 'package:sureplan/models/invite.dart';
import 'package:sureplan/models/user_profile.dart';
import 'package:sureplan/services/event_service.dart';
import 'package:sureplan/services/invite_service.dart';

class EditEventPage extends StatefulWidget {
  final Event event;
  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  final _eventService = EventService();
  String? _hostUsername;
  final _hostNameController = TextEditingController();
  final supabase = Supabase.instance.client;
  List<Invite> _attendees = [];
  final _inviteService = InviteService();
  late Event _event;
  String? backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _titleController.text = _event.title;
    _selectedDateTime = _event.dateTime;
    _locationController.text = _event.location;
    _descriptionController.text = _event.description ?? '';
    _fetchHostUsername();
    _fetchAttendees();
  }

  Future<void> _fetchAttendees() async {
    try {
      final attendees = await _inviteService.getAttendees(widget.event.id);
      if (mounted) {
        setState(() {
          _attendees = attendees;
        });
      }
    } catch (e) {
      debugPrint('Error fetching attendees: $e');
    }
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

  Future<void> _selectDateTime() async {
    // Select date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    // Select time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    if (!mounted) return;

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

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? backgroundImageUrl = _event.backgroundImage;
      if (_imageFile != null) {
        backgroundImageUrl = await _eventService.uploadEventBackground(
          _imageFile!,
        );
      }

      final updatedEvent = await _eventService.updateEvent(
        eventId: _event.id,
        title: _titleController.text.trim(),
        dateTime: _selectedDateTime,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        backgroundImageUrl: backgroundImageUrl,
      );

      if (!mounted) return;

      setState(() {
        _event = updatedEvent;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to Update event: ${e.toString()}'),
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

  Future _pickImage() async {
    final imagePicker = ImagePicker();

    // Pick an image
    final XFile? image = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    // Update image preview
    if (image != null) {
      _imageFile = File(image.path);
    }
  }

  double _calculateFontSize() {
    int textLength = _titleController.text.length;

    if (textLength <= 15) {
      return 32.0;
    } else if (textLength <= 30) {
      return 26.0;
    } else {
      return 20.0;
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
            backgroundColor: Colors.grey.shade200,
            child: Text(
              user.username[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 8),
          Text(
            user.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'Create Event',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),

        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  image: _imageFile != null
                      ? FileImage(_imageFile!) as ImageProvider
                      : NetworkImage(
                          _event.backgroundImage ??
                              "https://images.unsplash.com/photo-1631983856436-02b31717416b?q=80&w=987&auto=format&fit=crop",
                        ),
                  alignment: Alignment.topCenter,
                  repeat: ImageRepeat.noRepeat,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            top: true,
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,

                child: Column(
                  children: [
                    const SizedBox(height: 250),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 10,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white),
                          ),

                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Text(
                              "Edit Background",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white),
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

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _calculateFontSize(),
                                  fontWeight: FontWeight.bold,
                                ),

                                decoration: InputDecoration(
                                  hintText: 'Event Title',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),

                              const Divider(
                                color: Color.fromARGB(57, 218, 218, 218),
                                height: 30,
                              ),

                              // 2. Date and Time Section
                              GestureDetector(
                                onTap: () => _selectDateTime(),
                                child: Column(
                                  children: [
                                    Image.network(
                                      "https://img.icons8.com/?size=100&id=mlr7FnQ3G7zb&format=png&color=000000",
                                      color: Colors.white,
                                      height: 40,
                                      width: 40,
                                    ),

                                    const SizedBox(height: 8),
                                    Text(
                                      DateFormat(
                                        'E, MMMM d, h:mm a',
                                      ).format(_selectedDateTime),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Divider(
                                color: Color.fromARGB(57, 218, 218, 218),
                                height: 30,
                              ),

                              GestureDetector(
                                onTap: () => {},

                                child: Column(
                                  children: [
                                    Image.network(
                                      "https://img.icons8.com/?size=100&id=43731&format=png&color=000000",
                                      color: Colors.white,
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
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),

                                      decoration: InputDecoration(
                                        hintText: "Location",
                                        hintStyle: TextStyle(
                                          color: Colors.white,
                                        ),
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
                      ),
                    ),

                    SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          0,
                          0,
                          0,
                        ).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white),
                      ),

                      child: Column(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,

                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),

                                  children: [
                                    const TextSpan(
                                      text: "Hosted by ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                    ),

                                    TextSpan(
                                      text: _hostUsername ?? '...',
                                      style: TextStyle(
                                        color: Colors.white,
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

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
                                  fontSize: 18,
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

                    SizedBox(height: 20),
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

                    // Create button
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _isLoading ? null : _updateEvent,
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Save Event',
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
          ),
        ],
      ),
    );
  }
}
