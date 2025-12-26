import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:sureplan/events/create_event_page.dart';
import 'package:sureplan/events/event_page.dart';
import 'package:sureplan/models/event.dart';
import 'package:sureplan/services/event_service.dart';
import 'package:sureplan/settings/profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final EventService _eventService = EventService();
  late Future<List<Event>> _eventsFuture;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _refreshEvents();
  }

  void _refreshEvents() {
    setState(() {
      _eventsFuture = _eventService.getUpcomingEvents();
    });
  }

  Future<void> _navigateToEventPage(Event event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventPage(event: event)),
    );

    if (result == true) {
      _refreshEvents();
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return "Invited";
    switch (status.toLowerCase()) {
      case 'hosting':
        return "Hosting";
      case 'going':
        return "Going";
      case 'not_going':
        return "Not Going";
      case 'maybe':
        return "Maybe";
      default:
        return status;
    }
  }

  Widget _getStatusIcon(String? status) {
    if (status == null) return const Icon(Icons.mail_outline);

    switch (status.toLowerCase()) {
      case 'hosting':
        return Image.network(
          "https://img.icons8.com/?size=100&id=12566&format=png&color=FFFFFF",
          width: 20,
          height: 20,
        );
      case 'going':
        return Image.network(
          "https://img.icons8.com/?size=100&id=91kLZWvmd4sg&format=png&color=000000",
          width: 20,
          height: 20,
        );
      case 'not_going':
        return Image.network(
          "https://img.icons8.com/?size=100&id=4vD3CGn0ukPX&format=png&color=000000",
          width: 20,
          height: 20,
          color: Colors.red,
        );
      case 'maybe':
        return Image.network(
          "https://img.icons8.com/?size=100&id=kHG4p2DyB85t&format=png&color=000000",
          width: 20,
          height: 20,
        );
      default:
        return const Icon(Icons.info_outline, color: Colors.white);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("SuperPlan", style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Container(
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color.fromARGB(255, 156, 156, 156),
                ),
              ),

              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Profile()),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                icon: Icon(Icons.person, color: Colors.black, size: 40),
              ),
            ),
          ),
        ],

        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.white],
            ),
          ),
        ),
      ),

      backgroundColor: Colors.white,
      body: FutureBuilder<List<Event>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];

          // If there are no events
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      "https://img.icons8.com/?size=100&id=m9vqEcBYERYl&format=png&color=000000",
                      height: 80,
                      width: 80,
                      color: Colors.black,
                    ),

                    Text(
                      "No Upcoming Events",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 10),

                    Text(
                      "Upcoming Events, whether you're a host or a guest, will appear here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: const Color.fromARGB(255, 124, 124, 124),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 30),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(250, 60),
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                          side: BorderSide(color: Colors.grey[600]!),
                        ),
                      ),

                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateEventPage(),
                          ),
                        );
                        if (result == true) {
                          _refreshEvents();
                        }
                      },

                      child: Text(
                        "Create an Event",
                        style: TextStyle(fontSize: 23, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // List of events
          return RefreshIndicator(
            onRefresh: () async {
              _refreshEvents();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Section (Stays at the top)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 10,
                    top: 20,
                    bottom: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Upcoming Events",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          size: 40,
                          color: Colors.black,
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateEventPage(),
                            ),
                          );
                          if (result == true) _refreshEvents();
                        },
                      ),
                    ],
                  ),
                ),

                // 2. Horizontal PageView Section
                Expanded(
                  // 💡 Expanded fills the remaining screen space
                  child: PageView.builder(
                    controller: PageController(
                      viewportFraction: 0.9,
                    ), // 💡 Shows a peek of next card
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 10.0,
                        ),
                        child: GestureDetector(
                          onTap: () => _navigateToEventPage(event),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Stack(
                              children: [
                                // --- BACKGROUND IMAGE ---
                                Positioned.fill(
                                  child: Image.network(
                                    event.backgroundImage ??
                                        "https://images.unsplash.com/photo-1631983856436-02b31717416b?q=80&w=987&auto=format&fit=crop",
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                // --- GRADIENT BLEND ---
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.3),
                                          Colors.black.withOpacity(0.9),
                                        ],
                                        stops: const [0.3, 0.6, 1.0],
                                      ),
                                    ),
                                  ),
                                ),

                                // --- SMOOTH BLENDED BLUR ---
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 400,
                                  child: ShaderMask(
                                    shaderCallback: (rect) {
                                      return LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0),
                                          Colors.black,
                                        ],
                                        stops: const [0.0, 0.3],
                                      ).createShader(rect);
                                    },
                                    blendMode: BlendMode.dstIn,
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 25.0,
                                        sigmaY: 25.0,
                                      ),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                ),

                                // --- EVENT TEXT CONTENT ---
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 20,
                                      bottom: 30,
                                      left: 20,
                                      right: 20,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          event.title,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          DateFormat(
                                            'EEE, MMM d, h:mm a',
                                          ).format(event.dateTime),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          event.location,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // --- STATUS BADGE ---
                                Positioned(
                                  top: 25,
                                  left: 25,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _getStatusIcon(event.status),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getStatusText(event.status),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20), // Bottom padding
              ],
            ),
          );
        },
      ),
    );
  }
}
