import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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

            child: ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: events.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Upcoming Events",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        IconButton(
                          icon: Icon(
                            Icons.add_circle,
                            size: 40,
                            color: Colors.black,
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
                        ),
                      ],
                    ),
                  );
                }

                // Display events
                final event = events[index - 1];
                return GestureDetector(
                  onTap: () => _navigateToEventPage(event),
                  child: Card(
                    margin: EdgeInsets.only(bottom: 15),
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.grey[400]!, width: 1),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            event.createdBy.username,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 10),

                          Text(
                            DateFormat(
                              'MMM d, y • h:mm a',
                            ).format(event.dateTime),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 18,
                            ),
                          ),

                          SizedBox(height: 10),

                          SizedBox(
                            width: 250,
                            child: Text(
                              event.location,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 20,
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
          );
        },
      ),
    );
  }
}
