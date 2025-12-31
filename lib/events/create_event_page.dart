import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/auto_cancel/auto_cancel_page.dart';
import 'package:sureplan/events/select_invitees_page.dart';
import 'package:sureplan/models/user_profile.dart';
import 'package:sureplan/services/event_service.dart';
import 'package:sureplan/services/invite_service.dart';

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
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _fetchHostUsername();
    _titleController.addListener(_onTextChanged);
    _locationController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      // We don't need to do anything here except call setState
      // to trigger a UI refresh so the button color updates.
    });
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
    _titleController.removeListener(_onTextChanged);
    _locationController.removeListener(_onTextChanged);
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

    try {
      String? backgroundImageUrl;
      if (_imageFile != null) {
        backgroundImageUrl = await _eventService.uploadEventBackground(
          _imageFile!,
        );
      }

      final createdEvent = await _eventService.createEvent(
        title: _titleController.text.trim(),
        dateTime: _selectedDateTime,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        backgroundImageUrl: backgroundImageUrl,
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

  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty &&
        _locationController.text.trim().isNotEmpty;
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
                  crossAxisAlignment: CrossAxisAlignment.center,
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

                    if (_selectedInvitees.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white),
                        ),

                        child: Column(
                          children: [
                            const Text(
                              "Who's Invited?",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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

                    SizedBox(height: 20),

                    // Invite friends
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Color.fromARGB(218, 0, 0, 0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        side: BorderSide(color: Colors.white),
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

                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AutoCancelPage(),
                        ),
                      ),

                      child: Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.network(
                              "https://img.icons8.com/?size=100&id=39009&format=png&color=000000",
                              width: 30,
                              height: 30,
                              color: Colors.white,
                            ),

                            SizedBox(width: 15),

                            Text(
                              "Enable Auto Cancel",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 40),
                    // Create button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid
                            ? Color(0xFF0887ff)
                            : Colors.grey,

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

                    SizedBox(height: 30),
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
